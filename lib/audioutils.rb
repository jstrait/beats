class AudioUtils

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
   
  def self.normalize(sample_data, num_tracks)
    if num_tracks > 1 && sample_data.length > 0
      if sample_data.first.class == Fixnum
        sample_data = sample_data.map {|sample| sample / num_tracks }
      elsif sample_data.first.class == Array
        sample_data = sample_data.map {|sample| [sample[0] / num_tracks, sample[1] / num_tracks]}
      else
        raise StandardError, "Invalid sample data array in AudioUtils.normalize()"
      end
    end
    
    return sample_data
  end
end
