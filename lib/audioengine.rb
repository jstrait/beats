class AudioEngine
  SAMPLE_RATE = 44100
  SECONDS_PER_MINUTE = 60.0
  SAMPLES_PER_MINUTE = SAMPLE_RATE * SECONDS_PER_MINUTE
  DEFAULT_TEMPO = 120
  PACK_CODE = "s*"   # All sample data is assumed to be 16-bit

  def self.write_to_file(output_file_name, song, kit)
    cache = {}

    num_tracks_in_song = song.total_tracks
    sample_length = song.sample_length_with_overflow()
    
    wave_file = BeatsWaveFile.new(kit.num_channels, SAMPLE_RATE, kit.bits_per_sample)
    file = wave_file.open_for_appending(output_file_name, sample_length)

    incoming_overflow = {}
    song.flow.each do |pattern_name|
      key = [pattern_name, incoming_overflow.hash]
      unless cache.member?(key)
        sample_data = song.patterns[pattern_name].sample_data(song.tick_sample_length,
                                                              kit.num_channels,
                                                              num_tracks_in_song,
                                                              incoming_overflow)

        if kit.num_channels == 1
          # Don't flatten the sample data Array, since it is already flattened. That would be a waste of time, yo.
          cache[key] = {:primary => sample_data[:primary].pack(PACK_CODE), :overflow => sample_data[:overflow]}
        else
          cache[key] = {:primary => sample_data[:primary].flatten.pack(PACK_CODE), :overflow => sample_data[:overflow]}
        end
      end

      file.syswrite(cache[key][:primary])
      incoming_overflow = cache[key][:overflow]
    end

    wave_file.write_snippet(file, merge_overflow(incoming_overflow, kit, num_tracks_in_song))
    file.close()

    return wave_file.calculate_duration(SAMPLE_RATE, sample_length)
  end

private

  def self.merge_overflow(overflow, kit, num_tracks_in_song)
    merged_sample_data = []

    unless overflow == {}
      longest_overflow = overflow[overflow.keys.first]
      overflow.keys.each do |track_name|
        if overflow[track_name].length > longest_overflow.length
          longest_overflow = overflow[track_name]
        end
      end

      # TODO: What happens if final overflow is really long, and extends past single '.' rhythm?
      final_overflow_pattern = Pattern.new(:overflow)
      wave_data = kit.num_channels == 1 ? [] : [[]]
      final_overflow_pattern.track "", wave_data, "."
      final_overflow_sample_data = final_overflow_pattern.sample_data(longest_overflow.length, kit.num_channels, num_tracks_in_song, overflow)
      merged_sample_data = final_overflow_sample_data[:primary]
    end

    return merged_sample_data
  end
end
