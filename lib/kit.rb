# Raised when trying to load a sound file which can't be found at the path specified
class SoundFileNotFoundError < RuntimeError; end

# Raised when trying to load a sound file which either isn't actually a sound file, or
# is in an unsupported format.
class InvalidSoundFormatError < RuntimeError; end


# This class provides a repository for the sounds used in a song. Most usefully, it
# also handles converting the sounds to a common format. For example, if a song requires
# a sound that is mono/8-bit, another that is stereo/8-bit, and another that is
# stereo/16-bit, they have to be converted to a common format before they can be used
# together. Kit handles this conversion; all sounds retrieved using
# get_sample_data() will be in a common format.
#
# Sounds can only be added at initialization. During initialization, the sample data
# for each sound is loaded into memory, and converted to the common format if necessary.
# This format is:
#
#   Bits per sample: 16
#   Sample rate:     44100
#   Channels:        Stereo, unless all of the kit sounds are mono.
#
# For example if the kit has these sounds:
#
#   my_sound_1.wav:  mono, 16-bit
#   my_sound_2.wav:  stereo, 8-bit
#   my_sound_3.wav:  mono, 8-bit
#
# they will all be converted to stereo/16-bit during initialization.
class Kit
  def initialize(base_path, kit_items)
    @base_path = base_path
    @label_mappings = {}
    @sound_bank = {}
    @num_channels = 1
    @bits_per_sample = 16  # Only use 16-bit files as output. Supporting 8-bit output
                           # means extra complication for no real gain (I'm skeptical
                           # anyone would explicitly want 8-bit output instead of 16-bit).
                           
    load_sounds(base_path, kit_items)
  end
  
  # Returns the sample data for a sound contained in the Kit. If the all sounds in the
  # kit are mono, then this will be a flat Array of Fixnums between -32768 and 32767.
  # Otherwise, this will be an Array of Fixnums pairs between -32768 and 32767.
  #
  # label - The name of the sound to get sample data for. If the sound was defined in
  #         the Kit section of a song file, this will generally be a descriptive label
  #         such as "bass" or "snare". If defined in a track but not the kit, it will
  #         generally be a file name such as "my_sounds/hihat/hi_hat.wav".
  #
  # Examples
  #
  #   # If @num_channels is 1, a flat Array of Fixnums:
  #   get_sample_data("bass")
  #   # => [154, 7023, 8132, 2622, -132, 34, ..., -6702]
  #
  #   # If @num_channels is 2, a Array of Fixnums pairs:
  #   get_sample_data("snare")
  #   # => [[57, 1265], [-452, 10543], [-2531, 12643], [-6372, 11653], ..., [5482, 25673]]
  #
  # Returns the sample data Array for the sound bound to label.
  def get_sample_data(label)
    if label == "placeholder"
      return []
    end

    sample_data = @sound_bank[label]
    
    if sample_data == nil
      # TODO: Should we really throw an exception here rather than just returning nil?
      raise StandardError, "Kit doesn't contain sound '#{label}'."
    else
      return sample_data
    end
  end
  
  def scale!(scale_factor)
    @sound_bank.each do |label, sample_array|
      @sound_bank[label] = AudioUtils.scale(sample_array, @num_channels, scale_factor)
    end
  end

  # Returns a YAML representation of the Kit. Produces nicer looking output than the default version
  # of to_yaml().
  #
  # indent_space_count - The number of spaces to indent each line in the output (default: 0).
  #
  # Returns a String representation of the Kit in YAML format.
  def to_yaml(indent_space_count = 0)
    yaml = ""
    longest_label_mapping_length =
      @label_mappings.keys.inject(0) do |max_length, name|
        (name.to_s.length > max_length) ? name.to_s.length : max_length
      end

    if @label_mappings.length > 0
      yaml += " " * indent_space_count + "Kit:\n"
      ljust_amount = longest_label_mapping_length + 1  # The +1 is for the trailing ":"
      @label_mappings.sort.each do |label, path|
        yaml += " " * indent_space_count + "  - #{(label + ":").ljust(ljust_amount)}  #{path}\n"
      end
    end
    
    return yaml
  end
  
  attr_reader :base_path, :label_mappings, :bits_per_sample, :num_channels
  
private

  def load_sounds(base_path, kit_items)
    # Set label mappings
    kit_items.each do |label, sound_file_names|
      if sound_file_names.class == Array
        raise StandardError, "Composite sounds aren't allowed (yet...)"
      end

      unless label == sound_file_names
        @label_mappings[label] = sound_file_names
      end
    end
    
    kit_items = make_file_names_absolute(kit_items)
    raw_sounds = load_raw_sounds(kit_items)
    
    # Convert each sound to a common format
    raw_sounds.values.each do |wavefile|
      wavefile.num_channels = @num_channels
      wavefile.bits_per_sample = @bits_per_sample
    end
    
    # If necessary, mix component sounds into a composite
    kit_items.each do |label, sound_file_names|
      @sound_bank[label] = mixdown(sound_file_names, raw_sounds)
    end
  end
  
  def get_absolute_path(base_path, sound_file_name)
    path_is_absolute = sound_file_name.start_with?(File::SEPARATOR)
    return path_is_absolute ? sound_file_name : (base_path + File::SEPARATOR + sound_file_name)
  end
  
  def make_file_names_absolute(kit_items)
    kit_items.each do |label, sound_file_names|
      unless sound_file_names.class == Array
        sound_file_names = [sound_file_names]
      end
      
      sound_file_names.map! {|sound_file_name| get_absolute_path(base_path, sound_file_name)}  
      kit_items[label] = sound_file_names
    end
    
    return kit_items
  end
  
  # Load all sound files, bailing if any are invalid
  def load_raw_sounds(kit_items)
    raw_sounds = {}
    kit_items.values.flatten.each do |sound_file_name|
      begin
        wavefile = WaveFile.open(sound_file_name)
      rescue Errno::ENOENT
        raise SoundFileNotFoundError, "Sound file #{sound_file_name} not found."
      rescue StandardError
        raise InvalidSoundFormatError, "Sound file #{sound_file_name} is either not a sound file, " +
                                       "or is in an unsupported format. BEATS can handle 8 or 16-bit *.wav files."
      end
      @num_channels = [@num_channels, wavefile.num_channels].max
      raw_sounds[sound_file_name] = wavefile
    end
    
    return raw_sounds
  end
  
  def mixdown(sound_file_names, raw_sounds)
    sample_arrays = []    
    sound_file_names.each do |sound_file_name|
      sample_arrays << raw_sounds[sound_file_name].sample_data
    end

    composited_sample_data = AudioUtils.composite(sample_arrays, @num_channels)

    return AudioUtils.scale(composited_sample_data, @num_channels, sound_file_names.length)
  end
end
