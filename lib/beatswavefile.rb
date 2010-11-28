# Adds some functionality to the WaveFile gem that allows for improved performance. The 
# use of open_for_appending() allows a wave file to be written to disk in chunks, instead
# of all at once. This improves performance (and I would assume memory usage) by eliminating
# the need to store the entire sample data for the song in memory in a giant (i.e. millions
# of elements) array.
#
# I'm not sure these methods in their current form are suitable for the WaveFile gem.
# If I figure out a better API I might add it to the WaveFile gem in the future, but until
# then I'm just putting it here. Since BEATS is a stand-alone app and not a re-usable library,
# I don't think this should be a problem.
class BeatsWaveFile < WaveFile
  
  # Writes the header for the wave file to path, and returns an open File object that
  # can be used outside the method to append the sample data. WARNING: The header contains
  # a field for the total number of samples in the file. This number of samples (and exactly
  # this number of samples) must be subsequently be written to the file before it is closed
  # or it won't be valid and you won't be able to play it.
  def open_for_appending(path)
    file = File.open(path, "w")
    write_header(file, 0)
    
    return file
  end

  def write_header(file, sample_length)
    bytes_per_sample = (@bits_per_sample / 8)
    sample_data_size = sample_length * bytes_per_sample * @num_channels

    # Write the header
    header = CHUNK_ID
    header += [HEADER_SIZE + sample_data_size].pack("V")
    header += FORMAT
    header += FORMAT_CHUNK_ID
    header += [SUB_CHUNK1_SIZE].pack("V")
    header += [PCM].pack("v")
    header += [@num_channels].pack("v")
    header += [@sample_rate].pack("V")
    header += [@byte_rate].pack("V")
    header += [@block_align].pack("v")
    header += [@bits_per_sample].pack("v")
    header += DATA_CHUNK_ID
    header += [sample_data_size].pack("V")

    file.syswrite(header)
  end
  
  def calculate_duration(sample_rate, total_samples)
    samples_per_millisecond = sample_rate / 1000.0
    samples_per_second = sample_rate
    samples_per_minute = samples_per_second * 60
    samples_per_hour = samples_per_minute * 60
    hours, minutes, seconds, milliseconds = 0, 0, 0, 0
    
    if total_samples >= samples_per_hour
      hours = total_samples / samples_per_hour
      total_samples -= samples_per_hour * hours
    end
    
    if total_samples >= samples_per_minute
      minutes = total_samples / samples_per_minute
      total_samples -= samples_per_minute * minutes
    end
    
    if total_samples >= samples_per_second
      seconds = total_samples / samples_per_second
      total_samples -= samples_per_second * seconds
    end
    
    milliseconds = (total_samples / samples_per_millisecond).floor
    
    return { :hours => hours, :minutes => minutes, :seconds => seconds, :milliseconds => milliseconds }
  end
end
