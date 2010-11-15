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
    num_tracks_in_song = @song.total_tracks
    sample_length = song_sample_length()
    
    wave_file = BeatsWaveFile.new(@kit.num_channels, SAMPLE_RATE, @kit.bits_per_sample)
    file = wave_file.open_for_appending(output_file_name, sample_length)

    incoming_overflow = {}
    @song.flow.each do |pattern_name|
      key = [pattern_name, incoming_overflow.hash]
      unless @pattern_cache.member?(key)
        sample_data = @song.patterns[pattern_name].sample_data(@tick_sample_length,
                                                               @kit.num_channels,
                                                               num_tracks_in_song,
                                                               incoming_overflow)
        

        if @kit.num_channels == 1
          # Don't flatten the sample data Array, since it is already flattened. That would be a waste of time, yo.
          @pattern_cache[key] = {:primary => sample_data[:primary].pack(PACK_CODE), :overflow => sample_data[:overflow]}
        else
          @pattern_cache[key] = {:primary => sample_data[:primary].flatten.pack(PACK_CODE), :overflow => sample_data[:overflow]}
        end
      end

      file.syswrite(@pattern_cache[key][:primary])
      incoming_overflow = @pattern_cache[key][:overflow]
    end

    wave_file.write_snippet(file, merge_overflow(incoming_overflow, num_tracks_in_song))
    file.close()

    return wave_file.calculate_duration(SAMPLE_RATE, sample_length)
  end

  def song_sample_length()
    if @song.flow.length == 0
      return 0
    end

    patterns = @song.patterns

    primary_sample_length = @song.flow.inject(0) do |sum, pattern_name|
      sum + patterns[pattern_name].sample_length(@tick_sample_length)
    end

    last_pattern_name = @song.flow.last
    last_pattern_sample_length = patterns[last_pattern_name].sample_length(@tick_sample_length)
    last_pattern_overflow_length = patterns[last_pattern_name].sample_length_with_overflow(@tick_sample_length)
    overflow_sample_length = last_pattern_overflow_length - last_pattern_sample_length

    return primary_sample_length + overflow_sample_length
  end

  attr_reader :tick_sample_length

private

  def merge_overflow(overflow, num_tracks_in_song)
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
      wave_data = @kit.num_channels == 1 ? [] : [[]]
      final_overflow_pattern.track "", wave_data, "."
      final_overflow_sample_data = final_overflow_pattern.sample_data(longest_overflow.length, @kit.num_channels, num_tracks_in_song, overflow)
      merged_sample_data = final_overflow_sample_data[:primary]
    end

    return merged_sample_data
  end
end
