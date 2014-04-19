module Beats
  class KitBuilder
    BITS_PER_SAMPLE = 16
    SAMPLE_RATE = 44100

    def initialize(base_path)
      @base_path = base_path
      @labels_to_filenames = {}
    end

    def add_item(label, filename)
      @labels_to_filenames[label] = absolute_file_name(filename)
    end

    def has_label?(label)
      @labels_to_filenames.keys.include?(label)
    end

    def build_kit
      # Load each sample buffer
      filenames_to_buffers = {}
      @labels_to_filenames.values.uniq.each do |filename|
        filenames_to_buffers[filename] = load_sample_buffer(filename)
      end

      # Convert each buffer to the same sample format
      num_channels = filenames_to_buffers.values.map(&:channels).max || 1
      canonical_format = WaveFile::Format.new(num_channels, BITS_PER_SAMPLE, SAMPLE_RATE)
      filenames_to_buffers.values.each {|buffer| buffer.convert!(canonical_format) }

      labels_to_buffers = {}
      @labels_to_filenames.each do |label, filename|
        labels_to_buffers[label] = filenames_to_buffers[filename].samples
      end

      ImmutableKit.new(labels_to_buffers, num_channels, BITS_PER_SAMPLE)
    end

    private

    # Converts relative path into absolute path. Note that this will also handle
    # expanding ~ on platforms that support that.
    def absolute_file_name(filename)
      File.expand_path(filename, @base_path)
    end

    def load_sample_buffer(filename)
      sample_buffer = nil

      begin
        info = WaveFile::Reader.info(filename)
        WaveFile::Reader.new(filename).each_buffer(info.sample_frame_count) do |buffer|
          sample_buffer = buffer
        end
      rescue Errno::ENOENT
        raise SoundFileNotFoundError, "Sound file #{filename} not found."
      rescue StandardError
        raise InvalidSoundFormatError, "Sound file #{filename} is either not a sound file, " +
                                       "or is in an unsupported format. BEATS can handle 8, 16, 24, or 32-bit PCM *.wav files."
      end

      sample_buffer
    end
  end

  # Raised when trying to load a sound file which can't be found at the path specified
  class SoundFileNotFoundError < RuntimeError; end

  # Raised when trying to load a sound file which either isn't actually a sound file, or
  # is in an unsupported format.
  class InvalidSoundFormatError < RuntimeError; end

  class ImmutableKit
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
      if label == "placeholder"
        return []
      end

      sample_data = @items[label]

      if sample_data.nil?
        # TODO: Should we really throw an exception here rather than just returning nil?
        raise StandardError, "Kit doesn't contain sound '#{label}'."
      end

      sample_data
    end
  end
end
