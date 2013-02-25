module Beats
  # This class actually generates the output audio data that is saved to disk.
  #
  # To produce audio data, it needs two things: a Song and a Kit. The Song tells
  # it which sounds to trigger and when, while the Kit provides the sample data
  # for each of these sounds.
  #
  # Example usage, assuming song and kit are already defined:
  #
  #   engine = AudioEngine.new(song, kit)
  #   engine.write_to_file("my_song.wav")
  #
  class AudioEngine
    SAMPLE_RATE = 44100
    PACK_CODE = "s*"   # All output sample data is assumed to be 16-bit

    def initialize(song, kit)
      @song = song
      @kit = kit

      @step_sample_length = AudioUtils.step_sample_length(SAMPLE_RATE, @song.tempo)
      @composited_pattern_cache = {}
    end

    def write_to_file(output_file_name)
      packed_pattern_cache = {}
      num_tracks_in_song = @song.total_tracks

      # Open output wave file and prepare it for writing sample data.
      format = WaveFile::Format.new(@kit.num_channels, @kit.bits_per_sample, SAMPLE_RATE)
      writer = WaveFile::CachingWriter.new(output_file_name, format)

      # Generate each pattern's sample data, or pull it from cache, and append it to the wave file.
      incoming_overflow = {}
      @song.flow.each do |pattern_name|
        key = [pattern_name, incoming_overflow.hash]
        unless packed_pattern_cache.member?(key)
          sample_data = generate_pattern_sample_data(@song.patterns[pattern_name], incoming_overflow)

          packed_pattern_cache[key] = { :primary => WaveFile::Buffer.new(sample_data[:primary], format),
                                        :overflow => WaveFile::Buffer.new(sample_data[:overflow], format) }
        end

        writer.write(packed_pattern_cache[key][:primary])
        incoming_overflow = packed_pattern_cache[key][:overflow].samples
      end

      # Write any remaining overflow from the final pattern
      final_overflow_composite = AudioUtils.composite(incoming_overflow.values, format.channels)
      final_overflow_composite = AudioUtils.scale(final_overflow_composite, format.channels, num_tracks_in_song)
      writer.write(WaveFile::Buffer.new(final_overflow_composite, format))

      writer.close()

      writer.total_duration
    end

    attr_reader :step_sample_length

  private

    # Generates the sample data for a single track, using the specified sound's sample data.
    def generate_track_sample_data(track, sound)
      beats = track.beats
      if beats == [0]
        return {:primary => [], :overflow => []}    # Is this really what should happen? Why throw away overflow?
      end

      fill_value = (@kit.num_channels == 1) ? 0 : [0, 0]
      primary_sample_data = [].fill(fill_value, 0, AudioUtils.step_start_sample(track.step_count, @step_sample_length))

      step_index = beats[0]
      beat_sample_length = 0
      beats[1...(beats.length)].each do |beat_step_length|
        start_sample = AudioUtils.step_start_sample(step_index, @step_sample_length)
        end_sample = [(start_sample + sound.length), primary_sample_data.length].min
        beat_sample_length = end_sample - start_sample

        primary_sample_data[start_sample...end_sample] = sound[0...beat_sample_length]

        step_index += beat_step_length
      end

      overflow_sample_data = (sound == [] || beats.length == 1) ? [] : sound[beat_sample_length...(sound.length)]

      {:primary => primary_sample_data, :overflow => overflow_sample_data}
    end

    # Composites the sample data for each of the pattern's tracks, and returns the overflow sample data
    # from tracks whose last sound trigger extends past the end of the pattern. This overflow can be
    # used by the next pattern to avoid sounds cutting off when the pattern changes.
    def generate_pattern_sample_data(pattern, incoming_overflow)
      # Unless cached, composite each track's sample data.
      if @composited_pattern_cache[pattern].nil?
        primary_sample_data, overflow_sample_data = composite_pattern_tracks(pattern)
        @composited_pattern_cache[pattern] = {:primary => primary_sample_data.dup, :overflow => overflow_sample_data.dup}
      else
        primary_sample_data = @composited_pattern_cache[pattern][:primary].dup
        overflow_sample_data = @composited_pattern_cache[pattern][:overflow].dup
      end

      # Composite overflow from the previous pattern onto this pattern, to prevent sounds from cutting off.
      primary_sample_data, overflow_sample_data = handle_incoming_overflow(pattern,
                                                                           incoming_overflow,
                                                                           primary_sample_data,
                                                                           overflow_sample_data)
      primary_sample_data = AudioUtils.scale(primary_sample_data, @kit.num_channels, @song.total_tracks)

      {:primary => primary_sample_data, :overflow => overflow_sample_data}
    end

    def composite_pattern_tracks(pattern)
      overflow_sample_data = {}

      raw_track_sample_arrays = []
        pattern.tracks.each do |track_name, track|
          temp = generate_track_sample_data(track, @kit.get_sample_data(track.name))
          raw_track_sample_arrays << temp[:primary]
          overflow_sample_data[track_name] = temp[:overflow]
        end

      primary_sample_data = AudioUtils.composite(raw_track_sample_arrays, @kit.num_channels)
      return primary_sample_data, overflow_sample_data
    end

    # Applies sound overflow (i.e. long sounds such as cymbal crash which extend past the last step)
    # from the previous pattern in the flow to the current pattern. This prevents sounds from being
    # cut off when the pattern changes.
    #
    # It would probably be shorter and conceptually simpler to deal with incoming overflow in
    # generate_track_sample_data() instead of this method. (In fact, this method would go away).
    # However, doing it this way allows for caching composited pattern sample data, and
    # applying incoming overflow to the composite. This allows each pattern to only be composited once,
    # regardless of the incoming overflow that each performance of it receives. If incoming overflow
    # was handled at the Track level we couldn't do that.
    def handle_incoming_overflow(pattern, incoming_overflow, primary_sample_data, overflow_sample_data)
      pattern_track_names = pattern.tracks.keys
      sample_arrays = [primary_sample_data]

      incoming_overflow.each do |incoming_track_name, incoming_sample_data|
        end_sample = incoming_sample_data.length

        if pattern_track_names.member?(incoming_track_name)
          track = pattern.tracks[incoming_track_name]

          if track.beats.length > 1
            intro_length = (pattern.tracks[incoming_track_name].beats[0] * step_sample_length).floor
            end_sample = [end_sample, intro_length].min
          end
        end

        if end_sample > primary_sample_data.length
          end_sample = primary_sample_data.length
          overflow_sample_data[incoming_track_name] = incoming_sample_data[(primary_sample_data.length)...(incoming_sample_data.length)]
        end

        sample_arrays << incoming_sample_data[0...end_sample]
      end

      return AudioUtils.composite(sample_arrays, @kit.num_channels), overflow_sample_data
    end
  end
end
