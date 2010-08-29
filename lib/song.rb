class InvalidTempoError < RuntimeError; end

class Song
  SAMPLE_RATE = 44100
  SECONDS_PER_MINUTE = 60.0
  SAMPLES_PER_MINUTE = SAMPLE_RATE * SECONDS_PER_MINUTE
  DEFAULT_TEMPO = 120
  PACK_CODE = "s*"   # All sample data is assumed to be 16-bit

  def initialize(base_path)
    self.tempo = DEFAULT_TEMPO
    @kit = Kit.new(base_path, {})
    @patterns = {}
    @structure = []
  end

  # Adds a new pattern to the song, with the specified name.
  def pattern(name)
    @patterns[name] = Pattern.new(name)
    return @patterns[name]
  end

  # Returns the number of samples required for the entire song at the current tempo.
  # (Assumes a sample rate of 44100). Does NOT include samples required for sound
  # overflow from the last pattern.
  def sample_length
    @structure.inject(0) do |sum, pattern_name|
      sum + @patterns[pattern_name].sample_length(@tick_sample_length)
    end
  end

  # Returns the number of samples required for the entire song at the current tempo.
  # (Assumes a sample rate of 44100). Includes samples required for sound overflow
  # from the last pattern.
  def sample_length_with_overflow
    if @structure.length == 0
      return 0
    end
    
    full_sample_length = self.sample_length
    last_pattern_sample_length = @patterns[@structure.last].sample_length(@tick_sample_length)
    last_pattern_overflow_length = @patterns[@structure.last].sample_length_with_overflow(@tick_sample_length)
    overflow = last_pattern_overflow_length - last_pattern_sample_length

    return sample_length + overflow
  end
  
  # The number of tracks that the pattern with the greatest number of tracks has.
  # TODO: Is it a problem that an optimized song can have a different total_tracks() value than
  # the original? Or is that actually a good thing?
  # TODO: Investigate replacing this with a method max_sounds_playing_at_once() or something
  # like that. Would look each pattern along with it's incoming overflow.
  def total_tracks
    @patterns.keys.collect {|pattern_name| @patterns[pattern_name].tracks.length }.max || 0
  end

  # The unique track names used in each of the song's patterns. Sorted in alphabetical order.
  # For example calling this method for this song:
  #
  #   Verse:
  #     - bass:  X...
  #     - snare: ..X.
  #
  #   Chorus:
  #     - bass:  X.X.
  #     - snare: X.X.
  #     - hihat: XXXX
  #
  # Will return: ["bass", "hihat", "snare"]
  def track_names
    @patterns.values.inject([]) {|track_names, pattern| track_names | pattern.tracks.keys }.sort
  end

  def write_to_file(output_file_name)
    cache = {}
    num_tracks_in_song = self.total_tracks()
    sample_length = sample_length_with_overflow()
    
    wave_file = BeatsWaveFile.new(@kit.num_channels, SAMPLE_RATE, @kit.bits_per_sample)
    file = wave_file.open_for_appending(output_file_name, sample_length)
    
    incoming_overflow = {}
    @structure.each do |pattern_name|
      key = [pattern_name, incoming_overflow.hash]
      unless cache.member?(key)
        sample_data = @patterns[pattern_name].sample_data(@tick_sample_length,
                                                          @kit.num_channels,
                                                          num_tracks_in_song,
                                                          incoming_overflow)
        
        if @kit.num_channels == 1
          # Don't flatten the sample data Array, since it is already flattened. That would be a waste of time, yo.
          cache[key] = {:primary => sample_data[:primary].pack(PACK_CODE), :overflow => sample_data[:overflow]}
        else
          cache[key] = {:primary => sample_data[:primary].flatten.pack(PACK_CODE), :overflow => sample_data[:overflow]}
        end
      end
      
      file.syswrite(cache[key][:primary])
      incoming_overflow = cache[key][:overflow]
    end
    
    wave_file.write_snippet(file, merge_overflow(incoming_overflow, num_tracks_in_song))
    file.close()
    
    return wave_file.calculate_duration(SAMPLE_RATE, sample_length)
  end

  def num_channels
    return @kit.num_channels
  end
  
  def bits_per_sample
    return @kit.bits_per_sample
  end

  def tempo
    return @tempo
  end

  def tempo=(new_tempo)
    unless new_tempo.class == Fixnum && new_tempo > 0
      raise InvalidTempoError, "Invalid tempo: '#{new_tempo}'. Tempo must be a number greater than 0."
    end
    
    @tempo = new_tempo
    @tick_sample_length = SAMPLES_PER_MINUTE / new_tempo / 4.0
  end
  
  # Returns a new Song that is identical but with no patterns or structure.
  def copy_ignoring_patterns_and_structure
    copy = Song.new(@kit.base_path)
    copy.tempo = @tempo
    copy.kit = @kit
    
    return copy
  end
  
  # Splits a Song object into multiple Song objects, where each new
  # Song only has 1 track. For example, if a Song has 5 tracks, this will return
  # a hash of 5 songs, each with one of the original Song's tracks.
  def split()
    split_songs = {}
    track_names = track_names()
    
    track_names.each do |track_name|
      new_song = copy_ignoring_patterns_and_structure()
      
      @patterns.each do |name, original_pattern|
        new_pattern = new_song.pattern(name)
        
        if original_pattern.tracks.has_key?(track_name)
          original_track = original_pattern.tracks[track_name]
          new_pattern.track(original_track.name, original_track.wave_data, original_track.rhythm)
        else
          new_pattern.track(track_name, [], "." * original_pattern.tick_count())
        end
      end
      
      new_song.structure = @structure
      
      split_songs[track_name] = new_song
    end
    
    return split_songs
  end
  
  # Removes any patterns that aren't referenced in the structure.
  def remove_unused_patterns
    # Using reject() here because for some reason select() returns an Array not a Hash.
    @patterns.reject! {|k, pattern| !@structure.member?(pattern.name) }
  end

  # Serializes the current Song to a YAML string. This string can then be used to construct a new Song
  # using the SongParser class. This lets you save a Song to disk, to be re-loaded later. Produces nicer
  # looking output than the default version of to_yaml().
  def to_yaml
    # This implementation intentionally builds up a YAML string manually instead of using YAML::dump().
    # Ruby 1.8 makes it difficult to ensure a consistent ordering of hash keys, which makes the output ugly
    # and also hard to test.
    
    yaml_output = "Song:\n"
    yaml_output += "  Tempo: #{@tempo}\n"
    yaml_output += structure_to_yaml()
    yaml_output += @kit.to_yaml(2)
    yaml_output += patterns_to_yaml()
    
    return yaml_output
  end

  attr_reader :tick_sample_length, :patterns
  attr_accessor :structure, :kit

