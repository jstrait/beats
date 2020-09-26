require "includes"

# Make private methods public for testing
class MockAudioEngine < AudioEngine
  def generate_track_sample_data(track, sound)
    super
  end

  def composite_pattern_tracks(pattern)
    super
  end

  attr_accessor :step_sample_length
end

class AudioEngineTest < Minitest::Test
  FIXTURES = [:repeats_not_specified,
              :pattern_with_overflow,
              :example_no_kit,
              :example_with_kit]

  def load_fixtures
    test_audio_engines = {}
    base_path = File.dirname(__FILE__) + "/.."

    test_audio_engines[:blank] = AudioEngine.new(Song.new, KitBuilder.new(base_path).build_kit)

    FIXTURES.each do |fixture_name|
      song, kit = SongParser.parse(base_path, File.read("test/fixtures/valid/#{fixture_name}.txt"))
      test_audio_engines[fixture_name] = AudioEngine.new(song, kit)
    end

    test_audio_engines
  end

  def test_initialize
    test_audio_engines = load_fixtures

    assert_equal(5512.5, test_audio_engines[:blank].step_sample_length)
    assert_equal(6615.0, test_audio_engines[:repeats_not_specified].step_sample_length)
  end


  # S           Sample data for a sound. Unrealistically short for clarity.
  # S_LONG      A slightly longer sound.
  # S_SHORT     A slightly shorter Sound.
  # S_OVERFLOW  Sound overflow when step sample length is less than full sound length
  # T           Sample data for a step with no sound, with length equal to S
  # T_LONG      Sample data for a step with no sound, longer than full sound length
  # T_SHORT     Sample data for a step with no sound, shorter than full sound length
  # ZERO        A single zero sample

  MONO_KIT_ITEMS = { "S" => [-100, 200, 300, -400],
                     "S_LONG" => [-100, 200, 300, -400, 0, 0],
                     "S_SHORT" => [-100, 200],
                     "S_OVERFLOW" => [300, -400],
                     "T" => [0, 0, 0, 0],
                     "T_LONG" => [0, 0, 0, 0, 0, 0],
                     "T_SHORT" => [0, 0],
                     "ZERO" => [0] }
  MONO_KIT = Kit.new(MONO_KIT_ITEMS, 1, 16)

  STEREO_KIT_ITEMS = { "S" => [[-100, 800], [200, -700], [300, -600], [-400, 400]],
                       "S_LONG" => [[-100, 800], [200, -700], [300, -600], [-400, 400], [0, 0], [0, 0]],
                       "S_SHORT" => [[-100, 800], [200, -700]],
                       "S_OVERFLOW" => [[300, -600], [-400, 400]],
                       "T" => [[0, 0], [0, 0], [0, 0], [0, 0]],
                       "T_LONG" => [[0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0]],
                       "T_SHORT" => [[0, 0], [0, 0]],
                       "ZERO" => [[0, 0]] }
  STEREO_KIT = Kit.new(STEREO_KIT_ITEMS, 2, 16)


  # These tests use unrealistically short sounds and step sample lengths, to make tests easier to work with.
  def test_generate_track_sample_data
    [MONO_KIT, STEREO_KIT].each do |kit|
      s  = kit.get_sample_data("S")
      sl = kit.get_sample_data("S_LONG")
      ss = kit.get_sample_data("S_SHORT")
      so = kit.get_sample_data("S_OVERFLOW")
      t  = kit.get_sample_data("T")
      tl = kit.get_sample_data("T_LONG")
      ts = kit.get_sample_data("T_SHORT")
      z  = kit.get_sample_data("ZERO")

      # 1.) Tick sample length is equal to the length of the sound sample data.
      #     When this is the case, overflow should never occur.
      #     In practice, this will probably not occur often, but these tests act as a form of sanity check.
      helper_generate_track_sample_data(kit, "",       4, [])
      helper_generate_track_sample_data(kit, "X",      4, s)
      helper_generate_track_sample_data(kit, "X.",     4, s + t)
      helper_generate_track_sample_data(kit, ".X",     4, t + s)
      helper_generate_track_sample_data(kit, "...X.",  4, (t * 3) + s + t)
      helper_generate_track_sample_data(kit, ".X.XX.", 4, t + s + t + s + s + t)
      helper_generate_track_sample_data(kit, "...",    4, t * 3)

      # 2A.) Tick sample length is longer than the sound sample data. This is similar to (1), except that there should
      #     be some extra silence after the end of each trigger.
      #     Like (1), overflow should never occur.
      helper_generate_track_sample_data(kit, "",       6, [])
      helper_generate_track_sample_data(kit, "X",      6, sl)
      helper_generate_track_sample_data(kit, "X.",     6, sl + tl)
      helper_generate_track_sample_data(kit, ".X",     6, tl + sl)
      helper_generate_track_sample_data(kit, "...X.",  6, (tl * 3) + sl + tl)
      helper_generate_track_sample_data(kit, ".X.XX.", 6, tl + sl + tl + sl + sl + tl)
      helper_generate_track_sample_data(kit, "...",    6, (t + ts) * 3)

      # 2B.) Tick sample length is longer than the sound sample data, but not by an integer amount.
      #
      # Each step of 5.83 samples should end on the following boundaries:
      # Tick:               1,     2,     3,     4,     5,     6
      # Raw:        0.0, 5.83, 11.66, 17.49, 23.32, 29.15, 34.98
      # Quantized:    0,    5,    11,    17,    23,    29,    34
      helper_generate_track_sample_data(kit, "",       5.83, [])
      helper_generate_track_sample_data(kit, "X",      5.83, sl[0..4])
      helper_generate_track_sample_data(kit, "X.",     5.83, sl[0..4] + tl)
      helper_generate_track_sample_data(kit, ".X",     5.83, tl[0..4] + sl)
      helper_generate_track_sample_data(kit, "...X.",  5.83, (z * 17) + sl + tl)
      helper_generate_track_sample_data(kit, ".X.XX.", 5.83, tl[0..4] + sl + tl + sl + sl + tl[0..4])
      helper_generate_track_sample_data(kit, "...",    5.83, z * 17)

      # 3A.) Tick sample length is shorter than the sound sample data. Overflow will now occur!
      helper_generate_track_sample_data(kit, "",       2, [],              [])
      helper_generate_track_sample_data(kit, "X",      2, ss,              so)
      helper_generate_track_sample_data(kit, "X.",     2, s,               [])
      helper_generate_track_sample_data(kit, ".X",     2, ts + ss,         so)
      helper_generate_track_sample_data(kit, "...X.",  2, (ts * 3) + s,    [])
      helper_generate_track_sample_data(kit, ".X.XX.", 2, ts + s + ss + s, [])
      helper_generate_track_sample_data(kit, "...",    2, z * 6,         [])

      # 3B.) Tick sample length is shorter than sound sample data, such that a beat other than the final one
      #      would extend past the end of the rhythm if not cut off. Make sure that the sample data array doesn't
      #      inadvertently lengthen as a result.
      helper_generate_track_sample_data(kit, "XX", 1, [s[0], s[0]], s[1..3])

      # 3C.) Tick sample length is shorter than the sound sample data, but not by an integer amount.
      #
      # Each step of 1.83 samples should end on the following boundaries:
      # Tick:               1,    2,    3,    4,    5,     6
      # Raw:        0.0, 1.83, 3.66, 5.49, 7.32, 9.15, 10.98
      # Quantized:    0,    1,    3,    5,    7,    9,    10
      helper_generate_track_sample_data(kit, "",       1.83,                         [])
      helper_generate_track_sample_data(kit, "X",      1.83, s[0..0],                s[1..3])
      helper_generate_track_sample_data(kit, "X.",     1.83, s[0..2],                s[3..3])
      helper_generate_track_sample_data(kit, ".X",     1.83, z + s[0..1],            s[2..3])
      helper_generate_track_sample_data(kit, "...X.",  1.83, (z * 5) + s,            [])
      helper_generate_track_sample_data(kit, ".X.XX.", 1.83, z + s + ss + s[0..2],   s[3..3])
      helper_generate_track_sample_data(kit, "...",    1.83, z * 5,                  [])
    end
  end

  def helper_generate_track_sample_data(kit, rhythm, step_sample_length, expected_primary, expected_overflow = [])
    track = Track.new("foo", rhythm)
    audio_engine = MockAudioEngine.new(Song.new, kit)
    audio_engine.step_sample_length = step_sample_length
    actual = audio_engine.generate_track_sample_data(track, kit.get_sample_data("S"))

    assert_equal(Hash,                     actual.class)
    assert_equal(["overflow", "primary"],  actual.keys.map{|key| key.to_s}.sort)
    assert_equal(expected_primary,         actual[:primary])
    assert_equal(expected_overflow,        actual[:overflow])
  end

  def test_composite_pattern_tracks
    no_overflow_tracks = [
      Track.new("S", "X..."),
      Track.new("S_OVERFLOW", "X.X."),
      Track.new("S", "X.XX"),
    ]
    no_overflow_pattern = Pattern.new("no_overflow", no_overflow_tracks)

    overflow_tracks = [
      Track.new("S", "X..X"),
      Track.new("S_OVERFLOW", "XX.X"),
      Track.new("S_LONG", ".X.X"),
    ]
    overflow_pattern = Pattern.new("overflow", overflow_tracks)


    # Simple case, no overflow (stereo)
    audio_engine = MockAudioEngine.new(Song.new, MONO_KIT)
    audio_engine.step_sample_length = 4
    primary, overflow = audio_engine.composite_pattern_tracks(no_overflow_pattern)
    assert_equal([
                    -100 + 300 + -100,   200 + -400 + 200,   300 + 0 + 300,   -400 + 0 + -400,
                    0 + 0 + 0,           0 + 0 + 0,          0 + 0 + 0,       0 + 0 + 0,
                    0 + 300 + -100,      0 + -400 + 200,     0 + 0 + 300,     0 + 0 + -400,
                    0 + 0 + -100,        0 + 0 + 200,        0 + 0 + 300,     0 + 0 + -400,
                 ],
                 primary)
    assert_equal({"S" => [], "S_OVERFLOW" => [], "S2" => []}, overflow)


    # Simple case, no overflow (stereo)
    audio_engine = MockAudioEngine.new(Song.new, STEREO_KIT)
    audio_engine.step_sample_length = 4
    primary, overflow = audio_engine.composite_pattern_tracks(no_overflow_pattern)
    assert_equal([
                    [-100 + 300 + -100,      800 + -600 + 800],
                        [200 + -400 + 200,   -700 + 400 + -700],
                        [300 + 0 + 300,      -600 + 0 + -600],
                        [-400 + 0 + -400,    400 + 0 + 400],
                    [0 + 0 + 0,        0 + 0 + 0],
                        [0 + 0 + 0,    0 + 0 + 0],
                        [0 + 0 + 0,    0 + 0 + 0],
                        [0 + 0 + 0,    0 + 0 + 0],
                    [0 + 300 + -100,        0 + -600 + 800],
                        [0 + -400 + 200,    0 + 400 + -700],
                        [0 + 0 + 300,       0 + 0 + -600],
                        [0 + 0 + -400,      0 + 0 + 400],
                    [0 + 0 + -100,       0 + 0 + 800],
                        [0 + 0 + 200,    0 + 0 + -700],
                        [0 + 0 + 300,    0 + 0 + -600],
                        [0 + 0 + -400,   0 + 0 + 400],
                 ],
                 primary)
    assert_equal({"S" => [], "S_OVERFLOW" => [], "S2" => []}, overflow)


    # Some overflow (mono)
    audio_engine = MockAudioEngine.new(Song.new, MONO_KIT)
    audio_engine.step_sample_length = 3
    primary, overflow = audio_engine.composite_pattern_tracks(overflow_pattern)
    assert_equal([
                    -100 + 300 + 0,      200 + -400 + 0,     300 + 0 + 0,
                    -400 + 300 + -100,   0 + -400 + 200,     0 + 0 + 300,
                    0 + 0 + -400,        0 + 0 + 0,          0 + 0 + 0,
                    -100 + 300 + -100,   200 + -400 + 200,   300 + 0 + 300,
                 ],
                 primary)
    assert_equal({"S" => [-400], "S_OVERFLOW" => [], "S_LONG" => [-400, 0, 0]}, overflow)


    # Some overflow (stereo)
    audio_engine = MockAudioEngine.new(Song.new, STEREO_KIT)
    audio_engine.step_sample_length = 3
    primary, overflow = audio_engine.composite_pattern_tracks(overflow_pattern)
    assert_equal([
                    [-100 + 300 + 0,        800 + -600 + 0],
                        [200 + -400 + 0,    -700 + 400 + 0],
                        [300 + 0 + 0,       -600 + 0 + 0],
                    [-400 + 300 + -100,     400 + -600 + 800],
                        [0 + -400 + 200,    0 + 400 + -700],
                        [0 + 0 + 300,       0 + 0 + -600],
                    [0 + 0 + -400,     0 + 0 + 400],
                        [0 + 0 + 0,    0 + 0 + 0],
                        [0 + 0 + 0,    0 + 0 + 0],
                    [-100 + 300 + -100,       800 + -600 + 800],
                        [200 + -400 + 200,    -700 + 400 + -700],
                        [300 + 0 + 300,       -600 + 0 + -600],
                 ],
                 primary)
    assert_equal({"S" => [[-400, 400]], "S_OVERFLOW" => [], "S_LONG" => [[-400, 400], [0, 0], [0, 0]]}, overflow)
  end
end
