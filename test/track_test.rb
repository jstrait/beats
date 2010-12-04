$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class TrackTest < Test::Unit::TestCase
  def generate_test_data
    test_tracks = {}
    
    test_tracks[:blank] = Track.new("bass", "")
    test_tracks[:solo] = Track.new("bass", "X")
    test_tracks[:with_overflow] = Track.new("bass", "...X")
    test_tracks[:with_barlines] = Track.new("bass", "|X.X.|X.X.|")
    test_tracks[:placeholder] = Track.new("bass", "....")
    test_tracks[:complicated] = Track.new("bass", "..X...X...X...X.X...X...X...X...")
    
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
  
  def test_step_count
    test_tracks = generate_test_data()
    
    assert_equal(0,  test_tracks[:blank].step_count())
    assert_equal(1,  test_tracks[:solo].step_count())
    assert_equal(4,  test_tracks[:with_overflow].step_count())
    assert_equal(8,  test_tracks[:with_barlines].step_count())
    assert_equal(4,  test_tracks[:placeholder].step_count())
    assert_equal(32, test_tracks[:complicated].step_count())
  end
end
