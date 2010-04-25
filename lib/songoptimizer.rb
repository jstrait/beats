class SongOptimizer
  def initialize()
  end
  
  def optimize(original_song, max_pattern_length)
    # 1.) Create a new song, cloned from the original
    optimized_song = clone_song_ignoring_patterns_and_structure(original_song)
    
    # 2.) Subdivide patterns
    optimized_song = subdivide_song_patterns(original_song, optimized_song, max_pattern_length)

    # 3.) Prune duplicate patterns
    optimized_song = prune_duplicate_patterns(optimized_song)

    return optimized_song
  end

protected

  # Takes a Song, and returns a new Song that is identical to the original, but with no patterns
  # or structure.
  def clone_song_ignoring_patterns_and_structure(original_song)
    cloned_song = Song.new(original_song.kit.base_path)
    cloned_song.tempo = original_song.tempo
    cloned_song.kit = original_song.kit
    
    return cloned_song
  end
  
  def subdivide_song_patterns(original_song, optimized_song, max_pattern_length)
    blank_track_pattern = '.' * max_pattern_length
    
    # 2.) For each pattern, add a new pattern to new song every max_pattern_length ticks
    optimized_structure = {}
    original_song.patterns.values.each do |pattern|
      tick_index = 0
      optimized_structure[pattern.name] = []
      
      while(pattern.tracks.values.first.pattern[tick_index] != nil) do
        new_pattern = optimized_song.pattern("#{pattern.name}#{tick_index}".to_sym)
        optimized_structure[pattern.name] << new_pattern.name
        pattern.tracks.values.each do |track|
          sub_track_pattern = track.pattern[tick_index...(tick_index + max_pattern_length)]
          
          if(sub_track_pattern != blank_track_pattern)
            new_pattern.track(track.name,
                              track.wave_data,
                              sub_track_pattern)
          end
        end
        
        tick_index += max_pattern_length
      end
    end

    # 3.) Replace structure
    optimized_structure = original_song.structure.map do |original_pattern|
      optimized_structure[original_pattern]
    end
    optimized_song.structure = optimized_structure.flatten
    
    return optimized_song
  end
  
  def prune_duplicate_patterns(song)
    seen_patterns = []
    replacements = {}
    
    # Pattern names are sorted to ensure consistent pattern replacement. Makes tests easier to write.
    # Sort function added manually because Ruby 1.8 doesn't know how to sort symbols...
    pattern_names = song.patterns.keys.sort {|x, y| x.to_s <=> y.to_s }
    
    # Detect duplicates
    pattern_names.each do |pattern_name|
      pattern = song.patterns[pattern_name]
      found_duplicate = false
      seen_patterns.each do |seen_pattern|
        if(!found_duplicate && pattern.same_as(seen_pattern))
          replacements[pattern.name.to_sym] = seen_pattern.name.to_sym
          found_duplicate = true
        end
      end
      
      if(!found_duplicate)
        seen_patterns << pattern
      end
    end
    
    # Update structure to remove references to duplicates
    new_structure = song.structure
    replacements.each do |duplicate, replacement|
      new_structure = new_structure.map do |pattern_name|
        (pattern_name == duplicate) ? replacement : pattern_name
      end
    end
    
    song.structure = new_structure
    return song
  end
end