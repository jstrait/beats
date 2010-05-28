# Raised when trying to load a sound file which can't be found at the path specified
class SoundNotFoundError < RuntimeError; end

# This class keeps track of the sounds that are used in a song. It provides a
# central place for storing sound data, and most usefully, handles converting
# sounds in different formats to a standard format.
# 
# For example, if a song requires a sound that is mono/8-bit, another that is
# stereo/8-bit, and another that is stereo/16-bit, it can't mix them together
# because they are in different formats. Kit however automatically handles the
# details of converting them to a common format. If you add sounds to the kit
# using add(), sounds that you get using get_sample_data() will be in a canonical
# format.
#
# When choosing the canonical format, Kit uses the highest quality of the available
# sounds. So if a mono/8-bit, stereo/8-bit, and stereo/16-bit sound are added,
# when you retrieve each one using get_sample_data() they will be stereo/16-bit.
#
# Note that this means that each time a new sound is added to the Kit, the canonical
# format might change, if the incoming sound has a higher bits per sample or
# number of channels than any of the existing sounds. Therefore, all of the sounds
# used by a Song should be added to the Kit before generation begins. If you
# create Song objects by using SongParser, this will be taken care of for you (as
# long as you don't modify the Kit afterward).
class Kit
  PATH_SEPARATOR = File.const_get("SEPARATOR")
  
  # Creates a new Kit object. base_path indicates the folder from which sound files
  # with relative file paths will be loaded from.
  def initialize(base_path)
    @base_path = base_path
    @label_mappings = {}
    @sounds = {}
    @num_channels = 0     # Set to 0 so the first sound added will ratchet it to a real value
    @bits_per_sample = 0  # Set to 0 so the first sound added will ratchet it to a real value
  end
  
  # Adds a new sound to the kit. 
  def add(name, path)
    if(!@sounds.has_key? name)
      path_is_relative = !path.start_with?(PATH_SEPARATOR)
      if(path_is_relative)
        full_path = @base_path + PATH_SEPARATOR + path
      end
      
      begin
        wavefile = WaveFile.open(full_path)
      rescue
        # TODO: Raise different error if sound is in an unsupported format
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
  
  # Returns the sample data (as an Array) for a sound contained in the Kit.
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
  
  # Returns the number of sounds currently contained in the kit.
  def size
    return @sounds.length
  end
  
  attr_reader :base_path, :label_mappings, :bits_per_sample, :num_channels
end
