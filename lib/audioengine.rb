class AudioEngine
  SAMPLE_RATE = 44100
  PACK_CODE = "s*"   # All sample data is assumed to be 16-bit

  def initialize(song, kit)
    @song = song
    @kit = kit
    
    @tick_sample_length = AudioUtils.tick_sample_length(SAMPLE_RATE, @song.tempo) 
    @pattern_cache = {}
    @track_cache = {}
  end

  def write_to_file(output_file_name)
    packed_pattern_cache = {}
    num_tracks_in_song = @song.total_tracks
    samples_written = 0
    
    wave_file = BeatsWaveFile.new(@kit.num_channels, SAMPLE_RATE, @kit.bits_per_sample)
    file = wave_file.open_for_appending(output_file_name)

    incoming_overflow = {}
    @song.flow.each do |pattern_name|
      key = [pattern_name, incoming_overflow.hash]
      unless packed_pattern_cache.member?(key)
        sample_data = generate_pattern_sample_data(@song.patterns[pattern_name], incoming_overflow)

        if @kit.num_channels == 1
          # Don't flatten the sample data Array, since it is already flattened. That would be a waste of time, yo.
          packed_pattern_cache[key] = {:primary        => sample_data[:primary].pack(PACK_CODE),
                                       :overflow       => sample_data[:overflow],
                                       :primary_length => sample_data[:primary].length}
        else
          packed_pattern_cache[key] = {:primary        => sample_data[:primary].flatten.pack(PACK_CODE),
                                       :overflow       => sample_data[:overflow],
                                       :primary_length => sample_data[:primary].length}
        end
      end

      file.syswrite(packed_pattern_cache[key][:primary])
      incoming_overflow = packed_pattern_cache[key][:overflow]
      samples_written += packed_pattern_cache[key][:primary_length]
    end

    # Write any remaining overflow from the final pattern
    final_overflow_composite = AudioUtils.composite(incoming_overflow.values)
    final_overflow_composite = AudioUtils.normalize(final_overflow_composite, num_tracks_in_song)
    if @kit.num_channels == 1
      file.syswrite(final_overflow_composite.pack(PACK_CODE))
    else
      file.syswrite(final_overflow_composite.flatten.pack(PACK_CODE))
    end
    samples_written += final_overflow_composite.length
    
    # Now that we know how many samples have been written, go back and re-write the correct header.
    file.sysseek(0)
    wave_file.write_header(file, samples_written)

    file.close()

    return wave_file.calculate_duration(SAMPLE_RATE, samples_written)
  end

  def generate_pattern_sample_data(pattern, incoming_overflow)
    primary_sample_data, overflow_sample_data = generate_main_sample_data(pattern)
    primary_sample_data, overflow_sample_data = handle_incoming_overflow(pattern,
                                                                         incoming_overflow,
                                                                         primary_sample_data,
                                                                         overflow_sample_data)
    primary_sample_data = AudioUtils.normalize(primary_sample_data, @song.total_tracks)
    
    return {:primary => primary_sample_data, :overflow => overflow_sample_data}
  end

  attr_reader :tick_sample_length

private

  def generate_main_sample_data(pattern)
    primary_sample_data = []
    overflow_sample_data = {}
    
    if @pattern_cache[pattern] == nil
      raw_track_sample_arrays = []
      pattern.tracks.each do |track_name, track|
        temp = AudioUtils.generate_rhythm(track.beats, @tick_sample_length, @kit.get_sample_data(track.name))
        raw_track_sample_arrays << temp[:primary]
        overflow_sample_data[track_name] = temp[:overflow]
      end

      primary_sample_data = AudioUtils.composite(raw_track_sample_arrays)
      
      @pattern_cache[pattern] = {:primary => primary_sample_data.dup, :overflow => overflow_sample_data.dup}
    else
      primary_sample_data = @pattern_cache[pattern][:primary].dup
      overflow_sample_data = @pattern_cache[pattern][:overflow].dup
    end
  
    return primary_sample_data, overflow_sample_data
  end

  def handle_incoming_overflow(pattern, incoming_overflow, primary_sample_data, overflow_sample_data)
    track_names = pattern.tracks.keys
  
    # Add overflow from previous pattern
    incoming_overflow.keys.each do |track_name|
      num_incoming_overflow_samples = incoming_overflow[track_name].length
    
      if num_incoming_overflow_samples > 0
        if track_names.member?(track_name)
          # TODO: Does this handle situations where track has a .... rhythm and overflow is
          # longer than track length?
        
          intro_length = pattern.tracks[track_name].intro_sample_length(@tick_sample_length)
          if num_incoming_overflow_samples > intro_length
            num_incoming_overflow_samples = intro_length
          end
        else
          # If incoming overflow for track is longer than the pattern length, only add the first part of
          # the overflow to the pattern, and add the remainder to overflow_sample_data so that it gets
          # handled by the next pattern to be generated.
          if num_incoming_overflow_samples > primary_sample_data.length
            overflow_sample_data[track_name] = (incoming_overflow[track_name])[primary_sample_data.length...num_incoming_overflow_samples]
            num_incoming_overflow_samples = primary_sample_data.length
          end
        end
      
        if @kit.num_channels == 1
          num_incoming_overflow_samples.times {|i| primary_sample_data[i] += incoming_overflow[track_name][i]}
        else
          num_incoming_overflow_samples.times do |i|
            primary_sample_data[i] = [primary_sample_data[i][0] + incoming_overflow[track_name][i][0],
                                      primary_sample_data[i][1] + incoming_overflow[track_name][i][1]]
          end
        end
      end
    end
  
    return primary_sample_data, overflow_sample_data
  end
end
