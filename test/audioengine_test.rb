$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

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

# Allow setting sample data directly, instead of loading from a file
class MockKit < Kit
  attr_accessor :sound_bank, :num_channels
end

class AudioEngineTest < Test::Unit::TestCase
  FIXTURES = [:repeats_not_specified,
              :pattern_with_overflow,
              :example_no_kit,
              :example_with_kit]

  def load_fixtures
    test_engines = {}
    base_path = File.dirname(__FILE__) + "/.."
    song_parser = SongParser.new()
    
    test_engines[:blank] = AudioEngine.new(Song.new(), Kit.new(base_path, {}))

    FIXTURES.each do |fixture_name|
      song, kit = song_parser.parse(base_path, File.read("test/fixtures/valid/#{fixture_name}.txt"))
      test_engines[fixture_name] = AudioEngine.new(song, kit)
    end
     
    return test_engines 
  end

  def test_initialize
    test_engines = load_fixtures()

    assert_equal(5512.5, test_engines[:blank].step_sample_length)
    assert_equal(6615.0, test_engines[:repeats_not_specified].step_sample_length)
  end


  # S    Sample data for a sound. Unrealistically short for clarity.
  # SL   Sound when step sample length is longer than full sound length
  # SS   Sound when step sample length is less than full sound length
  # SO   Sound overflow when step sample length is less than full sound length
  # TE   A step with no sound, with length equal to S
  # TL   A step with no sound, longer than full sound length
  # TS   A step with no sound, shorter than full sound length
  # Z    A zero sample

  MONO_KIT = MockKit.new(".", {})
  MONO_KIT.sound_bank = { "S"  => [-100, 200, 300, -400],
                          "SL" => [-100, 200, 300, -400, 0, 0],
                          "SS" => [-100, 200],
                          "SO" => [300, -400],
                          "TE" => [0, 0, 0, 0],
                          "TL" => [0, 0, 0, 0, 0, 0],
                          "TS" => [0, 0],
                          "Z"  => [0] }
  MONO_KIT.num_channels = 1

  STEREO_KIT = MockKit.new(".", {})
  STEREO_KIT.sound_bank = { "S"  => [[-100, 800], [200, -700], [300, -600], [-400, 400]],
                            "SL" => [[-100, 800], [200, -700], [300, -600], [-400, 400], [0, 0], [0, 0]],
                            "SS" => [[-100, 800], [200, -700]],
                            "SO" => [[300, -600], [-400, 400]],
                            "TE" => [[0, 0], [0, 0], [0, 0], [0, 0]],
                            "TL" => [[0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0]],
                            "TS" => [[0, 0], [0, 0]],
                            "Z"  => [[0, 0]] }
  STEREO_KIT.num_channels = 2


  # These tests use unrealistically short sounds and step sample lengths, to make tests easier to work with.
  def test_generate_track_sample_data
    [MONO_KIT, STEREO_KIT].each do |kit|
      s  = kit.get_sample_data("S")
      sl = kit.get_sample_data("SL")
      ss = kit.get_sample_data("SS")
      so = kit.get_sample_data("SO")
      te = kit.get_sample_data("TE")
      tl = kit.get_sample_data("TL")
      ts = kit.get_sample_data("TS")
      z  = kit.get_sample_data("Z")

      # 1.) Tick sample length is equal to the length of the sound sample data.
      #     When this is the case, overflow should never occur.
      #     In practice, this will probably not occur often, but these tests act as a form of sanity check.
      helper_generate_track_sample_data kit, "",       4, []
      helper_generate_track_sample_data kit, "X",      4, s
      helper_generate_track_sample_data kit, "X.",     4, s + te
      helper_generate_track_sample_data kit, ".X",     4, te + s
      helper_generate_track_sample_data kit, "...X.",  4, (te * 3) + s + te
      helper_generate_track_sample_data kit, ".X.XX.", 4, te + s + te + s + s + te
      helper_generate_track_sample_data kit, "...",    4, te * 3

      # 2A.) Tick sample length is longer than the sound sample data. This is similar to (1), except that there should
      #     be some extra silence after the end of each trigger.
      #     Like (1), overflow should never occur.
      helper_generate_track_sample_data kit, "",       6, []
      helper_generate_track_sample_data kit, "X",      6, sl
      helper_generate_track_sample_data kit, "X.",     6, sl + tl
      helper_generate_track_sample_data kit, ".X",     6, tl + sl
      helper_generate_track_sample_data kit, "...X.",  6, (tl * 3) + sl + tl
      helper_generate_track_sample_data kit, ".X.XX.", 6, tl + sl + tl + sl + sl + tl
      helper_generate_track_sample_data kit, "...",    6, (te + ts) * 3

      # 2B.) Tick sample length is longer than the sound sample data, but not by an integer amount.
      #
      # Each step of 5.83 samples should end on the following boundaries:
      # Tick:               1,     2,     3,     4,     5,     6
      # Raw:        0.0, 5.83, 11.66, 17.49, 23.32, 29.15, 34.98
      # Quantized:    0,    5,    11,    17,    23,    29,    34
      helper_generate_track_sample_data kit, "",       5.83, []
      helper_generate_track_sample_data kit, "X",      5.83, sl[0..4]
      helper_generate_track_sample_data kit, "X.",     5.83, sl[0..4] + tl
      helper_generate_track_sample_data kit, ".X",     5.83, tl[0..4] + sl
      helper_generate_track_sample_data kit, "...X.",  5.83, (z * 17) + sl + tl
      helper_generate_track_sample_data kit, ".X.XX.", 5.83, tl[0..4] + sl + tl + sl + sl + tl[0..4]
      helper_generate_track_sample_data kit, "...",    5.83, z * 17

      # 3A.) Tick sample length is shorter than the sound sample data. Overflow will now occur!
      helper_generate_track_sample_data kit, "",       2, [],              []
      helper_generate_track_sample_data kit, "X",      2, ss,              so
      helper_generate_track_sample_data kit, "X.",     2, s,               []
      helper_generate_track_sample_data kit, ".X",     2, ts + ss,         so
      helper_generate_track_sample_data kit, "...X.",  2, (ts * 3) + s,    []
      helper_generate_track_sample_data kit, ".X.XX.", 2, ts + s + ss + s, []
      helper_generate_track_sample_data kit, "...",    2, z * 6,         []

      # 3B.) Tick sample length is shorter than sound sample data, such that a beat other than the final one
      #      would extend past the end of the rhythm if not cut off. Make sure that the sample data array doesn't
      #      inadvertently lengthen as a result.
      #helper_generate_track_sample_data kit, "XX", 1, [-100, -100], [200, 300, -400]

      # 3C.) Tick sample length is shorter than the sound sample data, but not by an integer amount.
      # 
      # Each step of 1.83 samples should end on the following boundaries:
      # Tick:               1,    2,    3,    4,    5,     6
      # Raw:        0.0, 1.83, 3.66, 5.49, 7.32, 9.15, 10.98
      # Quantized:    0,    1,    3,    5,    7,    9,    10
      helper_generate_track_sample_data kit, "",       1.83,                         []
      helper_generate_track_sample_data kit, "X",      1.83, s[0..0],                s[1..3]
      helper_generate_track_sample_data kit, "X.",     1.83, s[0..2],                s[3..3]
      helper_generate_track_sample_data kit, ".X",     1.83, z + s[0..1],            s[2..3]
      helper_generate_track_sample_data kit, "...X.",  1.83, (z * 5) + s,            []
      helper_generate_track_sample_data kit, ".X.XX.", 1.83, z + s + ss + s[0..2],   s[3..3]
      helper_generate_track_sample_data kit, "...",    1.83, z * 5,                  []
    end
  end

  def helper_generate_track_sample_data(kit, rhythm, step_sample_length, expected_primary, expected_overflow = [])
    track = Track.new("foo", rhythm)
    engine = MockAudioEngine.new(Song.new(), kit)
    engine.step_sample_length = step_sample_length
    actual = engine.generate_track_sample_data(track, kit.get_sample_data("S"))
    
    assert_equal(Hash,                     actual.class)
    assert_equal(["overflow", "primary"],  actual.keys.map{|key| key.to_s}.sort)
    assert_equal(expected_primary,         actual[:primary])
    assert_equal(expected_overflow,        actual[:overflow])
  end

  def test_composite_pattern_tracks
    no_overflow_pattern = Pattern.new("no_overflow")
    no_overflow_pattern.track "S",  "X..."
    no_overflow_pattern.track "SO", "X.X."
    no_overflow_pattern.track "S",  "X.XX"

    overflow_pattern = Pattern.new("overflow")
    overflow_pattern.track "S",  "X..X"
    overflow_pattern.track "SO", "XX.X"
    overflow_pattern.track "SL", ".X.X"


    # Simple case, no overflow (stereo)
    engine = MockAudioEngine.new(Song.new(), MONO_KIT)
    engine.step_sample_length = 4
    primary, overflow = engine.composite_pattern_tracks(no_overflow_pattern)
    assert_equal([
                    -100 + 300 + -100,   200 + -400 + 200,   300 + 0 + 300,   -400 + 0 + -400,
                    0 + 0 + 0,           0 + 0 + 0,          0 + 0 + 0,       0 + 0 + 0,
                    0 + 300 + -100,      0 + -400 + 200,     0 + 0 + 300,     0 + 0 + -400,
                    0 + 0 + -100,        0 + 0 + 200,        0 + 0 + 300,     0 + 0 + -400,
                 ],
                 primary)
    assert_equal({"S" => [], "SO" => [], "S2" => []}, overflow)


    # Simple case, no overflow (stereo)
    engine = MockAudioEngine.new(Song.new(), STEREO_KIT)
    engine.step_sample_length = 4
    primary, overflow = engine.composite_pattern_tracks(no_overflow_pattern)
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
    assert_equal({"S" => [], "SO" => [], "S2" => []}, overflow)


    # Some overflow (mono)
    engine = MockAudioEngine.new(Song.new(), MONO_KIT)
    engine.step_sample_length = 3
    primary, overflow = engine.composite_pattern_tracks(overflow_pattern)
    assert_equal([
                    -100 + 300 + 0,      200 + -400 + 0,     300 + 0 + 0,
                    -400 + 300 + -100,   0 + -400 + 200,     0 + 0 + 300,
                    0 + 0 + -400,        0 + 0 + 0,          0 + 0 + 0,
                    -100 + 300 + -100,   200 + -400 + 200,   300 + 0 + 300,
                 ],
                 primary)
    assert_equal({"S" => [-400], "SO" => [], "SL" => [-400, 0, 0]}, overflow)


    # Some overflow (stereo)
    # TODO
  end
end
