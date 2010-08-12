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
# This class is immutable. All sounds should be added at initialization.
# Once a Kit is created, no new sounds can be added to it.
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
  
  def get_sample_data(label)
    sample_data = @sound_bank[label]
    
    if sample_data == nil
      raise StandardError, "Kit doesn't contain sound '#{label}'."
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

  def load_sounds(base_path, kit_items)
    # Set label mappings
    kit_items.each do |label, sound_file_names|
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
  
  def longest_sample_data_length(arr)
    return arr.inject(0) {|max_length, sample_data| (sample_data.length > max_length) ? sample_data.length : max_length }
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
      rescue
        # TODO: Raise different error if sound is in an unsupported format
        raise SoundNotFoundError, "Sound file #{sound_file_name} not found."
      end
      @num_channels = [@num_channels, wavefile.num_channels].max
      raw_sounds[sound_file_name] = wavefile
    end
    
    return raw_sounds
  end
  
  def mixdown(sound_file_names, raw_sounds)
    num_sounds = sound_file_names.length
    sound_name = sound_file_names.pop
    mixdown = raw_sounds[sound_name].sample_data.dup
    sound_file_names.each do |sound_file_name|
      sample_data = raw_sounds[sound_file_name].sample_data
      if(mixdown.length > sample_data.length)
        incoming_samples = sample_data
      else
        incoming_samples = mixdown
        mixdown = sample_data
      end
      
      if @num_channels == 1
        incoming_samples.length.times {|i| mixdown[i] += incoming_samples[i]}
      elsif @num_channels == 2
        incoming_samples.length.times do |i|
          mixdown[i] = [mixdown[i][0] + incoming_samples[i][0],
                        mixdown[i][1] + incoming_samples[i][1]]
        end
      end
    end
    
    if num_sounds > 1
      if @num_channels == 1
        mixdown = mixdown.map {|sample| sample / num_sounds }
      elsif @num_channels == 2
        mixdown = mixdown.map {|sample| [sample[0] / num_sounds, sample[1] / num_sounds] }
      end
    end
    
    return mixdown
  end
end
