module WaveFile
  # Implementation of Writer that caches the raw wave data for each buffer that it has written.
  # If the Buffer is written again, it will write the version from cache instead of re-doing
  # a String.pack() call.
  class CachingWriter < Writer
    def initialize(io_or_file_name, format)
      super

      @buffer_cache = {}
    end

    def write(buffer)
      packed_buffer_data = {}

      key = buffer.hash
      if @buffer_cache.member?(key)
        packed_buffer_data = @buffer_cache[key]
      else
        samples = buffer.convert(@format).samples

        if @format.channels > 1
          data = samples.flatten.pack(@pack_code)
        else
          # Flattening an already flat array is a waste of time.
          data = samples.pack(@pack_code)
        end

        packed_buffer_data = { data: data, sample_count: samples.length }
        @buffer_cache[key] = packed_buffer_data
      end

      @io.write(packed_buffer_data[:data])
      @total_sample_frames += packed_buffer_data[:sample_count]
    end
  end
end
