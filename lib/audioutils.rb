# This class contains some utility methods for working with sample data.
class AudioUtils

  # Combines multiple sample arrays into one, by adding them together.
  # When the sample arrays are different lengths, the output array will be the length
  # of the longest input array.
  # WARNING: Incoming arrays can be modified.
  def self.composite(sample_arrays, num_channels)
    if sample_arrays == []
      return []
    end

    # Sort from longest to shortest
    sample_arrays = sample_arrays.sort {|x, y| y.length <=> x.length}

    composited_output = sample_arrays.slice!(0)
    sample_arrays.each do |sample_array|
        if num_channels == 1
          unless sample_array == []
            sample_array.length.times {|i| composited_output[i] += sample_array[i] }
          end
        elsif num_channels == 2
          unless sample_array == [[]]
            sample_array.length.times do |i|
              composited_output[i] = [composited_output[i][0] + sample_array[i][0],
                                      composited_output[i][1] + sample_array[i][1]]
            end
          end
        else
          raise StandardError, "Invalid sample data array"
        end
    end
 
    return composited_output
  end


  # Scales the amplitude of the incoming sample array by *scale* amount. Can be used in conjunction
  # with composite() to make sure composited sample arrays don't have an amplitude greater than 1.0.
  # TODO: Is there a better name for this method?
  def self.normalize(sample_array, scale)
    if sample_array == [] || sample_array == [[]]
      return sample_array
    end
    
    num_channels = num_channels(sample_array)

    if scale > 1
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


  # Returns the number of samples that each tick (i.e. a 'X' or a '.') lasts at a given sample
  # rate and tempo. The sample length can be a non-integer value. Although there's no such
  # thing as a partial sample, this is required to prevent small timing errors from creeping in.
  # If they accumulate, they can cause rhythms to drift out of time.
  def self.tick_sample_length(samples_per_second, tempo)
     samples_per_minute = samples_per_second * 60.0
     samples_per_quarter_note = samples_per_minute / tempo

     # Each tick is equivalent to a 16th note
     return samples_per_quarter_note / 4.0
  end


  # Returns the sample index that a given tick (offset from 0) starts on.
  def self.tick_start_sample(tick_index, tick_sample_length)
    return (tick_index * tick_sample_length).floor
  end


  # Returns FixNum count of channels in sample array.
  # TODO: This method should probably not exist. Instead, Kit.num_channels should be used.
  # One problem with this method is that it requires use of the stupid [[]] for stereo data.
  def self.num_channels(sample_array)
    first_element = sample_array.first

    if sample_array == [] || first_element.class == Fixnum
      return 1
    elsif sample_array == [[]] || first_element.class == Array
      return 2
    else
      # TODO: Define what to do here
    end
  end
end

