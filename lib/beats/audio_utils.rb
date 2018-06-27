module Beats
  # This class contains some utility methods for working with sample data.
  module AudioUtils

    # Combines multiple sample arrays into one, by adding them together.
    # When the sample arrays are different lengths, the output array will be the length
    # of the longest input array.
    # WARNING: Incoming arrays can be modified.
    def self.composite(sample_arrays, num_channels)
      if num_channels < 1
        raise ArgumentError, "`num_channels` must be 1 or greater"
      end

      if sample_arrays == []
        return []
      end

      # Sort from longest to shortest
      sample_arrays = sample_arrays.sort {|x, y| y.length <=> x.length}

      composited_output = sample_arrays.slice!(0)
      sample_arrays.each do |sample_array|
        if num_channels == 1
          sample_array.length.times {|i| composited_output[i] += sample_array[i] }
        elsif num_channels == 2
          sample_array.length.times do |i|
            # Setting composited_output[i][<channel_index>] won't necessary work,
            # because each sub array might point to the same array, causing more
            # samples to be set than expected. For example, a sample buffer initialized
            # using `[].fill([0, 0], 0, 1000)` will result in an array where each index
            # is a pointer to the same array instance.
            composited_output[i] = [composited_output[i][0] + sample_array[i][0],
                                    composited_output[i][1] + sample_array[i][1]]
          end
        elsif num_channels > 2
          sample_array.each_with_index do |sub_array, i|
            composited_sub_array = []
            sub_array.each_with_index do |sample, j|
              composited_sub_array << composited_output[i][j] + sample
            end

            composited_output[i] = composited_sub_array
          end
        end
      end

      composited_output
    end


    # Scales the amplitude of the incoming sample array by *scale* amount. Can be used in conjunction
    # with composite() to make sure composited sample arrays don't have an amplitude greater than 1.0.
    def self.scale(sample_array, num_channels, scale)
      if num_channels < 1
        raise ArgumentError, "`num_channels` must be 1 or greater"
      end

      if scale == 1 || sample_array == []
        return sample_array
      end

      if num_channels == 1
        sample_array.map {|sample| sample / scale }
      elsif num_channels == 2
        sample_array.map {|sample_frame| [sample_frame[0] / scale, sample_frame[1] / scale]}
      elsif num_channels > 2
        sample_array.map do |sample_frame|
          sample_frame.map {|sample| sample / scale }
        end
      end
    end


    # Returns the number of samples that each step (i.e. a 'X' or a '.') lasts at a given sample
    # rate and tempo. The sample length can be a non-integer value. Although there's no such
    # thing as a partial sample, this is required to prevent small timing errors from creeping in.
    # If they accumulate, they can cause rhythms to drift out of time.
    def self.step_sample_length(samples_per_second, tempo)
       samples_per_minute = samples_per_second * 60.0
       samples_per_quarter_note = samples_per_minute / tempo

       # Each step is equivalent to a 16th note
       samples_per_quarter_note / 4.0
    end


    # Returns the sample index that a given step (offset from 0) starts on.
    def self.step_start_sample(step_index, step_sample_length)
      (step_index * step_sample_length).floor
    end
  end
end
