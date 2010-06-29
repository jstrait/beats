# Used to split a Song object into multiple Song objects, where each resulting
# object only has 1 track. For example, if a Song has 5 tracks, this will return
# a hash of 5 songs, each with one of the original song's tracks.
class SongSplitter
  def initialize()
  end
  
  def split(original_song)
    track_names = original_song.track_names()
    
    split_songs = {}
    track_names.each do |track_name|
      new_song = original_song.copy_ignoring_patterns_and_structure()
      
      if track_name == "placeholder"
        track_sample_data = []
      else
        track_sample_data = new_song.kit.get_sample_data(track_name)
      end
      
      original_song.patterns.each do |name, original_pattern|
        new_pattern = new_song.pattern name
        
        if original_pattern.tracks.keys.member?(track_name)
          new_pattern.track track_name,
                            track_sample_data,
                            original_pattern.tracks[track_name].rhythm
        else
          new_pattern.track track_name,
                            track_sample_data,
                            "." * original_pattern.tick_count()
        end
      end
      
      new_song.structure = original_song.structure
      
      split_songs[track_name] = new_song
    end
    
    return split_songs
  end
end