$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class PatternTest < Test::Unit::TestCase
  SAMPLE_RATE = 44100
  SECONDS_IN_MINUTE = 60.0

  def generate_test_data
    test_patterns = {}
    
    pattern = Pattern.new :blank
    test_patterns[:blank] = pattern
    
    pattern = Pattern.new :verse
    pattern.track "bass.wav",      "X...X...X...XX..X...X...XX..X..."
    pattern.track "snare.wav",     "..X...X...X...X.X...X...X...X..."
    pattern.track "hh_closed.wav", "X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.X."
    pattern.track "hh_open.wav",   "X...............X..............X"
    test_patterns[:verse] = pattern
    
    pattern = Pattern.new :staircase
    pattern.track "bass.wav",      "X..."
    pattern.track "snare.wav",     "X.."
    pattern.track "hh_closed.wav", "X."
    test_patterns[:staircase] = pattern
    
    return test_patterns
  end
  
  def test_initialize
    test_patterns = generate_test_data()
    
    pattern = test_patterns[:blank]
    assert_equal(pattern.name, :blank)
    assert_equal(pattern.tracks.length, 0)

    pattern = test_patterns[:verse]
    assert_equal(pattern.name, :verse)
    assert_equal(pattern.tracks.length, 4)

    pattern = test_patterns[:staircase]
    assert_equal(pattern.name, :staircase)
    assert_equal(pattern.tracks.length, 3)
  end

=begin
  def test_sample_length
    test_patterns = generate_test_data()
    
    tick_sample_length = 13860.0
    assert_equal(test_patterns[:blank].sample_length(tick_sample_length), 0)
    assert_equal(test_patterns[:verse].sample_length(tick_sample_length), tick_sample_length * 32)
    assert_equal(test_patterns[:staircase].sample_length(tick_sample_length), tick_sample_length * 4)

    tick_sample_length = 6681.81818181818
    assert_equal(test_patterns[:blank].sample_length(tick_sample_length), 0)
    assert_equal(test_patterns[:verse].sample_length(tick_sample_length), (tick_sample_length * 32).floor)
    assert_equal(test_patterns[:staircase].sample_length(tick_sample_length), (tick_sample_length * 4).floor)

    tick_sample_length = 16134.1463414634
    assert_equal(test_patterns[:blank].sample_length(tick_sample_length), 0)
    assert_equal(test_patterns[:verse].sample_length(tick_sample_length), (tick_sample_length * 32).floor)
    assert_equal(test_patterns[:staircase].sample_length(tick_sample_length), (tick_sample_length * 4).floor)
  end
=end

  def test_tick_count
    test_patterns = generate_test_data()
    
    assert_equal(0,  test_patterns[:blank].tick_count())
    assert_equal(32, test_patterns[:verse].tick_count())
    assert_equal(4,  test_patterns[:staircase].tick_count())
  end

  def test_same_tracks_as?
    left_pattern = Pattern.new("left")
    left_pattern.track("bass",      "X...X...")
    left_pattern.track("snare",     "..X...X.")
    left_pattern.track("hh_closed", "X.X.X.X.")
    
    right_pattern = Pattern.new("right")
    right_pattern.track("bass",      "X...X...")
    right_pattern.track("snare",     "..X...X.")
    right_pattern.track("hh_closed", "X.X.X.X.")
    assert(left_pattern.same_tracks_as?(right_pattern))
    assert(right_pattern.same_tracks_as?(left_pattern))
    
    # Now switch up the order. Left and right should still be equal.
    right_pattern = Pattern.new("right")
    right_pattern.track("snare",     "..X...X.")
    right_pattern.track("hh_closed", "X.X.X.X.")
    right_pattern.track("bass",      "X...X...")
    assert(left_pattern.same_tracks_as?(right_pattern))
    assert(right_pattern.same_tracks_as?(left_pattern))
    
    # Now compare the pattern with same rhythms but different track names. Should not be equal.
    different_names_pattern = Pattern.new("different_names")
    different_names_pattern.track("tom",     "X...X...")
    different_names_pattern.track("cymbal",  "..X...X.")
    different_names_pattern.track("hh_open", "X.X.X.X.")
    assert_equal(false, left_pattern.same_tracks_as?(different_names_pattern))
    assert_equal(false, different_names_pattern.same_tracks_as?(left_pattern))
    
    # Now compare the pattern with same track names but different rhythms. Should not be equal.
    different_beats_pattern = Pattern.new("different_beats")
    different_beats_pattern.track("bass",      "X...X...")
    different_beats_pattern.track("snare",     "..X...X.")
    different_beats_pattern.track("hh_closed", "X.XXX.X.")
    assert_equal(false, left_pattern.same_tracks_as?(different_beats_pattern))
    assert_equal(false, different_beats_pattern.same_tracks_as?(left_pattern))
    
    # Now compare a pattern with the same tracks, but with one extra one as well. Should not be equal.
    something_extra = Pattern.new("something_extra")
    something_extra.track("bass",      "X...X...")
    something_extra.track("snare",     "..X...X.")
    something_extra.track("hh_closed", "X.X.X.X.")
    something_extra.track("extra",     "X..X..X.")
    assert_equal(false, left_pattern.same_tracks_as?(something_extra))
    assert_equal(false, something_extra.same_tracks_as?(left_pattern))
  end

