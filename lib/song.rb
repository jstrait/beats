class InvalidTempoError < RuntimeError; end

class Song
  SAMPLE_RATE = 44100
  SECONDS_PER_MINUTE = 60.0
  SAMPLES_PER_MINUTE = SAMPLE_RATE * SECONDS_PER_MINUTE
  DEFAULT_TEMPO = 120

  def initialize(base_path)
    self.tempo = DEFAULT_TEMPO
    @kit = Kit.new(base_path)
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
  def sample_length()
    @structure.inject(0) do |sum, pattern_name|
      sum + @patterns[pattern_name].sample_length(@tick_sample_length)
    end
  end

  # Returns the number of samples required for the entire song at the current tempo.
  # (Assumes a sample rate of 44100). Includes samples required for sound overflow
  # from the last pattern.
  def sample_length_with_overflow()
    if(@structure.length == 0)
      return 0
    end
    
    full_sample_length = self.sample_length
    last_pattern_sample_length = @patterns[@structure.last].sample_length(@tick_sample_length)
    last_pattern_overflow_length = @patterns[@structure.last].sample_length_with_overflow(@tick_sample_length)
    overflow = last_pattern_overflow_length - last_pattern_sample_length

    return sample_length + overflow
  end
  
  # The number of tracks that the pattern with the greatest number of tracks has.
  def total_tracks()
    @patterns.keys.collect {|pattern_name| @patterns[pattern_name].tracks.length }.max || 0
  end
  
  def track_names()
    track_names = {}
    @patterns.values.each do |pattern|
      pattern.tracks.values.each {|track| track_names[track.name] = nil}
    end
    
    return track_names.keys.sort
  end

  # Returns the sample data for the song.
  def sample_data(split, pattern_name = nil)
    num_tracks_in_song = self.total_tracks()
    fill_value = (@kit.num_channels == 1) ? 0 : [].fill(0, 0, @kit.num_channels)

    if(pattern_name == nil)      
      if(split)
        return sample_data_split_all_patterns(fill_value, num_tracks_in_song)
      else
        return sample_data_combined_all_patterns(fill_value, num_tracks_in_song)
      end
    else
      pattern = @patterns[pattern_name.downcase.to_sym]
      
      if(pattern == nil)
        raise StandardError, "Pattern '#{pattern_name}' not found in song."
      else
        primary_sample_length = pattern.sample_length(@tick_sample_length)
      
        if(split)
          return sample_data_split_single_pattern(fill_value, num_tracks_in_song, pattern, primary_sample_length)
        else
          return sample_data_combined_single_pattern(fill_value, num_tracks_in_song, pattern, primary_sample_length)
        end
      end
    end
  end

  def write_to_file(output_file_name, pattern_name)
    num_tracks_in_song = self.total_tracks()
    
    if(pattern_name == nil)
      structure = @structure
      sample_length = sample_length_with_overflow()
    else
      normalized_pattern_name = pattern_name.downcase.to_sym
      structure = [normalized_pattern_name]
      sample_length = patterns[normalized_pattern_name].sample_length(@tick_sample_length)
    end
    
    wave_file = WaveFileExtended.new(@kit.num_channels, SAMPLE_RATE, @kit.bits_per_sample)
    file = wave_file.open_for_appending(output_file_name, sample_length)
    
    incoming_overflow = {}
    structure.each do |pattern_name|
      sample_data = @patterns[pattern_name].sample_data(@tick_sample_length,
                                                        @kit.num_channels,
                                                        num_tracks_in_song,
                                                        incoming_overflow,
                                                        false)
                                                        
      wave_file.write_snippet(file, sample_data[:primary])
      incoming_overflow = sample_data[:overflow]
    end
    
    wave_file.write_snippet(file, merge_overflow(incoming_overflow, num_tracks_in_song))
    file.close()
    
    return wave_file.duration()
  end

  def num_channels()
    return @kit.num_channels
  end
  
  def bits_per_sample()
    return @kit.bits_per_sample
  end

  def tempo()
    return @tempo
  end

  def tempo=(new_tempo)
    if(new_tempo.class != Fixnum || new_tempo <= 0)
      raise InvalidTempoError, "Invalid tempo: '#{new_tempo}'. Tempo must be a number greater than 0."
    end
    
    @tempo = new_tempo
    @tick_sample_length = SAMPLES_PER_MINUTE / new_tempo / 4.0
  end

  # Serializes the current Song to a YAML string. This string can then be used to construct a new Song
  # using the SongParser class. This lets you save a Song to disk, to be re-loaded later.
  def to_yaml()
    # This implementation intentionally builds up a YAML string manually instead of using YAML::dump().
    # Ruby 1.8 makes it difficult to ensure a consistent ordering of hash keys, which makes the output ugly
    # and also hard to test.
    
    yaml_output = "Song:\n"
    yaml_output += "  Tempo: #{@tempo}\n"
    yaml_output += structure_to_yaml()
    yaml_output += kit_to_yaml()
    yaml_output += patterns_to_yaml()
    
    return yaml_output
  end

  attr_reader :tick_sample_length, :patterns
  attr_accessor :structure, :kit

