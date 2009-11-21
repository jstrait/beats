$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class PatternTest < Test::Unit::TestCase
  SAMPLE_RATE = 44100
  SECONDS_IN_MINUTE = 60.0

  def generate_test_data
    kit = Kit.new()
    kit.add("bass.wav",      "sounds/bass.wav")
    kit.add("snare.wav",     "sounds/snare.wav")
    kit.add("hh_closed.wav", "sounds/hh_closed.wav")
    kit.add("hh_open.wav",   "sounds/hh_open.wav")
    
    test_patterns = []
    
    p1 = Pattern.new :blank
    test_patterns << p1
    
    p2 = Pattern.new :verse
    p2.track "bass.wav",      kit.get_sample_data("bass.wav"),      "X...X...X...XX..X...X...XX..X..."
    p2.track "snare.wav",     kit.get_sample_data("snare.wav"),     "..X...X...X...X.X...X...X...X..."
    p2.track "hh_closed.wav", kit.get_sample_data("hh_closed.wav"), "X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.X."
    p2.track "hh_open.wav",   kit.get_sample_data("hh_open.wav"),   "X...............X..............X"
    test_patterns << p2
    
    p3 = Pattern.new :staircase
    p3.track "bass.wav",      kit.get_sample_data("bass.wav"),      "X..."
    p3.track "snare.wav",     kit.get_sample_data("snare.wav"),     "X.."
    p3.track "hh_closed.wav", kit.get_sample_data("hh_closed.wav"), "X."
    test_patterns << p3
    
    return test_patterns
  end
  
  def test_initialize
    test_patterns = generate_test_data()
    
    pattern = test_patterns.shift()
    assert_equal(pattern.name, :blank)
    assert_equal(pattern.tracks.length, 0)

    pattern = test_patterns.shift()
    assert_equal(pattern.name, :verse)
    assert_equal(pattern.tracks.length, 4)

    pattern = test_patterns.shift()
    assert_equal(pattern.name, :staircase)
    assert_equal(pattern.tracks.length, 3)
  end

  def test_sample_length
    test_patterns = generate_test_data()
    
    tick_sample_length = 13860.0
    assert_equal(test_patterns[0].sample_length(tick_sample_length), 0)
    assert_equal(test_patterns[1].sample_length(tick_sample_length), tick_sample_length * 32)
    assert_equal(test_patterns[2].sample_length(tick_sample_length), tick_sample_length * 4)

    tick_sample_length = 6681.81818181818
    assert_equal(test_patterns[0].sample_length(tick_sample_length), 0)
    assert_equal(test_patterns[1].sample_length(tick_sample_length), (tick_sample_length * 32).floor)
    assert_equal(test_patterns[2].sample_length(tick_sample_length), (tick_sample_length * 4).floor)

    tick_sample_length = 16134.1463414634
    assert_equal(test_patterns[0].sample_length(tick_sample_length), 0)
    assert_equal(test_patterns[1].sample_length(tick_sample_length), (tick_sample_length * 32).floor)
    assert_equal(test_patterns[2].sample_length(tick_sample_length), (tick_sample_length * 4).floor)
  end

  def test_sample_data
    tick_sample_lengths = [
      13860.0,
      (SAMPLE_RATE * SECONDS_IN_MINUTE) / 99 / 4,   # 6681.81818181818
      (SAMPLE_RATE * SECONDS_IN_MINUTE) / 41 / 4    # 16134.1463414634
    ]

    tick_sample_lengths.each{|tick_sample_length| helper_test_sample_data(tick_sample_length) }
  end

  def helper_test_sample_data(tick_sample_length)
=begin
    test_patterns = generate_test_data()
    
    # Combined
    test_patterns.each{|test_pattern|
      sample_data = test_pattern.sample_data(tick_sample_length, test_pattern.tracks.length, {})
      assert_equal(sample_data.class, Hash)
      assert_equal(sample_data.keys.sort, [:overflow, :primary])
      assert_equal(sample_data[:primary].length, test_pattern.sample_length_with_overflow(tick_sample_length))
    }

    #Split
    track_samples = test_patterns[0].sample_data(tick_sample_length, true)
    assert_equal(track_samples.class, Hash)
    assert_equal(track_samples.keys, [])

    track_samples = test_patterns[1].sample_data(tick_sample_length, true)
    assert_equal(track_samples.class, Hash)
    assert_equal(track_samples.keys.sort, ["bass", "cymbal", "hihat", "snare"])
    track_samples.keys.each{|name|
      assert_equal(track_samples[name].length, test_patterns[1].sample_length_with_overflow(tick_sample_length))
    }

    track_samples = test_patterns[2].sample_data(tick_sample_length, true)
    assert_equal(track_samples.class, Hash)
    assert_equal(track_samples.keys.sort, ["bass", "hihat", "snare"])
    track_samples.keys.each{|name|
      assert_equal(track_samples[name].length, (tick_sample_length * 4).floor)
      assert_equal(track_samples[name].length, test_patterns[2].sample_length(tick_sample_length))
    }
=end
  end
end