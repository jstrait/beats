class SongParseError < RuntimeError; end

class Song
  SAMPLE_RATE = 44100
  SECONDS_PER_MINUTE = 60.0

  def initialize(definition = nil)
    self.tempo = 120
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
      puts "Total samples: #{sample_length()}"
      
      if(split)
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
      else
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
    else
      pattern = @patterns[pattern_name.downcase.to_sym]
      primary_sample_length = pattern.sample_length(@tick_sample_length)
      
      if(split)
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
      else      
        output_data = [].fill(fill_value, 0, pattern.sample_length_with_overflow(@tick_sample_length))
        sample_data = pattern.sample_data(tick_sample_length, @kit.num_channels, num_tracks_in_song, {}, false)
        output_data[0...primary_sample_length] = sample_data[:primary]
        output_data[primary_sample_length...output_data.length] = merge_overflow(sample_data[:overflow], num_tracks_in_song)

        return output_data
      end
    end
  end

  def tempo()
    return @tempo
  end

  def tempo=(new_tempo)
    if(new_tempo.class != Fixnum || new_tempo <= 0)
      raise StandardError, "Invalid tempo: '#{new_tempo}'. Tempo must be a number greater than 0."
    end
    
    @tempo = new_tempo
    @tick_sample_length = (SAMPLE_RATE * SECONDS_PER_MINUTE) / new_tempo / 4.0
  end

  attr_reader :tick_sample_length, :kit
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

    song_definition = downcase_hash_keys(song_definition)
    
    # Process each pattern
    song_definition.keys.each{|key|
      if(key != "song")
        new_pattern = self.pattern key.to_sym

        track_list = song_definition[key]
        track_list.each{|track_definition|
          track_name = track_definition.keys.first
          
          if(!File.exists? track_name)
            raise SongParseError, "File '#{track_name}' not found for pattern '#{key}'"
          end

          @kit.add(track_name, track_name)
          new_pattern.track track_name, [], track_definition[track_name]
        }
      end
    }
    
    @patterns.values.each {|p|
      p.tracks.values.each {|t|
        t.wave_data = @kit.get_sample_data(t.name)
      }
    }
    
    # Process song header
    song_data = downcase_hash_keys(song_definition["song"])
    self.tempo = song_data["tempo"]

    pattern_list = song_data["structure"]
    structure = []
    pattern_list.each{|pattern_item|
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
end