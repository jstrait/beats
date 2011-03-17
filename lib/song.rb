class InvalidTempoError < RuntimeError; end


# Domain object which models the 'sheet music' for a full song. Models the Patterns
# that should be played, in which order (i.e. the flow), and at which tempo.
#
# This is the top-level model object that is used by the AudioEngine to produce
# actual audio data. A Song tells the AudioEngine what sounds to trigger and when.
# A Kit provides the sample data for each of these sounds. With a Song and a Kit
# the AudioEngine can produce the audio data that is saved to disk.
class Song
  DEFAULT_TEMPO = 120

  def initialize()
    self.tempo = DEFAULT_TEMPO
    @patterns = {}
    @flow = []
  end

  # Adds a new pattern to the song, with the specified name.
  def pattern(name)
    @patterns[name] = Pattern.new(name)
    return @patterns[name]
  end

  
  # The number of tracks that the pattern with the greatest number of tracks has.
  # TODO: Is it a problem that an optimized song can have a different total_tracks() value than
  # the original? Or is that actually a good thing?
  # TODO: Investigate replacing this with a method max_sounds_playing_at_once() or something
  # like that. Would look each pattern along with it's incoming overflow.
  def total_tracks
    @patterns.keys.collect {|pattern_name| @patterns[pattern_name].tracks.length }.max || 0
  end

  # The unique track names used in each of the song's patterns. Sorted in alphabetical order.
  # For example calling this method for this song:
  #
  #   Verse:
  #     - bass:  X...
  #     - snare: ..X.
  #
  #   Chorus:
  #     - bass:  X.X.
  #     - snare: X.X.
  #     - hihat: XXXX
  #
  # Will return: ["bass", "hihat", "snare"]
  def track_names
    @patterns.values.inject([]) {|track_names, pattern| track_names | pattern.tracks.keys }.sort
  end

  def tempo
    return @tempo
  end

  def tempo=(new_tempo)
    unless new_tempo.class == Fixnum && new_tempo > 0
      raise InvalidTempoError, "Invalid tempo: '#{new_tempo}'. Tempo must be a number greater than 0."
    end
    
    @tempo = new_tempo
  end
  
  # Returns a new Song that is identical but with no patterns or flow.
  def copy_ignoring_patterns_and_flow
    copy = Song.new()
    copy.tempo = @tempo
    
    return copy
  end
  
  # Splits a Song object into multiple Song objects, where each new
  # Song only has 1 track. For example, if a Song has 5 tracks, this will return
  # a hash of 5 songs, each with one of the original Song's tracks.
  def split()
    split_songs = {}
    track_names = track_names()
    
    track_names.each do |track_name|
      new_song = copy_ignoring_patterns_and_flow()
      
      @patterns.each do |name, original_pattern|
        new_pattern = new_song.pattern(name)
        
        if original_pattern.tracks.has_key?(track_name)
          original_track = original_pattern.tracks[track_name]
          new_pattern.track(original_track.name, original_track.rhythm)
        else
          new_pattern.track(track_name, "." * original_pattern.step_count)
        end
      end
      
      new_song.flow = @flow
      
      split_songs[track_name] = new_song
    end
    
    return split_songs
  end
  
  # Removes any patterns that aren't referenced in the flow.
  def remove_unused_patterns
    # Using reject() here because for some reason select() returns an Array not a Hash.
    @patterns.reject! {|k, pattern| !@flow.member?(pattern.name) }
  end

  # Serializes the current Song to a YAML string. This string can then be used to construct a new Song
  # using the SongParser class. This lets you save a Song to disk, to be re-loaded later. Produces nicer
  # looking output than the default version of to_yaml().
  def to_yaml(kit)
    # This implementation intentionally builds up a YAML string manually instead of using YAML::dump().
    # Ruby 1.8 makes it difficult to ensure a consistent ordering of hash keys, which makes the output ugly
    # and also hard to test.
    
    yaml_output = "Song:\n"
    yaml_output += "  Tempo: #{@tempo}\n"
    yaml_output += flow_to_yaml()
    yaml_output += kit.to_yaml(2)
    yaml_output += patterns_to_yaml()
    
    return yaml_output
  end

  attr_reader :patterns
  attr_accessor :flow

private

  def longest_length_in_array(arr)
    return arr.inject(0) {|max_length, name| [name.to_s.length, max_length].max }
  end

  def flow_to_yaml
    yaml_output = "  Flow:\n"
    ljust_amount = longest_length_in_array(@flow) + 1  # The +1 is for the trailing ":"
    previous = nil
    count = 0
    @flow.each do |pattern_name|
      if pattern_name == previous || previous == nil
        count += 1
      else
        yaml_output += "    - #{(previous.to_s.capitalize + ':').ljust(ljust_amount)}  x#{count}\n"
        count = 1
      end
      previous = pattern_name
    end
    yaml_output += "    - #{(previous.to_s.capitalize + ':').ljust(ljust_amount)}  x#{count}\n"
    
    return yaml_output
  end

  def patterns_to_yaml
    yaml_output = ""
    
    # Sort to ensure a consistent order, to make testing easier
    pattern_names = @patterns.keys.map {|key| key.to_s}  # Ruby 1.8 can't sort symbols...
    pattern_names.sort.each do |pattern_name|
      yaml_output += "\n" + @patterns[pattern_name.to_sym].to_yaml()
    end
    
    return yaml_output
  end
end
