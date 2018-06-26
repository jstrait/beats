module Beats
  # This class is used to parse a raw YAML song definition into domain objects (i.e.
  # Song, Pattern, Track, and Kit). These domain objects can then be used by AudioEngine
  # to generate the actual audio data that is saved to disk.
  #
  # The sole public method is parse(). It takes a raw YAML string and returns a Song and
  # Kit object (or raises an error if the YAML string couldn't be parsed correctly).
  class SongParser
    class ParseError < StandardError; end

    # Parses a raw YAML song definition and converts it into a Song and Kit object.
    def self.parse(base_path, raw_yaml_string)
      raw_song_components = hashify_raw_yaml(raw_yaml_string)

      unless raw_song_components[:folder].nil?
        base_path = raw_song_components[:folder]
      end

      song = Song.new
      kit_builder = KitBuilder.new(base_path)

      # Set tempo
      begin
        unless raw_song_components[:tempo].nil?
          song.tempo = raw_song_components[:tempo]
        end
      rescue Song::InvalidTempoError => detail
        raise ParseError, "#{detail}"
      end

      # Add sounds defined in the Kit section
      begin
        add_kit_sounds_from_kit(kit_builder, raw_song_components[:kit])
      rescue KitBuilder::SoundFileNotFoundError => detail
        raise ParseError, "#{detail}"
      rescue KitBuilder::InvalidSoundFormatError => detail
        raise ParseError, "#{detail}"
      end

      # Load patterns
      add_patterns_to_song(song, kit_builder, raw_song_components[:patterns])

      # Set flow
      if raw_song_components[:flow].nil?
        raise ParseError, "Song must have a Flow section in the header."
      else
        set_song_flow(song, raw_song_components[:flow])
      end

      # Swing, if swing flag is set
      if raw_song_components[:swing]
        begin
          song = Transforms::SongSwinger.transform(song, raw_song_components[:swing])
        rescue Transforms::SongSwinger::InvalidSwingRateError => detail
          raise ParseError, "#{detail}"
        end
      end

      # Build the final kit
      begin
        add_kit_sounds_from_patterns(kit_builder, song.patterns)
        kit = kit_builder.build_kit
      rescue KitBuilder::SoundFileNotFoundError => detail
        raise ParseError, "#{detail}"
      rescue KitBuilder::InvalidSoundFormatError => detail
        raise ParseError, "#{detail}"
      end

      return song, kit
    end


  private

    NO_SONG_HEADER_ERROR_MSG =
"Song must have a header. Here's an example:

Song:
  Tempo: 120
  Flow:
    - Verse: x2
    - Chorus: x2"

    def self.hashify_raw_yaml(raw_yaml_string)
      begin
        raw_song_definition = YAML.load(raw_yaml_string)
      rescue Psych::SyntaxError => detail
        raise ParseError, "Syntax error in YAML file: #{detail}"
      rescue ArgumentError => detail
        raise ParseError, "Syntax error in YAML file: #{detail}"
      end

      full_definition = downcase_hash_keys(raw_song_definition)

      unless full_definition["song"].nil?
        header = downcase_hash_keys(full_definition["song"])
      else
        raise ParseError, NO_SONG_HEADER_ERROR_MSG
      end

      {
        tempo: header["tempo"],
        folder: header["folder"],
        kit: header["kit"],
        flow: header["flow"],
        swing: header["swing"],
        patterns: full_definition.reject {|k, v| k == "song"},
      }
    end

    def self.add_kit_sounds_from_kit(kit_builder, raw_kit)
      return if raw_kit.nil?

      # Add sounds defined in the Kit section of the song header
      # Converts [{a=>1}, {b=>2}, {c=>3}] from raw YAML to {a=>1, b=>2, c=>3}
      raw_kit.each do |kit_item|
        kit_builder.add_item(kit_item.keys.first, kit_item.values.first)
      end
    end

    def self.add_kit_sounds_from_patterns(kit_builder, patterns)
      # Add sounds not defined in Kit section, but used in individual tracks
      patterns.each do |pattern_name, pattern|
        pattern.tracks.each do |track_name, track|
          track_path = track.name

          if !kit_builder.has_label?(track.name)
            kit_builder.add_item(track.name, track_path)
          end
        end
      end
    end

    def self.add_patterns_to_song(song, kit_builder, raw_patterns)
      raw_patterns.each do |pattern_name, raw_tracks|
        if raw_tracks.nil?
          # TODO: Use correct capitalization of pattern name in error message
          # TODO: Possibly allow if pattern not referenced in the Flow, or has 0 repeats?
          raise ParseError, "Pattern '#{pattern_name}' has no tracks. It needs at least one."
        end

        tracks = []

        raw_tracks.each do |raw_track|
          track_names = raw_track.keys.first
          rhythm = raw_track.values.first

          # Handle case where no track rhythm is specified (i.e. "- foo.wav:" instead of "- foo.wav: X.X.X.X.")
          rhythm = "" if rhythm.nil?

          track_names = Array(track_names)
          if track_names.empty?
            raise ParseError, "Pattern '#{pattern_name}' uses an empty composite sound (i.e. \"[]\"), which is not valid."
          end

          track_names.map! do |track_name|
            unless track_name.is_a?(String)
              raise ParseError, "'#{track_name}' in pattern '#{pattern_name}' is not a valid track sound"
            end
            kit_builder.composite_replacements[track_name] || track_name
          end
          track_names.flatten!

          track_names.each do |track_name|
            tracks << Track.new(track_name, rhythm)
          end
        end

        song.pattern(pattern_name.to_sym, tracks)
      end
    end


    def self.set_song_flow(song, raw_flow)
      flow = []

      raw_flow.each do |pattern_item|
        if pattern_item.class == String
          pattern_item = {pattern_item => "x1"}
        end

        pattern_name = pattern_item.keys.first
        pattern_name_sym = pattern_name.downcase.to_sym

        # Convert the number of repeats from a String such as "x4" into an integer such as 4.
        multiples_str = pattern_item[pattern_name]
        multiples_str.slice!(0)
        multiples = multiples_str.to_i

        unless multiples_str.match(/[^0-9]/).nil?
          raise ParseError,
                "'#{multiples_str}' is an invalid number of repeats for pattern '#{pattern_name}'. Number of repeats should be a whole number."
        else
          if multiples < 0
            raise ParseError, "'#{multiples_str}' is an invalid number of repeats for pattern '#{pattern_name}'. Must be 0 or greater."
          elsif multiples > 0 && !song.patterns.has_key?(pattern_name_sym)
            # This test is purposefully designed to only throw an error if the number of repeats is greater
            # than 0. This allows you to specify an undefined pattern in the flow with "x0" repeats.
            # This can be convenient for defining the flow before all patterns have been added to the song file.
            raise ParseError, "Song flow includes non-existent pattern: #{pattern_name}."
          end
        end

        multiples.times { flow << pattern_name_sym }
      end

      song.flow = flow
    end


    # Converts all hash keys to be lowercase
    def self.downcase_hash_keys(hash)
      hash.inject({}) do |new_hash, pair|
          new_hash[pair.first.downcase] = pair.last
          new_hash
      end
    end
  end
end
