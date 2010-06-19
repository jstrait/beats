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
# using add(), sounds that you get using get_sample_data() will be in a common
# format.
#
# All sounds returned by get_sample_data() will be 16-bit. All sounds will be
# either mono or stereo; if at least one added sound is stereo then all sounds
# will be stereo. So for example if a mono/8-bit, stereo/8-bit, and stereo/16-bit
# sound are added, when you retrieve each one using get_sample_data() they will
# be stereo/16-bit.
#
# Note that this means that each time a new sound is added to the Kit, the common
# format might change, if the incoming sound has a greater number of channels than
# any of the previously added sounds. Therefore, all of the sounds
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
    @num_channels = 1
    @bits_per_sample = 16  # Only use 16-bit files as output. Supporting 8-bit output
                           # means extra complication for no real gain (I'm skeptical
                           # anyone would explicitly want 8-bit output instead of 16-bit.
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
  
  # Produces nicer looking output than the default version of to_yaml().
  def to_yaml(indent_space_count = 0)
    yaml = ""
    longest_label_mapping_length =
      @label_mappings.keys.inject(0) do |max_length, name|
        (name.to_s.length > max_length) ? name.to_s.length : max_length
      end

    if(@label_mappings.length > 0)
      yaml += " " * indent_space_count + "Kit:\n"
      ljust_amount = longest_label_mapping_length + 1  # The +1 is for the trailing ":"
      @label_mappings.sort.each do |label, path|
        yaml += " " * indent_space_count + "  - #{(label + ":").ljust(ljust_amount)}  #{path}\n"
      end
    end
    
    return yaml
  end
  
  attr_reader :base_path, :label_mappings, :bits_per_sample, :num_channels
end
