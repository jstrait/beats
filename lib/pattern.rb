class Pattern
  def initialize(name)
    @name = name
    @cache = {}
    @tracks = {}
  end
  
  def track(name, wave_data, pattern)
    new_track = Track.new(name, wave_data, pattern)        
    @tracks[new_track.name] = new_track
    
    # If the new track is longer than any of the previously added tracks,
    # pad the other tracks with trailing . to make them all the same length.
    # Necessary to prevent incorrect overflow calculations for tracks.
    longest_track_length = 0
    @tracks.values.each {|track|
      if(track.pattern.length > longest_track_length)
        longest_track_length = track.pattern.length
      end
    }
    @tracks.values.each {|track|
      if(track.pattern.length < longest_track_length)
        track.pattern += "." * (longest_track_length - track.pattern.length)
      end
    }
    
    return new_track
  end
  
  def sample_length(tick_sample_length)
    @tracks.keys.collect {|track_name| @tracks[track_name].sample_length(tick_sample_length) }.max || 0
  end
  
  def sample_length_with_overflow(tick_sample_length)
    @tracks.keys.collect {|track_name| @tracks[track_name].sample_length_with_overflow(tick_sample_length) }.max || 0
  end
  
  def sample_data(tick_sample_length, num_channels, num_tracks_in_song, incoming_overflow, split = false)
    if(split)
      return split_sample_data(tick_sample_length, num_channels, incoming_overflow)
    else
      return combined_sample_data(tick_sample_length, num_channels, num_tracks_in_song, incoming_overflow)
    end
  end
  
  attr_accessor :tracks, :name

private

  def combined_sample_data(tick_sample_length, num_channels, num_tracks_in_song, incoming_overflow)
    # If we've already encountered this pattern with the same incoming overflow before,
    # return the pre-mixed down version from the cache.
    if(@cache.member?(incoming_overflow))
      return @cache[incoming_overflow]
    end
    
    fill_value = (num_channels == 1) ? 0 : [].fill(0, 0, num_channels)
    track_names = @tracks.keys
    primary_sample_data = []
    overflow_sample_data = {}
    actual_sample_length = sample_length(tick_sample_length)

    if(track_names.length > 0)
      primary_sample_data = [].fill(fill_value, 0, actual_sample_length)

      track_names.each {|track_name|
        temp = @tracks[track_name].sample_data(tick_sample_length, incoming_overflow[track_name])

        track_samples = temp[:primary]
        if(num_channels == 1)
          (0...track_samples.length).each {|i| primary_sample_data[i] += track_samples[i] }
        else
          (0...track_samples.length).each {|i|
            primary_sample_data[i] = [primary_sample_data[i][0] + track_samples[i][0],
                                      primary_sample_data[i][1] + track_samples[i][1]]
          }
        end

        overflow_sample_data[track_name] = temp[:overflow]
      }
    end
    
    # Add samples for tracks with overflow from previous pattern, but not
    # contained in current pattern.
    incoming_overflow.keys.each {|track_name|
      if(!track_names.member?(track_name) && incoming_overflow[track_name].length > 0)
        if(num_channels == 1)
          (0...incoming_overflow[track_name].length).each {|i| primary_sample_data[i] += incoming_overflow[track_name][i]}
        else
          (0...incoming_overflow[track_name].length).each {|i| primary_sample_data[i][0] += incoming_overflow[track_name][i][0]
                                                               primary_sample_data[i][1] += incoming_overflow[track_name][i][1]}
        end
      end
    }
    
    # Mix down the pattern's tracks into one single track
    if(num_channels == 1)
      primary_sample_data = primary_sample_data.map {|sample| (sample / num_tracks_in_song).round }
    else
      primary_sample_data = primary_sample_data.map {|sample| [(sample[0] / num_tracks_in_song).round, (sample[1] / num_tracks_in_song).round] }
    end
    
    # Add the result to the cache so we don't have to go through all of this the next time...
    mixdown_sample_data = {:primary => primary_sample_data, :overflow => overflow_sample_data}
    @cache[incoming_overflow] = mixdown_sample_data
    
    return mixdown_sample_data
  end

  def split_sample_data(tick_sample_length, num_channels, incoming_overflow)
    fill_value = (num_channels == 1) ? 0 : [].fill(0, 0, num_channels)
    primary_sample_data = {}
    overflow_sample_data = {}
    
    @tracks.keys.each {|track_name|
      temp = @tracks[track_name].sample_data(tick_sample_length, incoming_overflow[track_name])
      primary_sample_data[track_name] = temp[:primary]
      overflow_sample_data[track_name] = temp[:overflow]
    }
    
    incoming_overflow.keys.each {|track_name|
      if(@tracks[track_name] == nil)
        # TO DO: Add check for when incoming overflow is longer than
        # track full length to prevent track from lengthening.
        primary_sample_data[track_name] = [].fill(fill_value, 0, sample_length(tick_sample_length))
        primary_sample_data[track_name][0...incoming_overflow[track_name].length] = incoming_overflow[track_name]
        overflow_sample_data[track_name] = []
      end
    }
    
    return {:primary => primary_sample_data, :overflow => overflow_sample_data}
  end
end