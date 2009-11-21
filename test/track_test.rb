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
    
    assert_equal(test_tracks[0].beats, [0])
    assert_equal(test_tracks[0].name, "bass")
    
    assert_equal(test_tracks[1].beats, [0, 1])
    assert_equal(test_tracks[1].name, "bass")
    
    assert_equal(test_tracks[2].beats, [3, 1])
    assert_equal(test_tracks[3].beats, [0, 2, 2, 2, 2])
    assert_equal(test_tracks[4].beats, [4])
    assert_equal(test_tracks[5].beats, [2, 4, 4, 4, 2, 4, 4, 4, 4])
  end
  
  def test_sample_length
    tick_sample_lengths = [
      W.sample_data.length,                           # 13860.0
      (W.sample_rate * SECONDS_IN_MINUTE) / 99 / 4,   # 6681.81818181818
      (W.sample_rate * SECONDS_IN_MINUTE) / 41 / 4    # 16134.1463414634
    ]

    tick_sample_lengths.each { |tick_sample_length| helper_test_sample_length(tick_sample_length) }
  end

  def helper_test_sample_length(tick_sample_length)
    test_tracks = generate_test_data()
    
    assert_equal(test_tracks[0].sample_length(tick_sample_length), 0)
    assert_equal(test_tracks[0].sample_length(tick_sample_length), test_tracks[0].sample_data(tick_sample_length)[:primary].length)
    
    assert_equal(test_tracks[1].sample_length(tick_sample_length), tick_sample_length.floor)
    assert_equal(test_tracks[1].sample_length(tick_sample_length), test_tracks[1].sample_data(tick_sample_length)[:primary].length)
    
    assert_equal(test_tracks[2].sample_length(tick_sample_length), (tick_sample_length * 4).floor)
    assert_equal(test_tracks[2].sample_length(tick_sample_length), test_tracks[2].sample_data(tick_sample_length)[:primary].length)
    
    assert_equal(test_tracks[3].sample_length(tick_sample_length), (tick_sample_length * 8).floor)
    assert_equal(test_tracks[3].sample_length(tick_sample_length), test_tracks[3].sample_data(tick_sample_length)[:primary].length)
    
    assert_equal(test_tracks[4].sample_length(tick_sample_length), (tick_sample_length * 4).floor)
    assert_equal(test_tracks[4].sample_length(tick_sample_length), test_tracks[4].sample_data(tick_sample_length)[:primary].length)
    
    assert_equal(test_tracks[5].sample_length(tick_sample_length), (tick_sample_length * 32).floor)
    assert_equal(test_tracks[5].sample_length(tick_sample_length), test_tracks[5].sample_data(tick_sample_length)[:primary].length)
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
    assert_equal(test_tracks[0].sample_length_with_overflow(tick_sample_length), 0)
    assert_equal(test_tracks[0].sample_length_with_overflow(tick_sample_length), sample_data[:primary].length + sample_data[:overflow].length)
    
    sample_data = test_tracks[1].sample_data(tick_sample_length)
    if(wave_sample_length > tick_sample_length * test_tracks[1].beats.last)
      assert_equal(test_tracks[1].sample_length_with_overflow(tick_sample_length), wave_sample_length)
    else
      assert_equal(test_tracks[1].sample_length_with_overflow(tick_sample_length), tick_sample_length.floor)
      assert_equal(test_tracks[1].sample_length_with_overflow(tick_sample_length), sample_data[:primary].length + sample_data[:overflow].length)
    end
    
    sample_data = test_tracks[2].sample_data(tick_sample_length)
    if(wave_sample_length > tick_sample_length * test_tracks[2].beats.last)
      assert_equal(test_tracks[2].sample_length_with_overflow(tick_sample_length), (tick_sample_length * 4).floor + (wave_sample_length - tick_sample_length.floor))
      assert_equal(test_tracks[2].sample_length_with_overflow(tick_sample_length), sample_data[:primary].length + sample_data[:overflow].length)
    else
      assert_equal(test_tracks[2].sample_length_with_overflow(tick_sample_length), (tick_sample_length * 4).floor)
      assert_equal(test_tracks[2].sample_length_with_overflow(tick_sample_length), sample_data[:primary].length + sample_data[:overflow].length)
    end
    
    sample_data = test_tracks[3].sample_data(tick_sample_length)
    if(wave_sample_length > tick_sample_length * test_tracks[3].beats.last)
      assert_equal(test_tracks[3].sample_length_with_overflow(tick_sample_length), (tick_sample_length * 8).floor + (wave_sample_length - (tick_sample_length * 2).floor))
      assert_equal(test_tracks[3].sample_length_with_overflow(tick_sample_length), sample_data[:primary].length + sample_data[:overflow].length)
    else
      assert_equal(test_tracks[3].sample_length_with_overflow(tick_sample_length), (tick_sample_length * 8).floor)
      assert_equal(test_tracks[3].sample_length_with_overflow(tick_sample_length), sample_data[:primary].length + sample_data[:overflow].length)
    end
    
    sample_data = test_tracks[4].sample_data(tick_sample_length)
    assert_equal(test_tracks[4].sample_length_with_overflow(tick_sample_length), (tick_sample_length * 4).floor)
    assert_equal(test_tracks[4].sample_length_with_overflow(tick_sample_length), sample_data[:primary].length + sample_data[:overflow].length)
    
    sample_data = test_tracks[5].sample_data(tick_sample_length)
    assert_equal(test_tracks[5].sample_length_with_overflow(tick_sample_length), (tick_sample_length * 32).floor)
    assert_equal(test_tracks[5].sample_length_with_overflow(tick_sample_length), sample_data[:primary].length + sample_data[:overflow].length)
  end
  
  def helper_test_sample_data(track, tick_sample_length, expected_primary, expected_overflow)
    sample_data = track.sample_data(tick_sample_length)
    
    assert_equal(sample_data.class, Hash)
    assert_equal(sample_data.keys.sort, [:overflow, :primary])
    assert_equal(sample_data[:primary], expected_primary)
    assert_equal(sample_data[:overflow], expected_overflow)
  end
  
  def test_sample_data
    normalized_sample_data = W.normalized_sample_data
    
    tick_sample_length = W.sample_data.length   # 13860.0
    test_tracks = generate_test_data()
    
    assert_equal(test_tracks[0].sample_data(tick_sample_length), {:primary => [], :overflow => []})
    #helper_test_sample_data(test_tracks[1], tick_sample_length, normalized_sample_data[0...tick_sample_length], [])
    #helper_test_sample_data(test_tracks[2], tick_sample_length, zeroes(tick_sample_length * 3) + normalized_sample_data, [])
    #helper_test_sample_data(test_tracks[3], tick_sample_length, (normalized_sample_data + zeroes(tick_sample_length)) * 4, [])
    #helper_test_sample_data(test_tracks[4], tick_sample_length, zeroes(tick_sample_length * 4), [])
    # Track 6 is complicated. Will add test later...


    #tick_sample_length = (W.sample_rate * 60.0) / 99 / 4   # 6681.81818181818
    #test_tracks = generate_test_data()
    #puts "tick_sample_length = #{tick_sample_length}"

    #assert_equal(test_tracks[0].sample_data(tick_sample_length), {:primary => [], :overflow => []})
    #helper_test_sample_data(test_tracks[1], tick_sample_length, normalized_sample_data[0...tick_sample_length.floor], normalized_sample_data[tick_sample_length.floor...normalized_sample_data.length])
    
