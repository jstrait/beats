class SongOptimizer
  def initialize()
  end
  
  def optimize(original_song, max_pattern_length)
    blank_track_pattern = '.' * max_pattern_length
    
    # 1.) Create a new song
    optimized_song = clone_song_ignoring_patterns_and_structure(original_song)
    
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
  
private

  def clone_song_ignoring_patterns_and_structure(original_song)
    cloned_song = Song.new(original_song.kit.base_path)
    cloned_song.tempo = original_song.tempo
    cloned_song.kit = original_song.kit
    
    return cloned_song
  end
end