private

  def longest_length_in_array(arr)
    return arr.inject(0) {|max_length, name| (name.to_s.length > max_length) ? name.to_s.length : max_length }
  end

  def structure_to_yaml()
    yaml_output = "  Structure:\n"
    ljust_amount = longest_length_in_array(@structure) + 1  # The + 1 is for the trailing :
    previous = nil
    count = 0
    @structure.each do |pattern_name|
      if(pattern_name == previous || previous == nil)
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

  def kit_to_yaml()
    yaml_output = ""

    if(@kit.label_mappings.length > 0)
      yaml_output += "  Kit:\n"
      ljust_amount = longest_length_in_array(@kit.label_mappings.keys) + 1  # The + 1 is for the trailing :
      @kit.label_mappings.sort.each do |label, path|
        yaml_output += "    - #{(label + ":").ljust(ljust_amount)}  #{path}\n"
      end
    end
    
    return yaml_output
  end

  def patterns_to_yaml()
    yaml_output = ""
    
    # Sort to ensure a consistent order, to make testing easier
    pattern_names = @patterns.keys.map {|key| key.to_s}  # Ruby 1.8 can't sort symbols...
    pattern_names.sort.each do |pattern_name|
      yaml_output += "\n#{pattern_name.capitalize}:\n"
      pattern = @patterns[pattern_name.to_sym]
      ljust_amount = longest_length_in_array(pattern.tracks.keys) + 7
      
      pattern.tracks.keys.sort.each do |track_name|
        yaml_output += "  - #{track_name}:".ljust(ljust_amount)
        yaml_output += "#{pattern.tracks[track_name].rhythm}\n"
      end
    end
    
    return yaml_output
  end

  def merge_overflow(overflow, num_tracks_in_song)
    merged_sample_data = []

    if(overflow != {})
      longest_overflow = overflow[overflow.keys.first]
      overflow.keys.each do |track_name|
        if(overflow[track_name].length > longest_overflow.length)
          longest_overflow = overflow[track_name]
        end
      end

      final_overflow_pattern = Pattern.new(:overflow)
      final_overflow_pattern.track "", [], "."
      final_overflow_sample_data = final_overflow_pattern.sample_data(longest_overflow.length, @kit.num_channels, num_tracks_in_song, overflow, false)
      merged_sample_data = final_overflow_sample_data[:primary]
    end

    return merged_sample_data
  end
  
  def sample_data_split_all_patterns(fill_value, num_tracks_in_song)
    output_data = {}
    
    offset = 0
    overflow = {}
    @structure.each do |pattern_name|
      pattern_sample_length = @patterns[pattern_name].sample_length(@tick_sample_length)
      pattern_sample_data = @patterns[pattern_name].sample_data(@tick_sample_length, @kit.num_channels, num_tracks_in_song, overflow, true)
      
      pattern_sample_data[:primary].keys.each do |track_name|
        if(output_data[track_name] == nil)
          output_data[track_name] = [].fill(fill_value, 0, self.sample_length_with_overflow())
        end

        output_data[track_name][offset...(offset + pattern_sample_length)] = pattern_sample_data[:primary][track_name]
      end
      
      overflow.keys.each do |track_name|
        if(pattern_sample_data[:primary][track_name] == nil)
          output_data[track_name][offset...overflow[track_name].length] = overflow[track_name]
        end
      end
      
      overflow = pattern_sample_data[:overflow]
      offset += pattern_sample_length
    end

    overflow.keys.each do |track_name|
      output_data[track_name][offset...overflow[track_name].length] = overflow[track_name]
    end

    return output_data
  end
  
  def sample_data_split_single_pattern(fill_value, num_tracks_in_song, pattern, primary_sample_length)
    output_data = {}
    
    pattern_sample_length = pattern.sample_length(@tick_sample_length)
    pattern_sample_data = pattern.sample_data(@tick_sample_length, @kit.num_channels, num_tracks_in_song, {}, true)
    
    pattern_sample_data[:primary].keys.each do |track_name|
      overflow_sample_length = pattern_sample_data[:overflow][track_name].length
      full_sample_length = pattern_sample_length + overflow_sample_length
      output_data[track_name] = [].fill(fill_value, 0, full_sample_length)
      output_data[track_name][0...pattern_sample_length] = pattern_sample_data[:primary][track_name]
      output_data[track_name][pattern_sample_length...full_sample_length] = pattern_sample_data[:overflow][track_name]
    end
    
    return output_data
  end
  
  def sample_data_combined_all_patterns(fill_value, num_tracks_in_song)
    output_data = [].fill(fill_value, 0, self.sample_length_with_overflow)

    offset = 0
    overflow = {}
    @structure.each do |pattern_name|
      pattern_sample_length = @patterns[pattern_name].sample_length(@tick_sample_length)
      pattern_sample_data = @patterns[pattern_name].sample_data(@tick_sample_length, @kit.num_channels, num_tracks_in_song, overflow)
      output_data[offset...offset + pattern_sample_length] = pattern_sample_data[:primary]
      overflow = pattern_sample_data[:overflow]
      offset += pattern_sample_length
    end
    
    # Handle overflow from final pattern
    output_data[offset...output_data.length] = merge_overflow(overflow, num_tracks_in_song)
    return output_data
  end
  
  def sample_data_combined_single_pattern(fill_value, num_tracks_in_song, pattern, primary_sample_length)
    output_data = [].fill(fill_value, 0, pattern.sample_length_with_overflow(@tick_sample_length))
    sample_data = pattern.sample_data(tick_sample_length, @kit.num_channels, num_tracks_in_song, {}, false)
    output_data[0...primary_sample_length] = sample_data[:primary]
    output_data[primary_sample_length...output_data.length] = merge_overflow(sample_data[:overflow], num_tracks_in_song)

    return output_data
  end
end