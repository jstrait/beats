class AudioUtils

  # Combines multiple sample arrays into one, by adding them together.
  # When the sample arrays are different lengths, the output array will be the length
  # of the longest input array.
  # WARNING: Incoming arrays can be modified.
  def self.composite(sample_arrays)
    if sample_arrays == []
      return []
    end

    num_channels = num_channels(sample_arrays.first)

    # Sort from longest to shortest
    sample_arrays = sample_arrays.sort {|x, y| y.length <=> x.length}

    composited_output = sample_arrays.slice!(0)
    sample_arrays.each do |sample_array|
      if num_channels == 1
        sample_array.length.times {|i| composited_output[i] += sample_array[i] }
      elsif num_channels == 2
        sample_array.length.times do |i|
          composited_output[i] = [composited_output[i][0] + sample_array[i][0],
                                  composited_output[i][1] + sample_array[i][1]]
        end
      else
        raise StandardError, "Invalid sample data array in AudioUtils.composite()"
      end
    end
 
    return composited_output
  end


  def self.generate_rhythm(beats, tick_sample_length, sound_sample_array)
    primary_sample_length, full_sample_length =
        calculate_rhythm_sample_length(beats, tick_sample_length, sound_sample_array.length)
    
    fill_value = (sound_sample_array.first.class == Array) ? [0, 0] : 0
    full_sample_data = [].fill(fill_value, 0, full_sample_length)
    
    if full_sample_length > 0
      remainder = 0.0
      offset = beats[0] * tick_sample_length
      remainder += offset - offset.floor

      beats[1...(beats.length)].each do |beat_length|
        beat_sample_length = beat_length * tick_sample_length

        remainder += beat_sample_length - beat_sample_length.floor
        if remainder >= 1.0
          beat_sample_length += 1
          remainder -= 1.0
        end

        full_sample_data[offset...(offset + sound_sample_array.length)] = sound_sample_array
        offset += beat_sample_length.floor
      end

      if full_sample_length > primary_sample_length
        primary_sample_data = full_sample_data[0...offset]
        overflow_sample_data = full_sample_data[primary_sample_length...full_sample_length]
      else
        primary_sample_data = full_sample_data
        overflow_sample_data = []
      end
    else
      primary_sample_data = []
      overflow_sample_data = []
    end
 
    return { :primary => primary_sample_data, :overflow => overflow_sample_data }
  end


  # Scales the amplitude of the incoming sample array by *scale* amount. Can be used in conjunction
  # with composite() to make sure composited sample arrays don't have an amplitude greater than 1.0.
  # TODO: Is there a better name for this method?
  def self.normalize(sample_array, scale)
    num_channels = num_channels(sample_array)

    if scale > 1 && sample_array.length > 0
      if num_channels == 1
        sample_array = sample_array.map {|sample| sample / scale }
      elsif num_channels == 2
        sample_array = sample_array.map {|sample| [sample[0] / scale, sample[1] / scale]}
      else
        raise StandardError, "Invalid sample data array in AudioUtils.normalize()"
      end
    end
    
    return sample_array
  end


  # Returns FixNum count of channels in sample array.
  def self.num_channels(sample_array)
    first_element = sample_array.first

    if first_element.class == Fixnum
      return 1
    elsif first_element.class == Array
      return first_element.length
    else
      # TODO: Define what to do here
    end
  end

private

  def self.calculate_rhythm_sample_length(beats, tick_sample_length, sound_sample_length)
    if beats == [0]
      return 0, 0
    end
    
    total_ticks = beats.inject(0) {|sum, n| sum + n}
    primary_sample_length = (total_ticks * tick_sample_length).floor
    
    last_beat_sample_length = beats.last * tick_sample_length
    full_sample_length = primary_sample_length
    if sound_sample_length > last_beat_sample_length
      full_sample_length += sound_sample_length - last_beat_sample_length.floor
    end
        
    return primary_sample_length, full_sample_length.floor
  end
end

