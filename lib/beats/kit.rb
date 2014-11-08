module Beats
  # Raised when trying to load a sound file which can't be found at the path specified
  class SoundFileNotFoundError < RuntimeError; end

  # Raised when trying to load a sound file which either isn't actually a sound file, or
  # is in an unsupported format.
  class InvalidSoundFormatError < RuntimeError; end

  class Kit
    def initialize(items, num_channels, bits_per_sample)
      @items = items
      @num_channels = num_channels
      @bits_per_sample = bits_per_sample
    end

    attr_reader :num_channels, :bits_per_sample

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
      sample_data = @items[label]

      if sample_data.nil?
        # TODO: Should we really throw an exception here rather than just returning nil?
        raise StandardError, "Kit doesn't contain sound '#{label}'."
      end

      sample_data
    end
  end
end
