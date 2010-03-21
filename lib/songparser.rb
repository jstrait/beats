class SongParseError < RuntimeError; end

class SongParser  
  def initialize()
  end
        
  def parse(base_path, definition = nil)
    raw_song_definition = canonicalize_definition(definition)
    raw_song_components = split_raw_yaml_into_components(raw_song_definition)
    
    song = Song.new(base_path)
    
    # 1.) Set tempo
    begin
      song.tempo = raw_song_components[:tempo]
    rescue InvalidTempoError => detail
      raise SongParseError, "#{detail}"
    end
    
    # 2.) Build the kit
    begin
      kit = build_kit(base_path, raw_song_components[:kit], raw_song_components[:patterns])
    rescue SoundNotFoundError => detail
      raise SongParseError, "#{detail}"
    end
    song.kit = kit
    
    # 3.) Load patterns
    add_patterns_to_song(song, raw_song_components[:patterns])
    
    # 4.) Set structure
    set_song_structure(song, raw_song_components[:structure])
    
    return song
  end
  
private

  # This is basically a factory. Don't see a benefit to extracting to a full class.
  # Also, is "canonicalize" a word?
  def canonicalize_definition(definition)
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
    
    return raw_song_definition
  end

  def split_raw_yaml_into_components(raw_song_definition)
    raw_song_components = {}
  
    raw_song_components[:full_definition] = downcase_hash_keys(raw_song_definition)
    raw_song_components[:header]          = downcase_hash_keys(raw_song_components[:full_definition]["song"])
    raw_song_components[:tempo]           = raw_song_components[:header]["tempo"]
    raw_song_components[:kit]             = raw_song_components[:header]["kit"]
    raw_song_components[:structure]       = raw_song_components[:header]["structure"]
    raw_song_components[:patterns]        = raw_song_components[:full_definition].reject {|k, v| k == "song"}
  
    return raw_song_components
  end
      
  def build_kit(base_path, raw_kit, raw_patterns)
    kit = Kit.new(base_path)
    
    # Add sounds defined in the Kit section of the song header
    if(raw_kit != nil)
      raw_kit.each {|kit_item|
        kit.add(kit_item.keys.first, kit_item.values.first)
      }
    end
    
    # Add sounds not defined in Kit section, but used in individual tracks
    # TODO Investigate detecting duplicate keys already defined in the Kit section, as this could possibly
    # result in a performance improvement when the sound has to be converted to a different bit rate/num channels,
    # as well as use less memory.
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
  
  def add_patterns_to_song(song, raw_patterns)
    raw_patterns.keys.each{|key|
      new_pattern = song.pattern key.to_sym

      track_list = raw_patterns[key]
      track_list.each{|track_definition|
        track_name = track_definition.keys.first
       new_pattern.track track_name, song.kit.get_sample_data(track_name), track_definition[track_name]
      }
    }
  end
  
  def set_song_structure(song, raw_structure)
    structure = []
    raw_structure.each{|pattern_item|
      if(pattern_item.class == String)
        pattern_item = {pattern_item => "x1"}
      end
      
      pattern_name = pattern_item.keys.first
      pattern_name_sym = pattern_name.downcase.to_sym
      
      # Convert the number of repeats from a String such as "x4" into an integer such as 4.
      multiples_str = pattern_item[pattern_name]
      multiples_str.slice!(0)
      multiples = multiples_str.to_i
      
      if(multiples_str.match(/[^0-9]/) != nil)
        raise SongParseError, "'#{multiples_str}' is an invalid number of repeats for pattern '#{pattern_name}'. Number of repeats should be a whole number."
      else
        if(multiples < 0)
          raise SongParseError, "'#{multiples_str}' is an invalid number of repeats for pattern '#{pattern_name}'. Must be 0 or greater."
        elsif(multiples > 0 && !song.patterns.has_key?(pattern_name_sym))
          # This test is purposefully designed to only throw an error if the number of repeats is greater
          # than 0. This allows you to specify an undefined pattern in the structure with "x0" repeats.
          # This can be convenient for defining the structure before all patterns have been added to the song file.
          raise SongParseError, "Song structure includes non-existent pattern: #{pattern_name}."
        end
      end
      
      multiples.times { structure << pattern_name_sym }
    }
    song.structure = structure
  end
    
  # Converts all hash keys to be lowercase
  def downcase_hash_keys(hash)
    return hash.inject({}) {|new_hash, pair|
        new_hash[pair.first.downcase] = pair.last
        new_hash
    }
  end
end