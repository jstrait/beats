$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class MockTrack < Track
  attr_reader :beats
end

class TrackTest < Test::Unit::TestCase
  SECONDS_IN_MINUTE = 60.0
  SOUND_FILE_PATH = "test/sounds/bass_mono_8.wav"
  W = WaveFile.open(SOUND_FILE_PATH)
  
  def generate_test_data
    test_tracks = {}
    
    test_tracks[:blank] = MockTrack.new("bass", W.sample_data, "")
    test_tracks[:solo] = MockTrack.new("bass", W.sample_data, "X")
    test_tracks[:with_overflow] = MockTrack.new("bass", W.sample_data, "...X")
    test_tracks[:with_barlines] = MockTrack.new("bass", W.sample_data, "|X.X.|X.X.|")
    test_tracks[:placeholder] = MockTrack.new("bass", W.sample_data, "....")
    test_tracks[:complicated] = MockTrack.new("bass", W.sample_data, "..X...X...X...X.X...X...X...X...")
    
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

    tick_sample_length = W.sample_data.length        # 6179.0
    assert_equal(0,     test_tracks[:blank].intro_sample_length(tick_sample_length))
    assert_equal(0,     test_tracks[:solo].intro_sample_length(tick_sample_length))
    assert_equal(18537, test_tracks[:with_overflow].intro_sample_length(tick_sample_length))
    assert_equal(0,     test_tracks[:with_barlines].intro_sample_length(tick_sample_length))
    assert_equal(24716, test_tracks[:placeholder].intro_sample_length(tick_sample_length))
    assert_equal(12358, test_tracks[:complicated].intro_sample_length(tick_sample_length))
  end

  def test_sample_length
    tick_sample_lengths = [
      W.sample_data.length,                           # 13860.0 - FIXME, not correct
      (W.sample_rate * SECONDS_IN_MINUTE) / 99 / 4,   # 6681.81818181818 - FIXME, not correct
      (W.sample_rate * SECONDS_IN_MINUTE) / 41 / 4    # 16134.1463414634 - FIXME, not correct
    ]

    tick_sample_lengths.each {|tick_sample_length| helper_test_sample_length(tick_sample_length) }
  end

  def helper_test_sample_length(tick_sample_length)
    test_tracks = generate_test_data()
    
    assert_equal(0, test_tracks[:blank].sample_length(tick_sample_length))
    assert_equal(test_tracks[:blank].sample_data(tick_sample_length)[:primary].length, test_tracks[:blank].sample_length(tick_sample_length))
    
    assert_equal(tick_sample_length.floor, test_tracks[:solo].sample_length(tick_sample_length))
    assert_equal(test_tracks[:solo].sample_data(tick_sample_length)[:primary].length, test_tracks[:solo].sample_length(tick_sample_length))
    
    assert_equal((tick_sample_length * 4).floor, test_tracks[:with_overflow].sample_length(tick_sample_length))
    assert_equal(test_tracks[:with_overflow].sample_data(tick_sample_length)[:primary].length, test_tracks[:with_overflow].sample_length(tick_sample_length))
    
    assert_equal((tick_sample_length * 8).floor, test_tracks[:with_barlines].sample_length(tick_sample_length))
    assert_equal(test_tracks[:with_barlines].sample_data(tick_sample_length)[:primary].length, test_tracks[:with_barlines].sample_length(tick_sample_length))
    
    assert_equal((tick_sample_length * 4).floor, test_tracks[:placeholder].sample_length(tick_sample_length))
    assert_equal(test_tracks[:placeholder].sample_data(tick_sample_length)[:primary].length, test_tracks[:placeholder].sample_length(tick_sample_length))
    
    assert_equal((tick_sample_length * 32).floor, test_tracks[:complicated].sample_length(tick_sample_length))
    assert_equal(test_tracks[:complicated].sample_data(tick_sample_length)[:primary].length, test_tracks[:complicated].sample_length(tick_sample_length))
  end
  
  def test_sample_length_with_overflow
    tick_sample_lengths = [
      W.sample_data.length,                           # 13860.0 - FIXME, not correct
      (W.sample_rate * SECONDS_IN_MINUTE) / 99 / 4,   # 6681.81818181818 - FIXME, not correct
      (W.sample_rate * SECONDS_IN_MINUTE) / 41 / 4    # 16134.1463414634 - FIXME, not correct
    ]

    tick_sample_lengths.each { |tick_sample_length| helper_test_sample_length_with_overflow(tick_sample_length) }
  end
  
  def helper_test_sample_length_with_overflow(tick_sample_length)
    wave_sample_length = W.sample_data.length
    test_tracks = generate_test_data()
    
    sample_data = test_tracks[:blank].sample_data(tick_sample_length)
    assert_equal(0, test_tracks[:blank].sample_length_with_overflow(tick_sample_length))
    assert_equal(sample_data[:primary].length + sample_data[:overflow].length, test_tracks[:blank].sample_length_with_overflow(tick_sample_length))
    
    sample_data = test_tracks[:solo].sample_data(tick_sample_length)
    if(wave_sample_length > tick_sample_length * test_tracks[:solo].beats.last)
      assert_equal(wave_sample_length, test_tracks[:solo].sample_length_with_overflow(tick_sample_length))
    else
      assert_equal(tick_sample_length.floor, test_tracks[:solo].sample_length_with_overflow(tick_sample_length))
      assert_equal(sample_data[:primary].length + sample_data[:overflow].length, test_tracks[:solo].sample_length_with_overflow(tick_sample_length))
    end
    
    sample_data = test_tracks[:with_overflow].sample_data(tick_sample_length)
    if(wave_sample_length > tick_sample_length * test_tracks[:with_overflow].beats.last)
      assert_equal((tick_sample_length * 4).floor + (wave_sample_length - tick_sample_length.floor), test_tracks[:with_overflow].sample_length_with_overflow(tick_sample_length))
      assert_equal(sample_data[:primary].length + sample_data[:overflow].length, test_tracks[:with_overflow].sample_length_with_overflow(tick_sample_length))
    else
      assert_equal((tick_sample_length * 4).floor, test_tracks[:with_overflow].sample_length_with_overflow(tick_sample_length))
      assert_equal(sample_data[:primary].length + sample_data[:overflow].length, test_tracks[:with_overflow].sample_length_with_overflow(tick_sample_length))
    end
    
    sample_data = test_tracks[:with_barlines].sample_data(tick_sample_length)
    if(wave_sample_length > tick_sample_length * test_tracks[:with_barlines].beats.last)
      assert_equal((tick_sample_length * 8).floor + (wave_sample_length - (tick_sample_length * 2).floor), test_tracks[:with_barlines].sample_length_with_overflow(tick_sample_length))
      assert_equal(sample_data[:primary].length + sample_data[:overflow].length, test_tracks[:with_barlines].sample_length_with_overflow(tick_sample_length))
    else
      assert_equal((tick_sample_length * 8).floor, test_tracks[:with_barlines].sample_length_with_overflow(tick_sample_length))
      assert_equal(sample_data[:primary].length + sample_data[:overflow].length, test_tracks[:with_barlines].sample_length_with_overflow(tick_sample_length))
    end
    
    sample_data = test_tracks[:placeholder].sample_data(tick_sample_length)
    assert_equal((tick_sample_length * 4).floor, test_tracks[:placeholder].sample_length_with_overflow(tick_sample_length))
    assert_equal(sample_data[:primary].length + sample_data[:overflow].length, test_tracks[:placeholder].sample_length_with_overflow(tick_sample_length))
    
    sample_data = test_tracks[:complicated].sample_data(tick_sample_length)
    assert_equal((tick_sample_length * 32).floor, test_tracks[:complicated].sample_length_with_overflow(tick_sample_length))
    assert_equal(sample_data[:primary].length + sample_data[:overflow].length, test_tracks[:complicated].sample_length_with_overflow(tick_sample_length))
  end
    
  def test_sample_data
    sample_data = W.sample_data
    
    tick_sample_length = W.sample_data.length   # 6179.0
    test_tracks = generate_test_data()
    assert_equal({:primary => [], :overflow => []}, test_tracks[:blank].sample_data(tick_sample_length))
    helper_test_sample_data(test_tracks[:solo], tick_sample_length, sample_data[0...tick_sample_length], [])
    helper_test_sample_data(test_tracks[:with_overflow], tick_sample_length, zeroes(tick_sample_length * 3) + sample_data, [])
    helper_test_sample_data(test_tracks[:with_barlines], tick_sample_length, (sample_data + zeroes(tick_sample_length)) * 4, [])
    helper_test_sample_data(test_tracks[:placeholder], tick_sample_length, zeroes(tick_sample_length * 4), [])
    # Track :complicated is complicated. Will add test later...


    tick_sample_length = (W.sample_rate * 60.0) / 220 / 4   # 3006.818181818181818
    test_tracks = generate_test_data()
    assert_equal({:primary => [], :overflow => []}, test_tracks[:blank].sample_data(tick_sample_length))
    helper_test_sample_data(test_tracks[:solo], tick_sample_length, sample_data[0...tick_sample_length.floor], sample_data[tick_sample_length.floor...sample_data.length])
    #helper_test_sample_data(test_tracks[:with_overflow], tick_sample_length, zeroes(tick_sample_length * 3) + sample_data[0..tick_sample_length.floor], sample_data[(tick_sample_length.floor)...sample_data.length])
    #helper_test_sample_data(test_tracks[:with_barlines], tick_sample_length,
    #                        sample_data[0...(tick_sample_length * 2)] +
    #                        sample_data[0..(tick_sample_length * 2)] +
    #                        sample_data[0...(tick_sample_length * 2)] +
    #                        sample_data[0..(tick_sample_length * 2)],
    #                        sample_data[(tick_sample_length * 2)..sample_data.length])
    helper_test_sample_data(test_tracks[:placeholder], tick_sample_length, zeroes(tick_sample_length * 4), [])


    tick_sample_length = (W.sample_rate * 60.0) / 99 / 4   # 6681.818181818181818
    test_tracks = generate_test_data()    
    assert_equal({:primary => [], :overflow => []}, test_tracks[:blank].sample_data(tick_sample_length))
    helper_test_sample_data(test_tracks[:solo], tick_sample_length, sample_data + zeroes(tick_sample_length - W.sample_data.length), [])
    helper_test_sample_data(test_tracks[:with_overflow], tick_sample_length, zeroes(tick_sample_length * 3) + sample_data + zeroes(tick_sample_length - sample_data.length + 1), [])
    helper_test_sample_data(test_tracks[:with_barlines], tick_sample_length,
                            sample_data + zeroes((tick_sample_length * 2) - sample_data.length) +
                            sample_data + zeroes((tick_sample_length * 2) - sample_data.length + 1) +
                            sample_data + zeroes((tick_sample_length * 2) - sample_data.length) +
                            sample_data + zeroes((tick_sample_length * 2) - sample_data.length + 1),
                            [])
    helper_test_sample_data(test_tracks[:placeholder], tick_sample_length, zeroes(tick_sample_length * 4), [])
  end
  
  def helper_test_sample_data(track, tick_sample_length, expected_primary, expected_overflow)
    sample_data = track.sample_data(tick_sample_length)
    
    assert_equal(Hash,                      sample_data.class)
    assert_equal(["overflow", "primary"],   sample_data.keys.map{|key| key.to_s}.sort)
    assert_equal(expected_primary.length,   sample_data[:primary].length)
    assert_equal(expected_overflow.length,  sample_data[:overflow].length)
    assert_equal(expected_primary,          sample_data[:primary])
    assert_equal(expected_overflow,         sample_data[:overflow])
  end
  
private

  def zeroes(length)
    return [].fill(0, 0, length)
  end
end