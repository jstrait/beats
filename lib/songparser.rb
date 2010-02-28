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
    
    begin
      kit = build_kit(base_path, raw_song_definition)
    rescue SoundNotFoundError => detail
      raise SongParseError, "#{detail}"
    end
    
    song = Song.new(base_path)
    song.kit = kit
    
    # Process each pattern
    raw_song_definition.keys.each{|key|
      if(key != "song")
        new_pattern = song.pattern key.to_sym

        track_list = raw_song_definition[key]
        track_list.each{|track_definition|
          track_name = track_definition.keys.first
          new_pattern.track track_name, kit.get_sample_data(track_name), track_definition[track_name]
        }
      end
    }
    
    # Process song header
    song = parse_song_header(song, downcase_hash_keys(raw_song_definition["song"]))
    
    return song
  end
  
private
  
  def parse_song_header(song, header_data)
    new_tempo = header_data["tempo"]
    if(new_tempo.class == Fixnum && new_tempo > 0)
      song.tempo = new_tempo
    else
      raise SongParseError, "Invalid tempo: '#{new_tempo}'. Tempo must be a number greater than 0."
    end

    pattern_list = header_data["structure"]
    structure = []
    pattern_list.each{|pattern_item|
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
  
  # Converts all hash keys to be lowercase
  def downcase_hash_keys(hash)
    return hash.inject({}) {|new_hash, pair|
        new_hash[pair.first.downcase] = pair.last
        new_hash
    }
  end
end