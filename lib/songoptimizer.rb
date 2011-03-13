# This class is used to transform a Song object into an equivalent Song object whose
# sample data will be generated faster by the audio engine.
#
# The primary method is optimize(). Currently, it performs two optimizations:
#
#   1.) Breaks patterns into shorter patterns. Generating one long Pattern is generally
#       slower than generating several short Patterns with the same combined length.
#   2.) Replaces Patterns which are equivalent (i.e. they have the same tracks with the
#       same rhythms) with one canonical Pattern. This allows for better caching, by
#       preventing the audio engine from generating the same sample data more than once.
#
# Note that step #1 actually performs double duty, because breaking Patterns into smaller
# pieces increases the likelihood there will be duplicates that can be combined.
class SongOptimizer
  def initialize()
  end
  
  # Returns a Song that will produce the same output as original_song, but should be
  # generated faster.
  def optimize(original_song, max_pattern_length)
    # 1.) Create a new song, cloned from the original
    optimized_song = original_song.copy_ignoring_patterns_and_flow()
    
    # 2.) Subdivide patterns
    optimized_song = subdivide_song_patterns(original_song, optimized_song, max_pattern_length)

    # 3.) Prune duplicate patterns
    optimized_song = prune_duplicate_patterns(optimized_song)

    return optimized_song
  end

protected  
  
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
  # 2nd pattern above), it will not be included in the new pattern.
  def subdivide_song_patterns(original_song, optimized_song, max_pattern_length)
    blank_track_pattern = '.' * max_pattern_length
    
    # For each pattern, add a new pattern to new song every max_pattern_length steps
    optimized_flow = {}
    original_song.patterns.values.each do |pattern|
      step_index = 0
      optimized_flow[pattern.name] = []
      
      while(pattern.tracks.values.first.rhythm[step_index] != nil) do
        # TODO: Is this pattern 100% sufficient to prevent collisions between subdivided
        #       pattern names and existing patterns with numeric suffixes?
        new_pattern = optimized_song.pattern("#{pattern.name}_#{step_index}".to_sym)
        optimized_flow[pattern.name] << new_pattern.name
        pattern.tracks.values.each do |track|
          sub_track_pattern = track.rhythm[step_index...(step_index + max_pattern_length)]
          
          if sub_track_pattern != blank_track_pattern
            new_pattern.track(track.name, sub_track_pattern)
          end
        end
        
        # If no track has a trigger during this step pattern, add a blank track.
        # Otherwise, this pattern will have no steps, and no sound will be generated,
        # causing the pattern to be "compacted away".
        if new_pattern.tracks.empty?
          new_pattern.track("placeholder", blank_track_pattern)
        end
        
        step_index += max_pattern_length
      end
    end
    
    # Replace the Song's flow to reference the new sub-divided patterns
    # instead of the old patterns.
    optimized_flow = original_song.flow.map do |original_pattern|
      optimized_flow[original_pattern]
    end
    optimized_song.flow = optimized_flow.flatten

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
    pattern_replacements = determine_pattern_replacements(song.patterns)

    # Update flow to remove references to duplicates
    new_flow = song.flow
    pattern_replacements.each do |duplicate, replacement|
      new_flow = new_flow.map do |pattern_name|
        (pattern_name == duplicate) ? replacement : pattern_name
      end
    end
    song.flow = new_flow
    
    # This isn't strictly necessary, but makes resulting songs easier to read for debugging purposes.
    song.remove_unused_patterns()

    return song
  end


  # Examines a set of patterns definitions, determining which ones have the same tracks with the same
  # rhythms. Then constructs a hash of pattern => pattern indicating that all occurances in the flow
  # of the key should be replaced with the value, so that the other equivalent definitions can be pruned
  # from the song (and hence their sample data doesn't need to be generated).
  def determine_pattern_replacements(patterns)
    seen_patterns = []
    replacements = {}
    
    # Pattern names are sorted to ensure predictable pattern replacement. Makes tests easier to write.
    # Sort function added manually because Ruby 1.8 doesn't know how to sort symbols...
    pattern_names = patterns.keys.sort {|x, y| x.to_s <=> y.to_s }
    
    # Detect duplicates
    pattern_names.each do |pattern_name|
      pattern = patterns[pattern_name]
      found_duplicate = false
      seen_patterns.each do |seen_pattern|
        if !found_duplicate && pattern.same_tracks_as?(seen_pattern)
          replacements[pattern.name.to_sym] = seen_pattern.name.to_sym
          found_duplicate = true
        end
      end
      
      if !found_duplicate
        seen_patterns << pattern
      end
    end

    return replacements
  end
end
