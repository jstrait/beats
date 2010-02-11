class SongParseError < RuntimeError; end

class Song
  SAMPLE_RATE = 44100
  SECONDS_PER_MINUTE = 60.0
  PATH_SEPARATOR = File.const_get("SEPARATOR")

  def initialize(input_path, definition = nil)
    self.tempo = 120
    @input_path = input_path
    @kit = Kit.new()
    @patterns = {}
    @structure = []

    if(definition != nil)
      parse(definition)
    end
  end

  def pattern(name)
    @patterns[name] = Pattern.new(name)
    return @patterns[name]
  end

  def sample_length()
    @structure.inject(0) {|sum, pattern_name|
      sum + @patterns[pattern_name].sample_length(@tick_sample_length)
    }
  end

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
  
  def total_tracks()
    @patterns.keys.collect {|pattern_name| @patterns[pattern_name].tracks.length }.max || 0
  end

  def sample_data(pattern_name, split)
    num_tracks_in_song = self.total_tracks()
    fill_value = (@kit.num_channels == 1) ? 0 : [].fill(0, 0, @kit.num_channels)

    if(pattern_name == "")      
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
      raise SongParseError, "Invalid tempo: '#{new_tempo}'. Tempo must be a number greater than 0."
    end
    
    @tempo = new_tempo
    @tick_sample_length = (SAMPLE_RATE * SECONDS_PER_MINUTE) / new_tempo / 4.0
  end

  attr_reader :input_path, :tick_sample_length
  attr_accessor :structure

private

  def merge_overflow(overflow, num_tracks_in_song)
    merged_sample_data = []

    if(overflow != {})
      longest_overflow = overflow[overflow.keys.first]
      overflow.keys.each {|track_name|
        if(overflow[track_name].length > longest_overflow.length)
          longest_overflow = overflow[track_name]
        end
      }

      final_overflow_pattern = Pattern.new(:overflow)
      final_overflow_pattern.track "", [], "."
      final_overflow_sample_data = final_overflow_pattern.sample_data(longest_overflow.length, @kit.num_channels, num_tracks_in_song, overflow, false)
      merged_sample_data = final_overflow_sample_data[:primary]
    end

    return merged_sample_data
  end

  # Converts all hash keys to be lowercase
  def downcase_hash_keys(hash)
    return hash.inject({}) {|new_hash, pair|
        new_hash[pair.first.downcase] = pair.last
        new_hash
    }
  end

  def parse(definition)
    if(definition.class == String)
      song_definition = YAML.load(definition)
    elsif(definition.class == Hash)
      song_definition = definition
    else
      raise StandardError, "Invalid song input"
    end

    @kit = build_kit(song_definition)

    song_definition = downcase_hash_keys(song_definition)
    
    # Process each pattern
    song_definition.keys.each{|key|
      if(key != "song")
        new_pattern = self.pattern key.to_sym

        track_list = song_definition[key]
        track_list.each{|track_definition|
          track_name = track_definition.keys.first
          new_pattern.track track_name, @kit.get_sample_data(track_name), track_definition[track_name]
        }
      end
    }
    
    # Process song header
    parse_song_header(downcase_hash_keys(song_definition["song"]))
  end
  
  def parse_song_header(header_data)
    self.tempo = header_data["tempo"]

    pattern_list = header_data["structure"]
    structure = []
    pattern_list.each{|pattern_item|
      if(pattern_item.class == String)
        pattern_item = {pattern_item => "x1"}
      end
      
      pattern_name = pattern_item.keys.first
      pattern_name_sym = pattern_name.downcase.to_sym
      
      if(!@patterns.has_key?(pattern_name_sym))
        raise SongParseError, "Song structure includes non-existant pattern: #{pattern_name}."
      end
      
      multiples_str = pattern_item[pattern_name]
      multiples_str.slice!(0)
      multiples = multiples_str.to_i
      
      if(multiples_str.match(/[^0-9]/) != nil)
        raise SongParseError, "'#{multiples_str}' is an invalid number of repeats for pattern '#{pattern_name}'. Number of repeats should be a whole number."
      elsif(multiples < 0)
        raise SongParseError, "'#{multiples_str}' is an invalid number of repeats for pattern '#{pattern_name}'. Must be 0 or greater."
      end
      
      multiples.times { structure << pattern_name_sym }
    }

    @structure = structure
  end
  
  def build_kit(song_definition)
    kit = Kit.new()
    
    song_definition.keys.each{|key|
      if(key.downcase != "song")
        track_list = song_definition[key]
        track_list.each{|track_definition|
          track_name = track_definition.keys.first
          track_path = track_name
          if(track_path.start_with?(PATH_SEPARATOR))
            track_path = @input_path + PATH_SEPARATOR + track_path
          end
          
          if(!File.exists? track_path)
            raise SongParseError, "File '#{track_name}' not found for pattern '#{key}'"
          end
          
          kit.add(track_name, track_path)
        }
      end
    }
    
    return kit
  end
  
  def sample_data_split_all_patterns(fill_value, num_tracks_in_song)
    output_data = {}
    
    offset = 0
    overflow = {}
    @structure.each {|pattern_name|
      pattern_sample_length = @patterns[pattern_name].sample_length(@tick_sample_length)
      pattern_sample_data = @patterns[pattern_name].sample_data(@tick_sample_length, @kit.num_channels, num_tracks_in_song, overflow, true)
      
      pattern_sample_data[:primary].keys.each {|track_name|
        if(output_data[track_name] == nil)
          output_data[track_name] = [].fill(fill_value, 0, self.sample_length_with_overflow())
        end

        output_data[track_name][offset...(offset + pattern_sample_length)] = pattern_sample_data[:primary][track_name]
      }
      
      overflow.keys.each {|track_name|
        if(pattern_sample_data[:primary][track_name] == nil)
          output_data[track_name][offset...overflow[track_name].length] = overflow[track_name]
        end
      }
      
      overflow = pattern_sample_data[:overflow]
      offset += pattern_sample_length
    }

    overflow.keys.each {|track_name|
      output_data[track_name][offset...overflow[track_name].length] = overflow[track_name]
    }

    return output_data
  end
  
  def sample_data_split_single_pattern(fill_value, num_tracks_in_song, pattern, primary_sample_length)
    output_data = {}
    
    pattern_sample_length = pattern.sample_length(@tick_sample_length)
    pattern_sample_data = pattern.sample_data(@tick_sample_length, @kit.num_channels, num_tracks_in_song, {}, true)
    
    pattern_sample_data[:primary].keys.each {|track_name|
      overflow_sample_length = pattern_sample_data[:overflow][track_name].length
      full_sample_length = pattern_sample_length + overflow_sample_length
      output_data[track_name] = [].fill(fill_value, 0, full_sample_length)
      output_data[track_name][0...pattern_sample_length] = pattern_sample_data[:primary][track_name]
      output_data[track_name][pattern_sample_length...full_sample_length] = pattern_sample_data[:overflow][track_name]
    }
    
    return output_data
  end
  
  def sample_data_combined_all_patterns(fill_value, num_tracks_in_song)
    output_data = [].fill(fill_value, 0, self.sample_length_with_overflow)

    offset = 0
    overflow = {}
    @structure.each {|pattern_name|
      pattern_sample_length = @patterns[pattern_name].sample_length(@tick_sample_length)
      pattern_sample_data = @patterns[pattern_name].sample_data(@tick_sample_length, @kit.num_channels, num_tracks_in_song, overflow)
      output_data[offset...offset + pattern_sample_length] = pattern_sample_data[:primary]
      overflow = pattern_sample_data[:overflow]
      offset += pattern_sample_length
    }
    
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