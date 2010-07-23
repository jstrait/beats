class Pattern
  def initialize(name)
    @name = name
    @tracks = {}
  end
  
  # Adds a new track to the pattern.
  def track(name, wave_data, rhythm)
    track_key = unique_track_name(name)
    new_track = Track.new(name, wave_data, rhythm)        
    @tracks[track_key] = new_track

    # If the new track is longer than any of the previously added tracks,
    # pad the other tracks with trailing . to make them all the same length.
    # Necessary to prevent incorrect overflow calculations for tracks.
    longest_track_length = tick_count()
    @tracks.values.each do |track|
      if track.rhythm.length < longest_track_length
        track.rhythm += "." * (longest_track_length - track.rhythm.length)
      end
    end
    
    return new_track
  end
  
  # The number of samples required for the pattern at the given tempo. DOES NOT include samples
  # necessary for sound that overflows past the last tick of the pattern.
  def sample_length(tick_sample_length)
    @tracks.keys.collect {|track_name| @tracks[track_name].sample_length(tick_sample_length) }.max || 0
  end
  
  # The number of samples required for the pattern at the given tempo. Include sound overflow
  # past the last tick of the pattern.
  def sample_length_with_overflow(tick_sample_length)
    @tracks.keys.collect {|track_name| @tracks[track_name].sample_length_with_overflow(tick_sample_length) }.max || 0
  end
  
  def tick_count
    return @tracks.values.collect {|track| track.rhythm.length }.max || 0
  end
    
  def sample_data(tick_sample_length, num_channels, num_tracks_in_song, incoming_overflow)
    primary_sample_data, overflow_sample_data = generate_main_sample_data(tick_sample_length, num_channels)
    primary_sample_data, overflow_sample_data = handle_incoming_overflow(tick_sample_length,
                                                                         num_channels,
                                                                         incoming_overflow,
                                                                         primary_sample_data,
                                                                         overflow_sample_data)
    primary_sample_data = mixdown_sample_data(num_channels, num_tracks_in_song, primary_sample_data)
    
    return {:primary => primary_sample_data, :overflow => overflow_sample_data}
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

  def generate_main_sample_data(tick_sample_length, num_channels)
    track_names = @tracks.keys
    primary_sample_data = []
    overflow_sample_data = {}
    actual_sample_length = sample_length(tick_sample_length)
  
    if @intermediate_cache == nil
      track_names.each do |track_name|
        temp = @tracks[track_name].sample_data(tick_sample_length)
    
        if primary_sample_data == []
          primary_sample_data = temp[:primary]
          overflow_sample_data[track_name] = temp[:overflow]
        else
          track_samples = temp[:primary]
          if num_channels == 1
            track_samples.length.times {|i| primary_sample_data[i] += track_samples[i] }
          else
            track_samples.length.times do |i|
              primary_sample_data[i] = [primary_sample_data[i][0] + track_samples[i][0],
                                        primary_sample_data[i][1] + track_samples[i][1]]
            end
          end

          overflow_sample_data[track_name] = temp[:overflow]
        end
      end
    
      @intermediate_cache = {:primary => primary_sample_data.dup, :overflow => overflow_sample_data.dup}
    else
      primary_sample_data = @intermediate_cache[:primary].dup
      overflow_sample_data = @intermediate_cache[:overflow].dup
    end
  
    return primary_sample_data, overflow_sample_data
  end

  def handle_incoming_overflow(tick_sample_length, num_channels, incoming_overflow, primary_sample_data, overflow_sample_data)
    track_names = @tracks.keys
  
    # Add overflow from previous pattern
    incoming_overflow.keys.each do |track_name|
      num_incoming_overflow_samples = incoming_overflow[track_name].length
    
      if num_incoming_overflow_samples > 0
        if track_names.member?(track_name)
          # TODO: Does this handle situations where track has a .... rhythm and overflow is
          # longer than track length?
        
          intro_length = @tracks[track_name].intro_sample_length(tick_sample_length)
          if num_incoming_overflow_samples > intro_length
            num_incoming_overflow_samples = intro_length
          end
        else
          # If incoming overflow for track is longer than the pattern length, only add the first part of
          # the overflow to the pattern, and add the remainder to overflow_sample_data so that it gets
          # handled by the next pattern to be generated.
          if num_incoming_overflow_samples > primary_sample_data.length
            overflow_sample_data[track_name] = (incoming_overflow[track_name])[primary_sample_data.length...num_incoming_overflow_samples]
            num_incoming_overflow_samples = primary_sample_data.length
          end
        end
      
        if num_channels == 1
          num_incoming_overflow_samples.times {|i| primary_sample_data[i] += incoming_overflow[track_name][i]}
        else
          num_incoming_overflow_samples.times do |i|
            primary_sample_data[i] = [primary_sample_data[i][0] + incoming_overflow[track_name][i][0],
                                      primary_sample_data[i][1] + incoming_overflow[track_name][i][1]]
          end
        end
      end
    end
  
    return primary_sample_data, overflow_sample_data
  end

  def mixdown_sample_data(num_channels, num_tracks_in_song, primary_sample_data)
    # Mix down the pattern's tracks into one single track
    if num_tracks_in_song > 1
      if num_channels == 1
        primary_sample_data = primary_sample_data.map {|sample| sample / num_tracks_in_song }
      else
        primary_sample_data = primary_sample_data.map {|sample| [sample[0] / num_tracks_in_song, sample[1] / num_tracks_in_song]}
      end
    end
  
    return primary_sample_data
  end
end