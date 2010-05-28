class SongOptimizer
  def initialize()
  end
  
  # Returns a Song that will produce the same output as original_song, but should be
  # generated faster.
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
  
  
  # Splits the patterns of a Song into smaller patterns, each one with at most
  # max_pattern_length steps. For example, if max_pattern_length is 4, then
  # the following pattern:
  #
  # track1: X...X...X.
  # track2: ..X.....X.
  # track3: X.X.X.X.X.
  #
  # will be converted into the following 3 patterns:
  #
  # track1: X...
  # track2: ..X.
  # track3: X.X.
  #
  # track1: X...
  # track3: X.X.
  #
  # track1: X.
  # track2: X.
  # track3: X.
  #
  # Note that if a track in a sub-divided pattern has no triggers (such as track2 in the
  # 2nd pattern above), it will be removed from the new pattern.
  def subdivide_song_patterns(original_song, optimized_song, max_pattern_length)
    blank_track_pattern = '.' * max_pattern_length
    
    # 2.) For each pattern, add a new pattern to new song every max_pattern_length ticks
    optimized_structure = {}
    original_song.patterns.values.each do |pattern|
      tick_index = 0
      optimized_structure[pattern.name] = []
      
      while(pattern.tracks.values.first.rhythm[tick_index] != nil) do
        new_pattern = optimized_song.pattern("#{pattern.name}#{tick_index}".to_sym)
        optimized_structure[pattern.name] << new_pattern.name
        pattern.tracks.values.each do |track|
          sub_track_pattern = track.rhythm[tick_index...(tick_index + max_pattern_length)]
          
          if(sub_track_pattern != blank_track_pattern)
            new_pattern.track(track.name,
                              track.wave_data,
                              sub_track_pattern)
          end
        end
        
        # If no track has a trigger during this step pattern, add a blank track.
        # Otherwise, this pattern will have no ticks, and no sound will be generated.
        # This will cause the pattern to be "compacted away".
        if(new_pattern.tracks.empty?)
          new_pattern.track("placeholder", [], blank_track_pattern)
        end
        
        tick_index += max_pattern_length
      end
    end
    
    # 3.) Replace the Song's structure to reference the new sub-divided patterns
    # instead of the old patterns.
    optimized_structure = original_song.structure.map do |original_pattern|
      optimized_structure[original_pattern]
    end
    optimized_song.structure = optimized_structure.flatten

    return optimized_song    
  end
  
  
  # Replaces any Patterns that are duplicates (i.e., each track uses the same sound and has
  # the same rhythm) with a single canonical pattern.
  #
  # The benefit of this is that it allows more effective caching. For example, suppose Pattern A
  # and Pattern B are equivalent. If Pattern A gets generated first, it will be cached. When
  # Pattern B gets generated, it will be generated from scratch instead of using Pattern A's
  # cached data. Consolidating duplicates into one prevents this from happening.
  #
  # Duplicate Patterns are more likely to occur after calling subdivide_song_patterns().
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
        if(!found_duplicate && pattern.same_tracks_as(seen_pattern))
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