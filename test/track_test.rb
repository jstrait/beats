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
    test_tracks = []
    
    test_tracks << MockTrack.new("bass", W.sample_data, "")
    test_tracks << MockTrack.new("bass", W.sample_data, "X")
    test_tracks << MockTrack.new("bass", W.sample_data, "...X")
    test_tracks << MockTrack.new("bass", W.sample_data, "X.X.X.X.")
    test_tracks << MockTrack.new("bass", W.sample_data, "....")
    test_tracks << MockTrack.new("bass", W.sample_data, "..X...X...X...X.X...X...X...X...")
    
    return test_tracks
  end
  
  def test_initialize
    test_tracks = generate_test_data()
    
    assert_equal([0], test_tracks[0].beats)
    assert_equal("bass", test_tracks[0].name)
    
    assert_equal([0, 1], test_tracks[1].beats)
    assert_equal("bass", test_tracks[1].name)
    
    assert_equal([3, 1], test_tracks[2].beats)
    assert_equal([0, 2, 2, 2, 2], test_tracks[3].beats)
    assert_equal([4], test_tracks[4].beats)
    assert_equal([2, 4, 4, 4, 2, 4, 4, 4, 4], test_tracks[5].beats)
  end
  
  def test_tick_count
    test_tracks = generate_test_data()
    
    assert_equal(0,  test_tracks[0].tick_count())
    assert_equal(1,  test_tracks[1].tick_count())
    assert_equal(4,  test_tracks[2].tick_count())
    assert_equal(8,  test_tracks[3].tick_count())
    assert_equal(4,  test_tracks[4].tick_count())
    assert_equal(32, test_tracks[5].tick_count())
  end

  def test_intro_sample_length
    test_tracks = generate_test_data()

    tick_sample_length = W.sample_data.length        # 6179.0
    assert_equal(0,     test_tracks[0].intro_sample_length(tick_sample_length))
    assert_equal(0,     test_tracks[1].intro_sample_length(tick_sample_length))
    assert_equal(18537, test_tracks[2].intro_sample_length(tick_sample_length))
    assert_equal(0,     test_tracks[3].intro_sample_length(tick_sample_length))
    assert_equal(24716, test_tracks[4].intro_sample_length(tick_sample_length))
    assert_equal(12358, test_tracks[5].intro_sample_length(tick_sample_length))
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
    
    assert_equal(0, test_tracks[0].sample_length(tick_sample_length))
    assert_equal(test_tracks[0].sample_data(tick_sample_length)[:primary].length, test_tracks[0].sample_length(tick_sample_length))
    
    assert_equal(tick_sample_length.floor, test_tracks[1].sample_length(tick_sample_length))
    assert_equal(test_tracks[1].sample_data(tick_sample_length)[:primary].length, test_tracks[1].sample_length(tick_sample_length))
    
    assert_equal((tick_sample_length * 4).floor, test_tracks[2].sample_length(tick_sample_length))
    assert_equal(test_tracks[2].sample_data(tick_sample_length)[:primary].length, test_tracks[2].sample_length(tick_sample_length))
    
    assert_equal((tick_sample_length * 8).floor, test_tracks[3].sample_length(tick_sample_length))
    assert_equal(test_tracks[3].sample_data(tick_sample_length)[:primary].length, test_tracks[3].sample_length(tick_sample_length))
    
    assert_equal((tick_sample_length * 4).floor, test_tracks[4].sample_length(tick_sample_length))
    assert_equal(test_tracks[4].sample_data(tick_sample_length)[:primary].length, test_tracks[4].sample_length(tick_sample_length))
    
    assert_equal((tick_sample_length * 32).floor, test_tracks[5].sample_length(tick_sample_length))
    assert_equal(test_tracks[5].sample_data(tick_sample_length)[:primary].length, test_tracks[5].sample_length(tick_sample_length))
  end
  
  def test_sample_length_with_overflow
    tick_sample_lengths = [
      W.sample_data.length,                           # 13860.0
      (W.sample_rate * SECONDS_IN_MINUTE) / 99 / 4,   # 6681.81818181818
      (W.sample_rate * SECONDS_IN_MINUTE) / 41 / 4    # 16134.1463414634
    ]

    tick_sample_lengths.each { |tick_sample_length| helper_test_sample_length_with_overflow(tick_sample_length) }
  end
  
  def helper_test_sample_length_with_overflow(tick_sample_length)
    wave_sample_length = W.sample_data.length
    test_tracks = generate_test_data()
    
    sample_data = test_tracks[0].sample_data(tick_sample_length)
    assert_equal(0, test_tracks[0].sample_length_with_overflow(tick_sample_length))
    assert_equal(sample_data[:primary].length + sample_data[:overflow].length, test_tracks[0].sample_length_with_overflow(tick_sample_length))
    
    sample_data = test_tracks[1].sample_data(tick_sample_length)
    if(wave_sample_length > tick_sample_length * test_tracks[1].beats.last)
      assert_equal(wave_sample_length, test_tracks[1].sample_length_with_overflow(tick_sample_length))
    else
      assert_equal(tick_sample_length.floor, test_tracks[1].sample_length_with_overflow(tick_sample_length))
      assert_equal(sample_data[:primary].length + sample_data[:overflow].length, test_tracks[1].sample_length_with_overflow(tick_sample_length))
    end
    
    sample_data = test_tracks[2].sample_data(tick_sample_length)
    if(wave_sample_length > tick_sample_length * test_tracks[2].beats.last)
      assert_equal((tick_sample_length * 4).floor + (wave_sample_length - tick_sample_length.floor), test_tracks[2].sample_length_with_overflow(tick_sample_length))
      assert_equal(sample_data[:primary].length + sample_data[:overflow].length, test_tracks[2].sample_length_with_overflow(tick_sample_length))
    else
      assert_equal((tick_sample_length * 4).floor, test_tracks[2].sample_length_with_overflow(tick_sample_length))
      assert_equal(sample_data[:primary].length + sample_data[:overflow].length, test_tracks[2].sample_length_with_overflow(tick_sample_length))
    end
    
    sample_data = test_tracks[3].sample_data(tick_sample_length)
    if(wave_sample_length > tick_sample_length * test_tracks[3].beats.last)
      assert_equal((tick_sample_length * 8).floor + (wave_sample_length - (tick_sample_length * 2).floor), test_tracks[3].sample_length_with_overflow(tick_sample_length))
      assert_equal(sample_data[:primary].length + sample_data[:overflow].length, test_tracks[3].sample_length_with_overflow(tick_sample_length))
    else
      assert_equal((tick_sample_length * 8).floor, test_tracks[3].sample_length_with_overflow(tick_sample_length))
      assert_equal(sample_data[:primary].length + sample_data[:overflow].length, test_tracks[3].sample_length_with_overflow(tick_sample_length))
    end
    
    sample_data = test_tracks[4].sample_data(tick_sample_length)
    assert_equal((tick_sample_length * 4).floor, test_tracks[4].sample_length_with_overflow(tick_sample_length))
    assert_equal(sample_data[:primary].length + sample_data[:overflow].length, test_tracks[4].sample_length_with_overflow(tick_sample_length))
    
    sample_data = test_tracks[5].sample_data(tick_sample_length)
    assert_equal((tick_sample_length * 32).floor, test_tracks[5].sample_length_with_overflow(tick_sample_length))
    assert_equal(sample_data[:primary].length + sample_data[:overflow].length, test_tracks[5].sample_length_with_overflow(tick_sample_length))
  end
  
  def test_sample_data_overflow
    track = generate_test_data()[2]
    tick_sample_length = W.sample_data.length   # 6179.0
    
    overflow = W.sample_data[(W.sample_data.length / 2)..W.sample_data.length]
    expected_sample_data = zeroes(tick_sample_length * 3) + W.sample_data
    expected_sample_data[0...overflow.length] = overflow
    actual_sample_data = track.sample_data(tick_sample_length, overflow)
    assert_equal(expected_sample_data, actual_sample_data[:primary])

    # Call sample_data() again with different overflow, to verify that cached
    # sample data only contains the primary sample data.
    overflow = W.sample_data[0..(W.sample_data.length / 2)]
    expected_sample_data = zeroes(tick_sample_length * 3) + W.sample_data
    expected_sample_data[0...overflow.length] = overflow
    actual_sample_data = track.sample_data(tick_sample_length, overflow)
    assert_equal(expected_sample_data, actual_sample_data[:primary])
  end
  
  def test_sample_data
    sample_data = W.sample_data
    
    tick_sample_length = W.sample_data.length   # 6179.0
    test_tracks = generate_test_data()
    assert_equal({:primary => [], :overflow => []}, test_tracks[0].sample_data(tick_sample_length))
    helper_test_sample_data(test_tracks[1], tick_sample_length, sample_data[0...tick_sample_length], [])
    helper_test_sample_data(test_tracks[2], tick_sample_length, zeroes(tick_sample_length * 3) + sample_data, [])
    helper_test_sample_data(test_tracks[3], tick_sample_length, (sample_data + zeroes(tick_sample_length)) * 4, [])
    helper_test_sample_data(test_tracks[4], tick_sample_length, zeroes(tick_sample_length * 4), [])
    # Track 6 is complicated. Will add test later...


    tick_sample_length = (W.sample_rate * 60.0) / 220 / 4   # 3006.818181818181818
    test_tracks = generate_test_data()
    assert_equal({:primary => [], :overflow => []}, test_tracks[0].sample_data(tick_sample_length))
    helper_test_sample_data(test_tracks[1], tick_sample_length, sample_data[0...tick_sample_length.floor], sample_data[tick_sample_length.floor...sample_data.length])
    #helper_test_sample_data(test_tracks[2], tick_sample_length, zeroes(tick_sample_length * 3) + sample_data[0..tick_sample_length.floor], sample_data[(tick_sample_length.floor)...sample_data.length])
    #helper_test_sample_data(test_tracks[3], tick_sample_length,
    #                        sample_data[0...(tick_sample_length * 2)] +
    #                        sample_data[0..(tick_sample_length * 2)] +
    #                        sample_data[0...(tick_sample_length * 2)] +
    #                        sample_data[0..(tick_sample_length * 2)],
    #                        sample_data[(tick_sample_length * 2)..sample_data.length])
    helper_test_sample_data(test_tracks[4], tick_sample_length, zeroes(tick_sample_length * 4), [])


    tick_sample_length = (W.sample_rate * 60.0) / 99 / 4   # 6681.818181818181818
    test_tracks = generate_test_data()    
    assert_equal({:primary => [], :overflow => []}, test_tracks[0].sample_data(tick_sample_length))
    helper_test_sample_data(test_tracks[1], tick_sample_length, sample_data + zeroes(tick_sample_length - W.sample_data.length), [])
    helper_test_sample_data(test_tracks[2], tick_sample_length, zeroes(tick_sample_length * 3) + sample_data + zeroes(tick_sample_length - sample_data.length + 1), [])
    helper_test_sample_data(test_tracks[3], tick_sample_length,
                            sample_data + zeroes((tick_sample_length * 2) - sample_data.length) +
                            sample_data + zeroes((tick_sample_length * 2) - sample_data.length + 1) +
                            sample_data + zeroes((tick_sample_length * 2) - sample_data.length) +
                            sample_data + zeroes((tick_sample_length * 2) - sample_data.length + 1),
                            [])
    helper_test_sample_data(test_tracks[4], tick_sample_length, zeroes(tick_sample_length * 4), [])
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