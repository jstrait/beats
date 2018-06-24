module Beats
  class KitBuilder
    # Raised when trying to load a sound file which can't be found at the path specified
    class SoundFileNotFoundError < RuntimeError; end

    # Raised when trying to load a sound file which either isn't actually a sound file, or
    # is in an unsupported format.
    class InvalidSoundFormatError < RuntimeError; end

    BITS_PER_SAMPLE = 16
    SAMPLE_FORMAT = "pcm_#{BITS_PER_SAMPLE}".to_sym
    SAMPLE_RATE = 44100

    def initialize(base_path)
      @base_path = base_path
      @labels_to_filenames = {}
      @composite_replacements = {}
    end

    def add_item(label, filenames)
      if filenames.is_a?(Array)
        if filenames.empty?
          raise SoundFileNotFoundError, "Kit sound '#{label}' is an empty composite sound (i.e. \"[]\"), which is not valid."
        end

        filenames.each do |filename|
          unless filename.is_a?(String)
            raise SoundFileNotFoundError, "The Kit sound '#{label}' contains an invalid file: '#{filename}'"
          end
          @labels_to_filenames["#{label}-#{File.basename(filename, ".*")}"] = absolute_file_name(filename)
        end

        @composite_replacements[label] = filenames.map {|filename| "#{label}-#{File.basename(filename, ".*")}" }
      else
        @labels_to_filenames[label] = absolute_file_name(filenames)
      end
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
      canonical_format = WaveFile::Format.new(num_channels, SAMPLE_FORMAT, SAMPLE_RATE)
      filenames_to_buffers.values.each {|buffer| buffer.convert!(canonical_format) }

      labels_to_buffers = {}
      @labels_to_filenames.each do |label, filename|
        labels_to_buffers[label] = filenames_to_buffers[filename].samples
      end
      labels_to_buffers[Kit::PLACEHOLDER_TRACK_NAME] = []

      Kit.new(labels_to_buffers, num_channels, BITS_PER_SAMPLE)
    end

    attr_reader :composite_replacements

    private

    # Converts relative path into absolute path. Note that this will also handle
    # expanding ~ on platforms that support that.
    def absolute_file_name(filename)
      File.expand_path(filename, @base_path)
    end

    def load_sample_buffer(filename)
      sample_buffer = nil

      begin
        reader = WaveFile::Reader.new(filename)
        reader.each_buffer(reader.total_sample_frames) do |buffer|
          sample_buffer = buffer
        end
      rescue Errno::ENOENT
        raise SoundFileNotFoundError, "Sound file `#{filename}` not found."
      rescue WaveFile::UnsupportedFormatError
        raise InvalidSoundFormatError, "Sound file `#{filename}` is not a supported *.wav format. Beats can use *.wav files with a sample format of 8/16/24/32 PCM or floating point."
      rescue WaveFile::InvalidFormatError
        raise InvalidSoundFormatError, "Sound file `#{filename}` is either not a sound file, or is in an unsupported format. Beats can use *.wav files with a sample format of 8/16/24/32 PCM or floating point."
      end

      sample_buffer
    end
  end
end
