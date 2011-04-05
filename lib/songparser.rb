class SongParseError < RuntimeError; end


# This class is used to parse a raw YAML song definition into domain objects (i.e.
# Song, Pattern, Track, and Kit). These domain objects can then be used by AudioEngine
# to generate the actual audio data that is saved to disk.
#
# The sole public method is parse(). It takes a raw YAML string and returns a Song and
# Kit object (or raises an error if the YAML string couldn't be parsed correctly).
class SongParser
  DONT_USE_STRUCTURE_WARNING =
      "\n" +
      "WARNING! This song contains a 'Structure' section in the header.\n" +
      "As of BEATS 1.2.1, the 'Structure' section should be renamed 'Flow'.\n" +
      "You should change your song file, in a future version using 'Structure' will cause an error.\n"
  
  NO_SONG_HEADER_ERROR_MSG =
"Song must have a header. Here's an example:

  Song:
    Tempo: 120
    Flow:
      - Verse: x2
      - Chorus: x2"
  
  def initialize()
  end


  # Parses a raw YAML song definition and converts it into a Song and Kit object.
  def parse(base_path, raw_yaml_string)
    raw_song_components = hashify_raw_yaml(raw_yaml_string)
    
    unless raw_song_components[:folder] == nil
      base_path = raw_song_components[:folder]
    end
    
    song = Song.new()
    
    # 1.) Set tempo
    begin
      if raw_song_components[:tempo] != nil
        song.tempo = raw_song_components[:tempo]
      end
    rescue InvalidTempoError => detail
      raise SongParseError, "#{detail}"
    end
    
    # 2.) Build the kit
    begin
      kit = build_kit(base_path, raw_song_components[:kit], raw_song_components[:patterns])
    rescue SoundFileNotFoundError => detail
      raise SongParseError, "#{detail}"
    rescue InvalidSoundFormatError => detail
      raise SongParseError, "#{detail}"
    end
    
    # 3.) Load patterns
    add_patterns_to_song(song, raw_song_components[:patterns])
    
    # 4.) Set flow
    if raw_song_components[:flow] == nil
      raise SongParseError, "Song must have a Flow section in the header."
    else
      set_song_flow(song, raw_song_components[:flow])
    end
    
    return song, kit
  end


private


  def hashify_raw_yaml(raw_yaml_string)
    begin
      raw_song_definition = YAML.load(raw_yaml_string)
    rescue ArgumentError => detail
      raise SongParseError, "Syntax error in YAML file"
    end

    raw_song_components = {}
    raw_song_components[:full_definition] = downcase_hash_keys(raw_song_definition)
    
    if raw_song_components[:full_definition]["song"] != nil
      raw_song_components[:header] = downcase_hash_keys(raw_song_components[:full_definition]["song"])
    else
      raise SongParseError, NO_SONG_HEADER_ERROR_MSG
    end
    raw_song_components[:tempo]     = raw_song_components[:header]["tempo"]
    raw_song_components[:folder]    = raw_song_components[:header]["folder"]
    raw_song_components[:kit]       = raw_song_components[:header]["kit"]
    
    raw_flow = raw_song_components[:header]["flow"]
    raw_structure = raw_song_components[:header]["structure"]
    if raw_flow != nil
      raw_song_components[:flow]    = raw_flow
    else
      if raw_structure != nil
        puts DONT_USE_STRUCTURE_WARNING
      end
      
      raw_song_components[:flow]    = raw_structure
    end
    
    raw_song_components[:patterns]  = raw_song_components[:full_definition].reject {|k, v| k == "song"}
    
    return raw_song_components
  end


  def build_kit(base_path, raw_kit, raw_patterns)
    kit_items = {}
    
    # Add sounds defined in the Kit section of the song header
    # Converts [{a=>1}, {b=>2}, {c=>3}] from raw YAML to {a=>1, b=>2, c=>3}
    # TODO: Raise error is same name is defined more than once in the Kit
    unless raw_kit == nil
      raw_kit.each do |kit_item|
        kit_items[kit_item.keys.first] = kit_item.values.first
      end
    end
    
    # Add sounds not defined in Kit section, but used in individual tracks
    # TODO Investigate detecting duplicate keys already defined in the Kit section, as this could possibly
    # result in a performance improvement when the sound has to be converted to a different bit rate/num channels,
    # as well as use less memory.
    raw_patterns.keys.each do |key|
      track_list = raw_patterns[key]
      
      unless track_list == nil
        track_list.each do |track_definition|
          track_name = track_definition.keys.first
          track_path = track_name
        
          if track_name != Pattern::FLOW_TRACK_NAME && kit_items[track_name] == nil
            kit_items[track_name] = track_path   
          end
        end
      end
    end
    
    kit = Kit.new(base_path, kit_items)
    return kit
  end


  def add_patterns_to_song(song, raw_patterns)
    raw_patterns.keys.each do |key|
      new_pattern = song.pattern key.to_sym

      track_list = raw_patterns[key]
      # TODO Also raise error if only there is only 1 track and it's a flow track
      if track_list == nil
        # TODO: Use correct capitalization of pattern name in error message
        # TODO: Possibly allow if pattern not referenced in the Flow, or has 0 repeats?
        raise SongParseError, "Pattern '#{key}' has no tracks. It needs at least one."
      end
      
      # TODO: What if there is more than one flow? Raise error, or have last one win?
      track_list.each do |track_definition|
        track_name = track_definition.keys.first
        
        # Handle case where no track rhythm is specified (i.e. "- foo.wav:" instead of "- foo.wav: X.X.X.X.")
        track_definition[track_name] ||= ""
        
        new_pattern.track track_name, track_definition[track_name]
      end
    end
  end


  def set_song_flow(song, raw_flow)
    flow = []

    raw_flow.each{|pattern_item|
      if pattern_item.class == String
        pattern_item = {pattern_item => "x1"}
      end
      
      pattern_name = pattern_item.keys.first
      pattern_name_sym = pattern_name.downcase.to_sym
      
      # Convert the number of repeats from a String such as "x4" into an integer such as 4.
      multiples_str = pattern_item[pattern_name]
      multiples_str.slice!(0)
      multiples = multiples_str.to_i
      
      unless multiples_str.match(/[^0-9]/) == nil
        raise SongParseError,
              "'#{multiples_str}' is an invalid number of repeats for pattern '#{pattern_name}'. Number of repeats should be a whole number."
      else
        if multiples < 0
          raise SongParseError, "'#{multiples_str}' is an invalid number of repeats for pattern '#{pattern_name}'. Must be 0 or greater."
        elsif multiples > 0 && !song.patterns.has_key?(pattern_name_sym)
          # This test is purposefully designed to only throw an error if the number of repeats is greater
          # than 0. This allows you to specify an undefined pattern in the flow with "x0" repeats.
          # This can be convenient for defining the flow before all patterns have been added to the song file.
          raise SongParseError, "Song flow includes non-existent pattern: #{pattern_name}."
        end
      end
      
      multiples.times { flow << pattern_name_sym }
    }
    song.flow = flow
  end


  # Converts all hash keys to be lowercase
  def downcase_hash_keys(hash)
    return hash.inject({}) do |new_hash, pair|
        new_hash[pair.first.downcase] = pair.last
        new_hash
    end
  end
end
