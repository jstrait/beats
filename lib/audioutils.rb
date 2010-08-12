class AudioUtils
  
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