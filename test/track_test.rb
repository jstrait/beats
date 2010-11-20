$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class MockTrack < Track
  #attr_reader :beats
end

class TrackTest < Test::Unit::TestCase
  def generate_test_data
    test_tracks = {}
    
    test_tracks[:blank] = MockTrack.new("bass", "")
    test_tracks[:solo] = MockTrack.new("bass", "X")
    test_tracks[:with_overflow] = MockTrack.new("bass", "...X")
    test_tracks[:with_barlines] = MockTrack.new("bass", "|X.X.|X.X.|")
    test_tracks[:placeholder] = MockTrack.new("bass", "....")
    test_tracks[:complicated] = MockTrack.new("bass", "..X...X...X...X.X...X...X...X...")
    
    return test_tracks
  end
  
  def test_initialize
    test_tracks = generate_test_data()
    
    assert_equal([0], test_tracks[:blank].beats)
    assert_equal("bass", test_tracks[:blank].name)
    assert_equal("", test_tracks[:blank].rhythm)
    
    assert_equal([0, 1], test_tracks[:solo].beats)
    assert_equal("bass", test_tracks[:solo].name)
    assert_equal("X", test_tracks[:solo].rhythm)
    
    assert_equal([3, 1], test_tracks[:with_overflow].beats)
    assert_equal("...X", test_tracks[:with_overflow].rhythm)
    
    assert_equal([0, 2, 2, 2, 2], test_tracks[:with_barlines].beats)
    # Bar lines should be removed from rhythm:
    assert_equal("X.X.X.X.", test_tracks[:with_barlines].rhythm)
    
    assert_equal([4], test_tracks[:placeholder].beats)
    assert_equal("....", test_tracks[:placeholder].rhythm)
    
    assert_equal([2, 4, 4, 4, 2, 4, 4, 4, 4], test_tracks[:complicated].beats)
    assert_equal("..X...X...X...X.X...X...X...X...", test_tracks[:complicated].rhythm)
  end
  
  def test_tick_count
    test_tracks = generate_test_data()
    
    assert_equal(0,  test_tracks[:blank].tick_count())
    assert_equal(1,  test_tracks[:solo].tick_count())
    assert_equal(4,  test_tracks[:with_overflow].tick_count())
    assert_equal(8,  test_tracks[:with_barlines].tick_count())
    assert_equal(4,  test_tracks[:placeholder].tick_count())
    assert_equal(32, test_tracks[:complicated].tick_count())
  end

  def test_intro_sample_length
    # TODO: Add tests for when tick_sample_length has a non-zero remainder
    
    test_tracks = generate_test_data()

    tick_sample_length = 6179.0   # sounds/bass.wav
    assert_equal(0,     test_tracks[:blank].intro_sample_length(tick_sample_length))
    assert_equal(0,     test_tracks[:solo].intro_sample_length(tick_sample_length))
    assert_equal(18537, test_tracks[:with_overflow].intro_sample_length(tick_sample_length))
    assert_equal(0,     test_tracks[:with_barlines].intro_sample_length(tick_sample_length))
    assert_equal(24716, test_tracks[:placeholder].intro_sample_length(tick_sample_length))
    assert_equal(12358, test_tracks[:complicated].intro_sample_length(tick_sample_length))
  end
end
