class SongParseError < RuntimeError; end

class SongParser  
  def initialize()
  end
    
  def parse(base_path, definition = nil)
    if(definition.class == String)
      begin
        raw_song_definition = YAML.load(definition)
      rescue ArgumentError => detail
        raise SongParseError, "Syntax error in YAML file"
      end
    elsif(definition.class == Hash)
      raw_song_definition = definition
    else
      raise SongParseError, "Invalid song input"
    end
    
    raw_song_definition = downcase_hash_keys(raw_song_definition)
    raw_song_header = downcase_hash_keys(raw_song_definition["song"])
    raw_tempo = raw_song_header["tempo"]
    raw_kit = raw_song_header["kit"]
    raw_structure = raw_song_header["structure"]
    raw_patterns = raw_song_definition.reject {|k, v| k == "song"}
    
    song = Song.new(base_path)
    
    # 1.) Set tempo
    if(raw_tempo.class == Fixnum && raw_tempo > 0)
      song.tempo = raw_tempo
    else
      # TODO Add this error check to Song, check for Song exception and wrap in SongParseError
      raise SongParseError, "Invalid tempo: '#{raw_tempo}'. Tempo must be a number greater than 0."
    end
    
    # 2.) Build kit
    begin
      kit = build_kit(base_path, raw_kit, raw_patterns)
    rescue SoundNotFoundError => detail
      raise SongParseError, "#{detail}"
    end
    song.kit = kit
    
    # 3.) Load patterns
    raw_patterns.keys.each{|key|
      new_pattern = song.pattern key.to_sym

      track_list = raw_patterns[key]
      track_list.each{|track_definition|
        track_name = track_definition.keys.first
        new_pattern.track track_name, kit.get_sample_data(track_name), track_definition[track_name]
      }
    }
    
    # 4.) Set structure
    structure = []
    raw_structure.each{|pattern_item|
      if(pattern_item.class == String)
        pattern_item = {pattern_item => "x1"}
      end
      
      pattern_name = pattern_item.keys.first
      pattern_name_sym = pattern_name.downcase.to_sym
      
      if(!song.patterns.has_key?(pattern_name_sym))
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
    song.structure = structure
    
    return song
  end
  
private
    
  def build_kit(base_path, raw_kit, raw_patterns)
    kit = Kit.new(base_path)
    
    # Add sounds defined in the Kit section of the song header
    if(raw_kit != nil)
      raw_kit.each {|kit_item|
        kit.add(kit_item.keys.first, kit_item.values.first)
      }
    end
    
    # TODO Investigate detecting duplicate keys already defined in the Kit section
    # Add sounds not defined in Kit section, but used in individual tracks
    raw_patterns.keys.each{|key|
      track_list = raw_patterns[key]
      track_list.each{|track_definition|
        track_name = track_definition.keys.first
        track_path = track_name
        
        kit.add(track_name, track_path)
      }
    }
    
    return kit
  end
    
=begin    
  def build_kit(base_path, song_definition)
    kit = Kit.new(base_path)
    
    song_definition.keys.each{|key|
      if(key != "song")
        track_list = song_definition[key]
        track_list.each{|track_definition|
          track_name = track_definition.keys.first
          track_path = track_name
          
          #if(!File.exists? track_path)
          #  raise SongParseError, "File '#{track_name}' not found for pattern '#{key}'"
          #end
          kit.add(track_name, track_path)
        }
      end
    }
    
    return kit
  end
=end
  
  # Converts all hash keys to be lowercase
  def downcase_hash_keys(hash)
    return hash.inject({}) {|new_hash, pair|
        new_hash[pair.first.downcase] = pair.last
        new_hash
    }
  end
end