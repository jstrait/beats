# Raised when trying to load a sound file which can't be found at the path specified
class SoundNotFoundError < RuntimeError; end

# This class keeps track of the sounds that are used in a song. It provides a
# central place for storing sound data, and most usefully, handles converting
# sounds in different formats to a standard format.
#
# For example, if a song requires a sound that is mono/8-bit, another that is
# stereo/8-bit, and another that is stereo/16-bit, it can't mix them together
# because they are in different formats. Kit however automatically handles the
# details of converting them to a common format. Sounds that you get using
# get_sample_data() will be in a common format.
#
# This class is immutable. Once a Kit is created, no new sounds can be added to it.
class Kit
  def initialize(base_path, kit_items)
    @base_path = base_path
    @label_mappings = {}
    @sound_bank = {}
    @num_channels = 1
    @bits_per_sample = 16  # Only use 16-bit files as output. Supporting 8-bit output
                           # means extra complication for no real gain (I'm skeptical
                           # anyone would explicitly want 8-bit output instead of 16-bit.
                           
    load_sounds(base_path, kit_items)
  end
  
  def get_sample_data(label)
    sample_data = @sound_bank[label]
    
    if sample_data == nil
      raise StandardError, "Kit doesn't contain sound '#{name}'."
    else
      return sample_data
    end
  end
  
  # Produces nicer looking output than the default version of to_yaml().
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

  def get_absolute_path(base_path, sound_file_name)
    path_is_absolute = sound_file_name.start_with?(File::SEPARATOR)
    return path_is_absolute ? sound_file_name : (base_path + File::SEPARATOR + sound_file_name)
  end

  def load_sounds(base_path, kit_items)
    # Make all sound file paths absolute
    kit_items.each do |label, sound_file_name|
      unless label == sound_file_name
        @label_mappings[label] = sound_file_name
      end
      kit_items[label] = get_absolute_path(base_path, sound_file_name)
    end
    
    # Load all sound files, bailing if any are invalid
    raw_sounds = {}
    kit_items.values.each do |sound_file_name|
      begin
        wavefile = WaveFile.open(sound_file_name)
      rescue
        # TODO: Raise different error if sound is in an unsupported format
        raise SoundNotFoundError, "Sound file #{sound_file_name} not found."
      end
      @num_channels = [@num_channels, wavefile.num_channels].max
      raw_sounds[sound_file_name] = wavefile
    end
    
    # Convert each sound to a canonical format
    raw_sounds.values.each do |wavefile|
      wavefile.num_channels = @num_channels
      wavefile.bits_per_sample = @bits_per_sample
    end
    
    kit_items.each do |label, sound_file_name|
      @sound_bank[label] = raw_sounds[sound_file_name].sample_data
    end
  end
end
