# Domain object which models one or more Tracks playing a part of the song at the same time.
# For example, a bass drum, snare drum, and hi-hat track playing the song's chorus.
#
# This object is like sheet music; the AudioEngine is responsible creating actual
# audio data for a Pattern (with the help of a Kit).
class Pattern
  FLOW_TRACK_NAME = "flow"
  
  def initialize(name)
    @name = name
    @tracks = {}
  end
  
  # Adds a new track to the pattern.
  def track(name, rhythm)
    track_key = unique_track_name(name)
    new_track = Track.new(name, rhythm)        
    @tracks[track_key] = new_track

    # If the new track is longer than any of the previously added tracks,
    # pad the other tracks with trailing . to make them all the same length.
    # Necessary to prevent incorrect overflow calculations for tracks.
    longest_track_length = step_count()
    @tracks.values.each do |track|
      if track.rhythm.length < longest_track_length
        track.rhythm += "." * (longest_track_length - track.rhythm.length)
      end
    end
    
    return new_track
  end
  
  def step_count
    return @tracks.values.collect {|track| track.rhythm.length }.max || 0
  end
  
  # Returns whether or not this pattern has the same number of tracks as other_pattern, and that
  # each of the tracks has the same name and rhythm. Ordering of tracks does not matter; will
  # return true if the two patterns have the same tracks but in a different ordering.
  def same_tracks_as?(other_pattern)
    @tracks.keys.each do |track_name|
      other_pattern_track = other_pattern.tracks[track_name]
      if other_pattern_track == nil || @tracks[track_name].rhythm != other_pattern_track.rhythm
        return false
      end
    end
    
    return @tracks.length == other_pattern.tracks.length
  end
  
  # Returns a YAML representation of the Pattern. Produces nicer looking output than the default
  # version of to_yaml().
  def to_yaml
    longest_track_name_length =
      @tracks.keys.inject(0) do |max_length, name|
        (name.to_s.length > max_length) ? name.to_s.length : max_length
      end
    ljust_amount = longest_track_name_length + 7
    
    yaml = "#{@name.to_s.capitalize}:\n"
    @tracks.keys.sort.each do |track_name|
      yaml += "  - #{track_name}:".ljust(ljust_amount)
      yaml += "#{@tracks[track_name].rhythm}\n"
    end
    
    return yaml
  end
  
  attr_accessor :tracks, :name
  
private

  # Returns a unique track name that is not already in use by a track in
  # this pattern. Used to help support having multiple tracks with the same
  # sample in a track.
  def unique_track_name(name)
    i = 2
    name_key = name
    while @tracks.has_key? name_key
      name_key = "#{name}#{i.to_s}"
      i += 1
    end
    
    return name_key
  end
end
