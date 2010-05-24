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
end