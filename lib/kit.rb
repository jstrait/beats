class SoundNotFoundError < RuntimeError; end

class Kit
  PATH_SEPARATOR = File.const_get("SEPARATOR")
  
  def initialize(base_path)
    @base_path = base_path
    @label_mappings = {}
    @sounds = {}
    @num_channels = 0
    @bits_per_sample = 0
  end
  
  def add(name, path)
    if(!@sounds.has_key? name)
      if(!path.start_with?(PATH_SEPARATOR))
        full_path = @base_path + PATH_SEPARATOR + path
      end
      
      begin
        wavefile = WaveFile.open(full_path)
      rescue
        raise SoundNotFoundError, "Sound file #{full_path} not found."
      end
      
      @sounds[name] = wavefile
      if(name != path)
        @label_mappings[name] = path
      end
    
      if wavefile.num_channels > @num_channels
        @num_channels = wavefile.num_channels
      end
      if wavefile.bits_per_sample > @bits_per_sample
        @bits_per_sample = wavefile.bits_per_sample
      end
    end
  end
  
  # Returns the sample data for a sound contained in the Kit.
  # Raises an error if the sound doesn't exist in the Kit.
  def get_sample_data(name)
    wavefile = @sounds[name]
    
    if wavefile == nil
      raise StandardError, "Kit doesn't contain sound '#{name}'."
    else
      wavefile.num_channels = @num_channels
      wavefile.bits_per_sample = @bits_per_sample

      return wavefile.sample_data
    end
  end
  
  def size
    return @sounds.length
  end
  
  attr_reader :base_path, :label_mappings, :bits_per_sample, :num_channels
end
