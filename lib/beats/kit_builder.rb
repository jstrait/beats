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

      Kit.new(labels_to_buffers, num_channels, BITS_PER_SAMPLE)
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
        # Check if remote file
        if filename.include?('http:')
          remote_filename = 'http://' + filename.split('http:/').last
          # Create a local representation of the remote resource
          remote_resource = RemoteResource.new(remote_filename)
          # We have a copy of the remote file for processing
          tmp_file = remote_resource.file
          filename = tmp_file
        end
        
        # Move along
        info = WaveFile::Reader.info(filename)
        WaveFile::Reader.new(filename).each_buffer(info.sample_frame_count) do |buffer|
          sample_buffer = buffer
        end

      rescue Errno::ENOENT
        raise SoundFileNotFoundError, "Sound file #{filename} not found."
      rescue StandardError
        raise InvalidSoundFormatError, "Sound file #{filename} is either not a sound file, " +
                                       "or is in an unsupported format. BEATS can handle 8, 16, 24, or 32-bit PCM *.wav files."
      rescue LoadError
        raise SoundFileNotFoundError, "Sound file #{remote_filename} not found."
      end

      # Remove tmp files
      if tmp_file
        File.delete(tmp_file)
      end

      sample_buffer
    end
  end
end
