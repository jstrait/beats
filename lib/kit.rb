class Kit
  def initialize()
    @sounds = {}
    @num_channels = 0
    @bits_per_sample = 0
  end
  
  def add(name, path)
    if(!@sounds.has_key? name)
      w = WaveFile.open(path)
      @sounds[name] = w
    
      if w.num_channels > @num_channels
        @num_channels = w.num_channels
      end
      if w.bits_per_sample > @bits_per_sample
        @bits_per_sample = w.bits_per_sample
      end
    end
  end
  
  def get_sample_data(name)
    w = @sounds[name]
    w.num_channels = @num_channels
    w.bits_per_sample = @bits_per_sample

    return w.sample_data
  end
  
  def size
    return @sounds.length
  end
  
  attr_reader :bits_per_sample, :num_channels
end