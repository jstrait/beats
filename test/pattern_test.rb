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

  def test_step_count
    test_patterns = generate_test_data()
    
    assert_equal(0,  test_patterns[:blank].step_count())
    assert_equal(32, test_patterns[:verse].step_count())
    assert_equal(4,  test_patterns[:staircase].step_count())
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
end
