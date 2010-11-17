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
    sample_length = song_sample_length()
    
    wave_file = BeatsWaveFile.new(@kit.num_channels, SAMPLE_RATE, @kit.bits_per_sample)
    file = wave_file.open_for_appending(output_file_name, sample_length)

    incoming_overflow = {}
    @song.flow.each do |pattern_name|
      key = [pattern_name, incoming_overflow.hash]
      unless packed_pattern_cache.member?(key)
        sample_data = generate_pattern_sample_data(@song.patterns[pattern_name], incoming_overflow)

        if @kit.num_channels == 1
          # Don't flatten the sample data Array, since it is already flattened. That would be a waste of time, yo.
          packed_pattern_cache[key] = {:primary => sample_data[:primary].pack(PACK_CODE), :overflow => sample_data[:overflow]}
        else
          packed_pattern_cache[key] = {:primary => sample_data[:primary].flatten.pack(PACK_CODE), :overflow => sample_data[:overflow]}
        end
      end

      file.syswrite(packed_pattern_cache[key][:primary])
      incoming_overflow = packed_pattern_cache[key][:overflow]
    end

    # Write any remaining overflow from the final pattern
    final_overflow_composite = AudioUtils.composite(incoming_overflow.values)
    final_overflow_composite = AudioUtils.normalize(final_overflow_composite, num_tracks_in_song)
    wave_file.write_snippet(file, final_overflow_composite)
    
    file.close()

    return wave_file.calculate_duration(SAMPLE_RATE, sample_length)
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


  # TODO: What if pattern before final pattern has really long sample that extends past the end of the last pattern's overflow?
  def song_sample_length()
    if @song.flow.length == 0
      return 0
    end

    patterns = @song.patterns

    primary_sample_length = @song.flow.inject(0) do |sum, pattern_name|
      sum + pattern_sample_length(patterns[pattern_name])[:primary]
    end

    last_pattern_name = @song.flow.last
    last_pattern_sample_length = pattern_sample_length(patterns[last_pattern_name])

    return primary_sample_length + last_pattern_sample_length[:overflow]
  end

  attr_reader :tick_sample_length

private

  def pattern_sample_length(pattern)
    primary_sample_lengths = []
    overflow_sample_lengths = []

    track_lengths = pattern.tracks.collect do |track_name, track|
      track_sample_length = track_sample_length(track)
      primary_sample_lengths << track_sample_length[:primary]
      overflow_sample_lengths << track_sample_length[:overflow]
    end
    
    return {:primary => primary_sample_lengths.max || 0, :overflow => overflow_sample_lengths.max || 0}
  end

  def track_sample_length(track)
    primary_sample_length = (track.tick_count * @tick_sample_length).floor
    
    # Does this account for non-integer tick sample lengths in previous beats?
    sound_sample_data = @kit.get_sample_data(track.name)
    unless track.beats == [0]
      beat_sample_length = track.beats.last * @tick_sample_length
      if(sound_sample_data.length > beat_sample_length)
        overflow_sample_length = sound_sample_data.length - beat_sample_length.floor
      else
        overflow_sample_length = 0
      end
    end
    
    return {:primary => primary_sample_length, :overflow => overflow_sample_length}
  end

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