# TODO: Replace these with suitable AudioEngine.pattern_sample_data() tests.
=begin
  def test_sample_data
    tick_sample_lengths = [
      13860.0,
      (SAMPLE_RATE * SECONDS_IN_MINUTE) / 200 / 4,   # 3307.50
      (SAMPLE_RATE * SECONDS_IN_MINUTE) / 99 / 4     # 6681.81818181818
    ]

    tick_sample_lengths.each{|tick_sample_length| helper_test_sample_data(tick_sample_length) }
  end

  def helper_test_sample_data(tick_sample_length)

    test_patterns = generate_test_data()
    
    # Combined
    test_patterns.each{|pattern_name, test_pattern|
      sample_data = test_pattern.sample_data(tick_sample_length, 1, test_pattern.tracks.length, {})
      assert_equal(sample_data.class, Hash)
      assert_equal(sample_data.keys.map{|key| key.to_s}.sort, ["overflow", "primary"])
      
      primary_sample_length = test_pattern.sample_length(tick_sample_length)
      full_sample_length = test_pattern.sample_length_with_overflow(tick_sample_length)
      assert_equal(sample_data[:primary].length, primary_sample_length)
      assert_equal(sample_data[:overflow].length, test_pattern.tracks.length)
      sample_data[:overflow].values.each do |track_overflow|
        assert_equal(track_overflow.class, Array)
      end
      # To do: add test to verify that longest overflow == full_sample_length - primary_sample_length
    }
  end
  
  def find_longest_overflow(overflow)
    longest_overflow = overflow.keys.first
    overflow.keys.each do |name|
      if(overflow[name].length > overflow[longest_overflow].length)
        longest_overflow = name
      end
    end
    
    return longest_overflow
  end
  
  # Test scenario where incoming overflow for a track not in the pattern is longer than the pattern itself.
  # In this situation, the the overflow should continue into the outgoing overflow so it is handled in the
  # next pattern.
  def test_sample_data_incoming_overflow_longer_than_pattern_length
    # bass.wav sample length:   6179
    # snare.wav sample length: 14700
    kit = Kit.new("test/sounds", {"bass"  => "bass_mono_8.wav",
                                  "snare" => "snare_mono_8.wav"})
    bass_sample_data = kit.get_sample_data("bass")
    snare_sample_data = kit.get_sample_data("snare")
    tick_sample_length = bass_sample_data.length.to_f
    
    # Construct expected
    expected_primary_sample_data = Array.new(bass_sample_data.length)
    bass_sample_data.length.times do |i|
      expected_primary_sample_data[i] = ((bass_sample_data[i] + snare_sample_data[i]) / 2).round
    end
    expected_overflow_sample_data = snare_sample_data[bass_sample_data.length...snare_sample_data.length]
    
    # Get actual
    pattern = Pattern.new :verse
    pattern.track "bass", bass_sample_data, "X"
    actual_sample_data = pattern.sample_data(tick_sample_length, 1, 2, {"snare" => snare_sample_data})
    
    assert_equal(Hash, actual_sample_data.class)
    assert_equal(["overflow", "primary"], actual_sample_data.keys.map{|key| key.to_s}.sort)
    assert_equal(expected_primary_sample_data, actual_sample_data[:primary])
    assert_equal(["bass", "snare"], actual_sample_data[:overflow].keys.sort)
    assert_equal([], actual_sample_data[:overflow]["bass"])
    assert_equal(expected_overflow_sample_data, actual_sample_data[:overflow]["snare"])
  end
=end
end
