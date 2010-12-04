$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

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

  S  = [-100, 200, 300, -400]    # Sample data for a sound. Unrealistically short for clarity.
  SL = S + [0, 0]                # Sound when step sample length is longer than full sound length
  SS = [-100, 200]               # Sound when step sample length is less than full sound length
  SO = [300, -400]               # Sound overflow when step sample length is less than full sound length
  TE = [0, 0, 0, 0]              # A step with no sound, with length equal to S
  TL = [0, 0, 0, 0, 0, 0]        # A step with no sound, longer than full sound length
  TS = [0, 0]                    # A step with no sound, shorter than full sound length

  # These tests use unrealistically short sounds and step sample lengths, to make tests a lot easier to work with.
  def test_generate_track_sample_data
    
    # 1.) Tick sample length is equal to the length of the sound sample data.
    #     When this is the case, overflow should never occur.
    #     In practice, this will probably not occur often, but these tests act as a form of sanity check.
    helper_generate_track_sample_data "",       4, []
    helper_generate_track_sample_data "X",      4, S
    helper_generate_track_sample_data "X.",     4, S + TE
    helper_generate_track_sample_data ".X",     4, TE + S
    helper_generate_track_sample_data "...X.",  4, (TE * 3) + S + TE
    helper_generate_track_sample_data ".X.XX.", 4, TE + S + TE + S + S + TE
  
    # 2A.) Tick sample length is longer than the sound sample data. This is similar to (1), except that there should
    #     be some extra silence after the end of each trigger.
    #     Like (1), overflow should never occur.
    helper_generate_track_sample_data "",       6, []
    helper_generate_track_sample_data "X",      6, SL
    helper_generate_track_sample_data "X.",     6, SL + TL
    helper_generate_track_sample_data ".X",     6, TL + SL
    helper_generate_track_sample_data "...X.",  6, (TL * 3) + SL + TL
    helper_generate_track_sample_data ".X.XX.", 6, TL + SL + TL + SL + SL + TL

    # 2B.) Tick sample length is longer than the sound sample data, but not by an integer amount.
    #
    # Each step of 5.83 samples should end on the following boundaries:
    # Tick:               1,     2,     3,     4,     5,     6
    # Raw:        0.0, 5.83, 11.66, 17.49, 23.32, 29.15, 34.98
    # Quantized:    0,    5,    11,    17,    23,    29,    34
    helper_generate_track_sample_data "",       5.83, []
    helper_generate_track_sample_data "X",      5.83, SL[0..4]
    helper_generate_track_sample_data "X.",     5.83, SL[0..4] + TL
    helper_generate_track_sample_data ".X",     5.83, TL[0..4] + SL
    helper_generate_track_sample_data "...X.",  5.83, ([0] * 17) + SL + TL
    helper_generate_track_sample_data ".X.XX.", 5.83, TL[0..4] + SL + TL + SL + SL + TL[0..4]

    # 3A.) Tick sample length is shorter than the sound sample data. Overflow will now occur!
    helper_generate_track_sample_data "",       2, [],              []
    helper_generate_track_sample_data "X",      2, SS,              SO
    helper_generate_track_sample_data "X.",     2, S,               []
    helper_generate_track_sample_data ".X",     2, TS + SS,         SO
    helper_generate_track_sample_data "...X.",  2, (TS * 3) + S,    []
    helper_generate_track_sample_data ".X.XX.", 2, TS + S + SS + S, []

    # 3B.) Tick sample length is shorter than sound sample data, such that a beat other than the final one
    #      would extend past the end of the rhythm if not cut off. Make sure that the sample data array doesn't
    #      inadvertently lengthen as a result.
    helper_generate_track_sample_data "XX", 1, [-100, -100], [200, 300, -400]

    # 3C.) Tick sample length is shorter than the sound sample data, but not by an integer amount.
    # 
    # Each step of 1.83 samples should end on the following boundaries:
    # Tick:               1,    2,    3,    4,    5,     6
    # Raw:        0.0, 1.83, 3.66, 5.49, 7.32, 9.15, 10.98
    # Quantized:    0,    1,    3,    5,    7,    9,    10
    helper_generate_track_sample_data "",       1.83,                         []
    helper_generate_track_sample_data "X",      1.83, S[0..0],                S[1..3]
    helper_generate_track_sample_data "X.",     1.83, S[0..2],                S[3..3]
    helper_generate_track_sample_data ".X",     1.83, [0] + S[0..1],          S[2..3]
    helper_generate_track_sample_data "...X.",  1.83, ([0] * 5) + S,          []
    helper_generate_track_sample_data ".X.XX.", 1.83, [0] + S + SS + S[0..2], S[3..3]
  end

  def helper_generate_track_sample_data(rhythm, step_sample_length, expected_primary, expected_overflow = [])
    track = Track.new("foo", rhythm)
    kit = Kit.new(".", {})
    engine = MockAudioEngine.new(Song.new(), kit)
    engine.step_sample_length = step_sample_length
    actual = engine.generate_track_sample_data(track, S)
    
    assert_equal(Hash,                     actual.class)
    assert_equal(["overflow", "primary"],  actual.keys.map{|key| key.to_s}.sort)
    assert_equal(expected_primary,         actual[:primary])
    assert_equal(expected_overflow,        actual[:overflow])
  end
end

class MockAudioEngine < AudioEngine
  # Make private method public
  def generate_track_sample_data(track, sound)
    super
  end

  attr_accessor :step_sample_length
end