private

  def longest_length_in_array(arr)
    return arr.inject(0) {|max_length, name| [name.to_s.length, max_length].max }
  end

  def structure_to_yaml
    yaml_output = "  Structure:\n"
    ljust_amount = longest_length_in_array(@structure) + 1  # The +1 is for the trailing ":"
    previous = nil
    count = 0
    @structure.each do |pattern_name|
      if pattern_name == previous || previous == nil
        count += 1
      else
        yaml_output += "    - #{(previous.to_s.capitalize + ':').ljust(ljust_amount)}  x#{count}\n"
        count = 1
      end
      previous = pattern_name
    end
    yaml_output += "    - #{(previous.to_s.capitalize + ':').ljust(ljust_amount)}  x#{count}\n"
    
    return yaml_output
  end

  def patterns_to_yaml
    yaml_output = ""
    
    # Sort to ensure a consistent order, to make testing easier
    pattern_names = @patterns.keys.map {|key| key.to_s}  # Ruby 1.8 can't sort symbols...
    pattern_names.sort.each do |pattern_name|
      yaml_output += "\n" + @patterns[pattern_name.to_sym].to_yaml()
    end
    
    return yaml_output
  end

  def merge_overflow(overflow, num_tracks_in_song)
    merged_sample_data = []

    unless overflow == {}
      longest_overflow = overflow[overflow.keys.first]
      overflow.keys.each do |track_name|
        if overflow[track_name].length > longest_overflow.length
          longest_overflow = overflow[track_name]
        end
      end

      # TODO: What happens if final overflow is really long, and extends past single '.' rhythm?
      final_overflow_pattern = Pattern.new(:overflow)
      wave_data = @kit.num_channels == 1 ? [] : [[]]
      final_overflow_pattern.track "", wave_data, "."
      final_overflow_sample_data = final_overflow_pattern.sample_data(longest_overflow.length, @kit.num_channels, num_tracks_in_song, overflow)
      merged_sample_data = final_overflow_sample_data[:primary]
    end

    return merged_sample_data
  end
end