require "includes"

class AudioEngineTest < Minitest::Test
  def test_initialize
    audio_engine = AudioEngine.new(Song.new, MONO_KIT)  # Default song tempo of 120
    assert_equal(5512.5, audio_engine.step_sample_length)

    song = Song.new
    song.tempo = 100
    audio_engine = AudioEngine.new(song, MONO_KIT)
    assert_equal(6615.0, audio_engine.step_sample_length)
  end


  MONO_KIT_ITEMS = { "sound" => [-10, 20, 30, -40],
                     "longer_sound" => [-100, 200, 300, -400, -500, 600],
                     "shorter_sound" => [-1, 2],
                     "zero_sample" => [0] }
  MONO_KIT = Kit.new(MONO_KIT_ITEMS, 1, 16)

  STEREO_KIT_ITEMS = { "sound" => [[-10, 90], [20, -80], [30, -70], [-40, 60]],
                       "longer_sound" => [[-100, 900], [200, -800], [300, -700], [-400, 600], [-500, 500], [600, -400]],
                       "shorter_sound" => [[-1, 9], [2, -8]],
                       "zero_sample" => [[0, 0]] }
  STEREO_KIT = Kit.new(STEREO_KIT_ITEMS, 2, 16)


  # These tests use unrealistically short sounds and step sample lengths, to make tests easier to work with.
  #
  # "b" is short for "beat", and "r" is short for "rest", and "o" is short for "overflow"
  def test_generate_track_sample_data
    [MONO_KIT, STEREO_KIT].each do |kit|
      sound_samples = kit.get_sample_data("sound")
      zero_sample = kit.get_sample_data("zero_sample")

      # 1.) Tick sample length is equal to the length of the sound sample data.
      #     When this is the case, overflow should never occur.
      #     In practice, this will probably not occur often, but these tests act as a form of sanity check.
      b = sound_samples
      r = zero_sample * 4
      helper_generate_track_sample_data(kit, "",       4, [])
      helper_generate_track_sample_data(kit, "X",      4, b)
      helper_generate_track_sample_data(kit, "X.",     4, b + r)
      helper_generate_track_sample_data(kit, ".X",     4, r + b)
      helper_generate_track_sample_data(kit, "...X.",  4, r + r + r + b + r)
      helper_generate_track_sample_data(kit, ".X.XX.", 4, r + b + r + b + b + r)
      helper_generate_track_sample_data(kit, "...",    4, r + r + r)

      # 2A.) Tick sample length is longer than the sound sample data. This is similar to (1), except that there should
      #     be some extra silence after the end of each trigger.
      #     Like (1), overflow should never occur.
      b = sound_samples + zero_sample + zero_sample
      r = zero_sample * 6
      helper_generate_track_sample_data(kit, "",       6, [])
      helper_generate_track_sample_data(kit, "X",      6, b)
      helper_generate_track_sample_data(kit, "X.",     6, b + r)
      helper_generate_track_sample_data(kit, ".X",     6, r + b)
      helper_generate_track_sample_data(kit, "...X.",  6, r + r + r + b + r)
      helper_generate_track_sample_data(kit, ".X.XX.", 6, r + b + r + b + b + r)
      helper_generate_track_sample_data(kit, "...",    6, r + r + r)

      # 2B.) Tick sample length is longer than the sound sample data, but not by an integer amount.
      #
      # Each step of 5.83 samples should end on the following boundaries:
      # Tick:               1,     2,     3,     4,     5,     6
      # Raw:        0.0, 5.83, 11.66, 17.49, 23.32, 29.15, 34.98
      # Quantized:    0,    5,    11,    17,    23,    29,    34
      b5 = sound_samples + zero_sample                 # Beat that is 5 samples long
      b6 = sound_samples + zero_sample + zero_sample   # Beat that is 6 samples long
      r5 = zero_sample * 5                             # Rest that is 5 samples long
      r6 = zero_sample * 6                             # Rest that is 6 samples long
      helper_generate_track_sample_data(kit, "",       5.83, [])
      helper_generate_track_sample_data(kit, "X",      5.83, b5)
      helper_generate_track_sample_data(kit, "X.",     5.83, b5 + r6)
      helper_generate_track_sample_data(kit, ".X",     5.83, r5 + b6)
      helper_generate_track_sample_data(kit, "...X.",  5.83, r5 + r6 + r6 + b6 + r6)
      helper_generate_track_sample_data(kit, ".X.XX.", 5.83, r5 + b6 + r6 + b6 + b6 + r5)
      helper_generate_track_sample_data(kit, "...",    5.83, r5 + r6 + r6)

      # 3A.) Tick sample length is shorter than the sound sample data. Overflow will now occur!
      b = sound_samples[0..1]
      o = sound_samples[2..3]
      r = zero_sample * 2
      helper_generate_track_sample_data(kit, "",       2, [],                    [])
      helper_generate_track_sample_data(kit, "X",      2, b,                     o)
      helper_generate_track_sample_data(kit, "X.",     2, b + o,                 [])
      helper_generate_track_sample_data(kit, ".X",     2, r + b,                 o)
      helper_generate_track_sample_data(kit, "...X.",  2, r + r + r + b + o,     [])
      helper_generate_track_sample_data(kit, ".X.XX.", 2, r + b + o + b + b + o, [])
      helper_generate_track_sample_data(kit, "...",    2, r + r + r,             [])

      # 3B.) Tick sample length is shorter than sound sample data, such that a beat other than the final one
      #      would extend past the end of the rhythm if not cut off. Make sure that the sample data array doesn't
      #      inadvertently lengthen as a result.
      b = sound_samples[0..0]
      o = sound_samples[1..3]
      helper_generate_track_sample_data(kit, "XX", 1, b + b, o)

      # 3C.) Tick sample length is shorter than the sound sample data, but not by an integer amount.
      #
      # Each step of 1.83 samples should end on the following boundaries:
      # Tick:               1,    2,    3,    4,    5,     6
      # Raw:        0.0, 1.83, 3.66, 5.49, 7.32, 9.15, 10.98
      # Quantized:    0,    1,    3,    5,    7,    9,    10
      b = sound_samples
      r1 = zero_sample      # Rest that is 1 sample long
      r2 = zero_sample * 2  # Rest that is 2 samples long
      helper_generate_track_sample_data(kit, "",       1.83,                                             [])
      helper_generate_track_sample_data(kit, "X",      1.83, b[0..0],                                    b[1..3])
      helper_generate_track_sample_data(kit, "X.",     1.83, b[0..0] + b[1..2],                          b[3..3])
      helper_generate_track_sample_data(kit, ".X",     1.83, r1 + b[0..1],                               b[2..3])
      helper_generate_track_sample_data(kit, "...X.",  1.83, r1 + r2 + r2 + b[0..1] + b[2..3],           [])
      helper_generate_track_sample_data(kit, ".X.XX.", 1.83, r1 + b[0..1] + b[2..3] + b[0..1] + b[0..2], b[3..3])
      helper_generate_track_sample_data(kit, "...",    1.83, r1 + r2 + r2,                               [])
    end
  end

  def helper_generate_track_sample_data(kit, rhythm, step_sample_length, expected_primary, expected_overflow = [])
    song = song_with_step_sample_length(step_sample_length)
    track = Track.new("foo", rhythm)

    audio_engine = AudioEngine.new(song, kit)
    assert_equal(step_sample_length, audio_engine.step_sample_length)
    actual = audio_engine.send(:generate_track_sample_data, track, kit.get_sample_data("sound"))

    assert_equal(Hash,                     actual.class)
    assert_equal(["overflow", "primary"],  actual.keys.map{|key| key.to_s}.sort)
    assert_equal(expected_primary,         actual[:primary])
    assert_equal(expected_overflow,        actual[:overflow])
  end

  def test_composite_pattern_tracks
    no_overflow_tracks = [
      Track.new("sound", "X..."),
      Track.new("shorter_sound", "X.X."),
      Track.new("sound", "X.XX"),
    ]
    no_overflow_pattern = Pattern.new("no_overflow", no_overflow_tracks)

    overflow_tracks = [
      Track.new("sound", "X..X"),
      Track.new("shorter_sound", "XX.X"),
      Track.new("longer_sound", ".X.X"),
    ]
    overflow_pattern = Pattern.new("overflow", overflow_tracks)


    # Simple case, no overflow (mono)
    audio_engine = AudioEngine.new(song_with_step_sample_length(4), MONO_KIT)
    assert_equal(4, audio_engine.step_sample_length)
    primary, overflow = audio_engine.send(:composite_pattern_tracks, no_overflow_pattern)
    assert_equal([
                    -10 + -1 + -10,   20 + 2 + 20,   30 + 0 + 30,   -40 + 0 + -40,
                    0 + 0 + 0,        0 + 0 + 0,     0 + 0 + 0,     0 + 0 + 0,
                    0 + -1 + -10,     0 + 2 + 20,    0 + 0 + 30,    0 + 0 + -40,
                    0 + 0 + -10,      0 + 0 + 20,    0 + 0 + 30,    0 + 0 + -40,
                 ],
                 primary)
    assert_equal({"sound" => [], "shorter_sound" => [], "sound2" => []}, overflow)


    # Simple case, no overflow (stereo)
    audio_engine = AudioEngine.new(song_with_step_sample_length(4), STEREO_KIT)
    assert_equal(4, audio_engine.step_sample_length)
    primary, overflow = audio_engine.send(:composite_pattern_tracks, no_overflow_pattern)
    assert_equal([
                    [-10 + -1 + -10,       90 + 9 + 90],
                        [20 + 2 + 20,      -80 + -8 + -80],
                        [30 + 0 + 30,      -70 + 0 + -70],
                        [-40 + 0 + -40,    60 + 0 + 60],
                    [0 + 0 + 0,        0 + 0 + 0],
                        [0 + 0 + 0,    0 + 0 + 0],
                        [0 + 0 + 0,    0 + 0 + 0],
                        [0 + 0 + 0,    0 + 0 + 0],
                    [0 + -1 + -10,       0 + 9 + 90],
                        [0 + 2 + 20,     0 + -8 + -80],
                        [0 + 0 + 30,     0 + 0 + -70],
                        [0 + 0 + -40,    0 + 0 + 60],
                    [0 + 0 + -10,        0 + 0 + 90],
                        [0 + 0 + 20,     0 + 0 + -80],
                        [0 + 0 + 30,     0 + 0 + -70],
                        [0 + 0 + -40,    0 + 0 + 60],
                 ],
                 primary)
    assert_equal({"sound" => [], "shorter_sound" => [], "sound2" => []}, overflow)


    # Some overflow (mono)
    audio_engine = AudioEngine.new(song_with_step_sample_length(3), MONO_KIT)
    assert_equal(3, audio_engine.step_sample_length)
    primary, overflow = audio_engine.send(:composite_pattern_tracks, overflow_pattern)
    assert_equal([
                    -10 + -1 + 0,      20 + 2 + 0,     30 + 0 + 0,
                    -40 + -1 + -100,   0 + 2 + 200,    0 + 0 + 300,
                    0 + 0 + -400,      0 + 0 + -500,   0 + 0 + 600,
                    -10 + -1 + -100,   20 + 2 + 200,   30 + 0 + 300,
                 ],
                 primary)
    assert_equal({"sound" => [-40], "shorter_sound" => [], "longer_sound" => [-400, -500, 600]}, overflow)


    # Some overflow (stereo)
    audio_engine = AudioEngine.new(song_with_step_sample_length(3), STEREO_KIT)
    assert_equal(3, audio_engine.step_sample_length)
    primary, overflow = audio_engine.send(:composite_pattern_tracks, overflow_pattern)
    assert_equal([
                    [-10 + -1 + 0,      90 + 9 + 0],
                        [20 + 2 + 0,    -80 + -8 + 0],
                        [30 + 0 + 0,    -70 + 0 + 0],
                    [-40 + -1 + -100,    60 + 9 + 900],
                        [0 + 2 + 200,    0 + -8 + -800],
                        [0 + 0 + 300,    0 + 0 + -700],
                    [0 + 0 + -400,        0 + 0 + 600],
                        [0 + 0 + -500,    0 + 0 + 500],
                        [0 + 0 + 600,     0 + 0 + -400],
                    [-10 + -1 + -100,     90 + 9 + 900],
                        [20 + 2 + 200,    -80 + -8 + -800],
                        [30 + 0 + 300,    -70 + 0 + -700],
                 ],
                 primary)
    assert_equal({"sound" => [[-40, 60]], "shorter_sound" => [], "longer_sound" => [[-400, 600], [-500, 500], [600, -400]]}, overflow)
  end

  # Creates a song with a tempo such that each step will have the
  # desired sample length. Since the tests in this file use unrealistically
  # short sample lengths to make testing easier, this will result in tempos
  # that are extremely fast.
  def song_with_step_sample_length(step_sample_length)
    sample_rate = 44100
    samples_per_minute = sample_rate * 60.0
    quarter_note_sample_length = step_sample_length * 4  # Each step is a sixteenth note

    song = Song.new
    song.tempo = samples_per_minute / quarter_note_sample_length

    song
  end
end
