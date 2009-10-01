class Pattern
  def initialize(name)
    @name = name
    @tracks = {}
    @sample_data = nil
  end
  
  def track(file_name, pattern)
    
    begin
      new_track = Track.new(file_name, pattern)    
    rescue => detail
      raise StandardError, "Error in pattern #{@name}: #{detail.message}"
    end
    
    @tracks[new_track.name] = new_track
    return new_track
  end
  
  def sample_length(tick_sample_length)
    @tracks.keys.collect {|track_name| @tracks[track_name].sample_length(tick_sample_length) }.max || 0
  end
  
  def sample_length_with_overflow(tick_sample_length)
    @tracks.keys.collect {|track_name| @tracks[track_name].sample_length_with_overflow(tick_sample_length) }.max || 0
  end
  
  def sample_data(tick_sample_length, num_tracks_in_song, incoming_overflow, split = false)
    if(split)
      return split_sample_data(tick_sample_length, incoming_overflow)
    else
      return combined_sample_data(tick_sample_length, num_tracks_in_song, incoming_overflow)
    end
  end
  
  attr_accessor :tracks, :name

private

  def combined_sample_data(tick_sample_length, num_tracks_in_song, incoming_overflow)
    track_names = @tracks.keys
    
    if @sample_data == nil
      primary_sample_data = []
      overflow_sample_data = {}
      actual_sample_length = sample_length(tick_sample_length)
    
      if(track_names.length > 0)
        primary_sample_data = [].fill([0, 0], 0, actual_sample_length)

        track_names.each {|track_name|
          temp = @tracks[track_name].sample_data(tick_sample_length, incoming_overflow[track_name])
        
          track_samples = temp[:primary]
          (0...track_samples.length).each {|i|
            primary_sample_data[i] = [primary_sample_data[i][0] + track_samples[i][0],
                                      primary_sample_data[i][1] + track_samples[i][1]]
          }
        
          overflow_sample_data[track_name] = temp[:overflow]
        }
      end
      
      @sample_data = {:primary => primary_sample_data, :overflow => overflow_sample_data}
    else
      primary_sample_data = @sample_data[:primary]
      overflow_sample_data = @sample_data[:overflow]
    end
    
    # Add samples for tracks with overflow from previous pattern, but not
    # contained in current pattern.
    incoming_overflow.keys.each {|track_name|
      if(!track_names.member?(track_name) && incoming_overflow[track_name].length > 0)
        puts "Overflow for non-included track! #{track_name}"
        (0...incoming_overflow[track_name].length).each {|i| primary_sample_data[i][0] += incoming_overflow[track_name][i][0]
                                                             primary_sample_data[i][1] += incoming_overflow[track_name][i][1]}
      end
    }
    
    primary_sample_data = primary_sample_data.map {|sample| [(sample[0] / num_tracks_in_song).round, (sample[1] / num_tracks_in_song).round] }
    
    return {:primary => primary_sample_data, :overflow => overflow_sample_data}
  end

  def split_sample_data(tick_sample_length, incoming_overflow)
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
        primary_sample_data[track_name] = [].fill([0, 0], 0, sample_length(tick_sample_length))
        primary_sample_data[track_name][0...incoming_overflow[track_name].length] = incoming_overflow[track_name]
        overflow_sample_data[track_name] = []
      end
    }
    
    return {:primary => primary_sample_data, :overflow => overflow_sample_data}
  end
end