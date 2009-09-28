require 'yaml'

class Song
  SAMPLE_RATE = 44100
  SECONDS_PER_MINUTE = 60.0

  def initialize(definition = nil)
    self.tempo = 120
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
    puts "TICK SAMPLE LENGTH: #{@tick_sample_length}"
    num_tracks_in_song = self.total_tracks()

    if(pattern_name == "")
      puts "TOTAL SAMPLE LENGTH: #{sample_length()}"
      
      if(split)
        output_data = {}
        
        offset = 0
        overflow = {}
        @structure.each {|pattern_name|
          puts "================================="
          puts pattern_name
          pattern_sample_length = @patterns[pattern_name].sample_length(@tick_sample_length)
          pattern_sample_data = @patterns[pattern_name].sample_data(@tick_sample_length, num_tracks_in_song, overflow, true)
          
          pattern_sample_data[:primary].keys.each {|track_name|
            if(output_data[track_name] == nil)
              output_data[track_name] = [].fill([0.0, 0.0], 0, sample_length_with_overflow())
            end

            output_data[track_name][offset...(offset + pattern_sample_length)] = pattern_sample_data[:primary][track_name]
          }
          
          overflow.keys.each {|track_name|
            if(pattern_sample_data[:primary][track_name] == nil)
              puts "Extra key! #{track_name}"
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
        output_data = [].fill([0.0, 0.0], 0, self.sample_length_with_overflow)

        offset = 0
        overflow = {}
        @structure.each {|pattern_name|
          pattern_sample_length = @patterns[pattern_name].sample_length(@tick_sample_length)
          pattern_sample_data = @patterns[pattern_name].sample_data(@tick_sample_length, num_tracks_in_song, overflow)
          output_data[offset...offset + pattern_sample_length] = pattern_sample_data[:primary]
          overflow = pattern_sample_data[:overflow]
          offset += pattern_sample_length
        }

        # Handle overflow from final pattern
        output_data[offset...output_data.length] = merge_overflow(overflow, num_tracks_in_song)

        puts "Final # samples: #{output_data.length}"
        puts "Final: #{output_data[0]}"

        return output_data
      end
    else
      pattern = @patterns[pattern_name.downcase.to_sym]
      primary_sample_length = pattern.sample_length(@tick_sample_length)
      
      if(split)
        output_data = {}
        
        puts "================================="
        puts pattern_name
        pattern_sample_length = pattern.sample_length(@tick_sample_length)
        pattern_sample_data = pattern.sample_data(@tick_sample_length, num_tracks_in_song, {}, true)
        
        pattern_sample_data[:primary].keys.each {|track_name|
          overflow_sample_length = pattern_sample_data[:overflow][track_name].length
          full_sample_length = pattern_sample_length + overflow_sample_length
          output_data[track_name] = [].fill([0.0, 0.0], 0, full_sample_length)
          output_data[track_name][0...pattern_sample_length] = pattern_sample_data[:primary][track_name]
          output_data[track_name][pattern_sample_length...full_sample_length] = pattern_sample_data[:overflow][track_name]
        }
        
        return output_data
      else      
        output_data = [].fill([0.0, 0.0], 0, pattern.sample_length_with_overflow(@tick_sample_length))
        sample_data = pattern.sample_data(tick_sample_length, num_tracks_in_song, {}, false)
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
    @tempo = new_tempo
    @tick_sample_length = (SAMPLE_RATE * SECONDS_PER_MINUTE) / new_tempo / 4.0
  end

  attr_reader :tick_sample_length
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
      final_overflow_pattern.track "bass.wav", "."
      final_overflow_sample_data = final_overflow_pattern.sample_data(longest_overflow.length, num_tracks_in_song, overflow, false)
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
    song_definition.keys.each{|key|
      if(key == "song")
        song_data = downcase_hash_keys(song_definition[key])
        self.tempo = song_data["tempo"]

        pattern_list = song_data["structure"]
        structure = []
        pattern_list.each{|pattern_item|
          pattern_name = pattern_item[pattern_item.keys.first]
          pattern_name.slice!(0)

          multiples = pattern_name.to_i
          multiples.times { structure << pattern_item.keys.first.downcase.to_sym }
        }

        @structure = structure
      else
        new_pattern = self.pattern key.to_sym

        track_list = song_definition[key]
        track_list.keys.each{|track_name|
          begin
            new_pattern.track track_name, track_list[track_name]
          rescue => detail
            raise StandardError, detail.message
          end
        }
      end
    }
  end
end