class WaveFileExtended < WaveFile
  def open_for_appending(path, num_samples)
    bytes_per_sample = (@bits_per_sample / 8)
    sample_data_size = num_samples * bytes_per_sample

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

    file = File.open(path, "w")
    file.syswrite(header)
    
    return file
  end
  
  def write_snippet(file, sample_data)
    if @bits_per_sample == 8
      pack_code = "C*"
    elsif @bits_per_sample == 16
      pack_code = "s*"
    end
    
    if @num_channels == 1
      file.syswrite(sample_data.pack(pack_code))
    else
      file.syswrite(sample_data.flatten.pack(pack_code))
    end
  end
  
  def calculate_duration(sample_rate, total_samples)
    samples_per_millisecond = sample_rate / 1000.0
    samples_per_second = sample_rate
    samples_per_minute = samples_per_second * 60
    samples_per_hour = samples_per_minute * 60
    hours, minutes, seconds, milliseconds = 0, 0, 0, 0
    
    if(total_samples >= samples_per_hour)
      hours = total_samples / samples_per_hour
      total_samples -= samples_per_hour * hours
    end
    
    if(total_samples >= samples_per_minute)
      minutes = total_samples / samples_per_minute
      total_samples -= samples_per_minute * minutes
    end
    
    if(total_samples >= samples_per_second)
      seconds = total_samples / samples_per_second
      total_samples -= samples_per_second * seconds
    end
    
    milliseconds = (total_samples / samples_per_millisecond).floor
    
    return { :hours => hours, :minutes => minutes, :seconds => seconds, :milliseconds => milliseconds }
  end
end