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
      unless sample_array == []
        if num_channels == 1
          sample_array.length.times {|i| composited_output[i] += sample_array[i] }
        elsif num_channels == 2
          sample_array.length.times do |i|
            composited_output[i] = [composited_output[i][0] + sample_array[i][0],
                                    composited_output[i][1] + sample_array[i][1]]
          end
        end
      end
    end
 
    return composited_output
  end


  # Scales the amplitude of the incoming sample array by *scale* amount. Can be used in conjunction
  # with composite() to make sure composited sample arrays don't have an amplitude greater than 1.0.
  def self.scale(sample_array, num_channels, scale)
    if sample_array == []
      return sample_array
    end
    
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


  # Returns the number of samples that each step (i.e. a 'X' or a '.') lasts at a given sample
  # rate and tempo. The sample length can be a non-integer value. Although there's no such
  # thing as a partial sample, this is required to prevent small timing errors from creeping in.
  # If they accumulate, they can cause rhythms to drift out of time.
  def self.step_sample_length(samples_per_second, tempo)
     samples_per_minute = samples_per_second * 60.0
     samples_per_quarter_note = samples_per_minute / tempo

     # Each step is equivalent to a 16th note
     return samples_per_quarter_note / 4.0
  end


  # Returns the sample index that a given step (offset from 0) starts on.
  def self.step_start_sample(step_index, step_sample_length)
    return (step_index * step_sample_length).floor
  end
end