=begin
    #helper_test_sample_data(test_tracks[2], tick_sample_length, zeroes(tick_sample_length * 3) + normalized_sample_data[0..tick_sample_length.floor], normalized_sample_data[tick_sample_length.floor..normalized_sample_data.length])
    #assert_equal(test_tracks[2].sample_data(tick_sample_length),
    #             zeroes(tick_sample_length * 3) + normalized_sample_data)
    #assert_equal(test_tracks[3].sample_data(tick_sample_length),
    #             normalized_sample_data[0...(tick_sample_length * 2)] +
    #             normalized_sample_data[0..(tick_sample_length * 2)] +
    #            normalized_sample_data[0...(tick_sample_length * 2)] +
    #            normalized_sample_data[0..(tick_sample_length * 2)])
    #assert_equal(test_tracks[4].sample_data(tick_sample_length), zeroes(tick_sample_length * 4))

    tick_sample_length = (W.sample_rate * 60.0) / 41 / 4   # 16134.1463414634
    test_tracks = generate_test_data()
    puts "tick_sample_length = #{tick_sample_length}"
    
    assert_equal(T1.sample_data(tick_sample_length), [])
    assert_equal(T2.sample_data(tick_sample_length), normalized_sample_data[0...tick_sample_length] + zeroes(tick_sample_length - W.sample_data.length))
    assert_equal(T3.sample_data(tick_sample_length),
                 zeroes(tick_sample_length * 3) + normalized_sample_data[0...tick_sample_length] + zeroes(tick_sample_length - W.sample_data.length))
    assert_equal(T4.sample_data(tick_sample_length),
                 normalized_sample_data[0...(tick_sample_length * 2)] + zeroes(tick_sample_length * 2 - W.sample_data.length) +
                 normalized_sample_data[0..(tick_sample_length * 2)] + zeroes(tick_sample_length * 2 - W.sample_data.length) +
                 normalized_sample_data[0...(tick_sample_length * 2)] + zeroes(tick_sample_length * 2 - W.sample_data.length) +
                 normalized_sample_data[0..(tick_sample_length * 2)] + zeroes(tick_sample_length * 2 - W.sample_data.length) + [0.0])
    assert_equal(T5.sample_data(tick_sample_length), zeroes(tick_sample_length * 4))
=end
  end
  
private

  def zeroes(length)
    return [].fill(0.0, 0, length)
  end
end