$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class PatternTest < Test::Unit::TestCase
  SAMPLE_RATE = 44100
  SECONDS_IN_MINUTE = 60.0

  def generate_test_data
    kit = Kit.new("test/sounds")
    kit.add("bass.wav",      "bass_mono_8.wav")
    kit.add("snare.wav",     "snare_mono_8.wav")
    kit.add("hh_closed.wav", "hh_closed_mono_8.wav")
    kit.add("hh_open.wav",   "hh_open_mono_8.wav")
    
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

  def test_same_as
    left_pattern = Pattern.new("left")
    left_pattern.track("bass",      nil, "X...X...")
    left_pattern.track("snare",     nil, "..X...X.")
    left_pattern.track("hh_closed", nil, "X.X.X.X.")
    
    right_pattern = Pattern.new("right")
    right_pattern.track("bass",      nil, "X...X...")
    right_pattern.track("snare",     nil, "..X...X.")
    right_pattern.track("hh_closed", nil, "X.X.X.X.")
    assert(left_pattern.same_as(right_pattern))
    assert(right_pattern.same_as(left_pattern))
    
    # Now switch up the order. Left and right should still be equal.
    right_pattern = Pattern.new("right")
    right_pattern.track("snare",     nil, "..X...X.")
    right_pattern.track("hh_closed", nil, "X.X.X.X.")
    right_pattern.track("bass",      nil, "X...X...")
    assert(left_pattern.same_as(right_pattern))
    assert(right_pattern.same_as(left_pattern))
    
    # Now compare the pattern with same rhythms but different track names. Should not be equal.
    different_names_pattern = Pattern.new("different_names")
    different_names_pattern.track("tom",     nil, "X...X...")
    different_names_pattern.track("cymbal",  nil, "..X...X.")
    different_names_pattern.track("hh_open", nil, "X.X.X.X.")
    assert_equal(false, left_pattern.same_as(different_names_pattern))
    assert_equal(false, different_names_pattern.same_as(left_pattern))
    
    # Now compare the pattern with same track names but different rhythms. Should not be equal.
    different_beats_pattern = Pattern.new("different_beats")
    different_beats_pattern.track("bass",      nil, "X...X...")
    different_beats_pattern.track("snare",     nil, "..X...X.")
    different_beats_pattern.track("hh_closed", nil, "X.XXX.X.")
    assert_equal(false, left_pattern.same_as(different_beats_pattern))
    assert_equal(false, different_beats_pattern.same_as(left_pattern))
  end
  
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
    test_patterns.each{|test_pattern|
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

    #Split
    track_samples = test_patterns[0].sample_data(tick_sample_length, 1, 0, {}, true)
    assert_equal(track_samples.class, Hash)
    assert_equal(track_samples.keys.map{|key| key.to_s}.sort, ["overflow", "primary"])

    track_samples = test_patterns[1].sample_data(tick_sample_length, 1, 4, {}, true)
    assert_equal(track_samples.class, Hash)
    assert_equal(track_samples[:primary].keys.map{|key| key.to_s}.sort,
                 ["bass.wav", "hh_closed.wav", "hh_open.wav", "snare.wav"])
    primary = track_samples[:primary]
    primary.keys.each do |name|
      assert_equal(primary[name].length, test_patterns[1].sample_length(tick_sample_length))
    end
    overflow = track_samples[:overflow]
    longest_overflow = find_longest_overflow(overflow)
    overflow.keys.each do |name|
      assert_equal(overflow[name].class, Array)
      #assert_lessthan(overflow[name].length, test_patterns[1].sample_length_with_overflow(tick_sample_length) - test_patterns[1].sample_length(tick_sample_length))
    end
    assert_equal(overflow[longest_overflow].length, test_patterns[1].sample_length_with_overflow(tick_sample_length) - test_patterns[1].sample_length(tick_sample_length))

    track_samples = test_patterns[2].sample_data(tick_sample_length, 1, 3, {}, true)
    assert_equal(track_samples.class, Hash)
    assert_equal(track_samples[:primary].keys.map{|key| key.to_s}.sort,
                 ["bass.wav", "hh_closed.wav", "snare.wav"])
    primary = track_samples[:primary]
    primary.keys.each do |name|
      assert_equal(primary[name].length, test_patterns[2].sample_length(tick_sample_length))
    end
    overflow = track_samples[:overflow]
    longest_overflow = find_longest_overflow(overflow)
    overflow.keys.each do |name|
      assert_equal(overflow[name].class, Array)
    end
    assert_equal(overflow[longest_overflow].length, test_patterns[2].sample_length_with_overflow(tick_sample_length) - test_patterns[2].sample_length(tick_sample_length))
    primary.keys.each do |name|
      assert_equal(primary[name].length, (tick_sample_length * 4).floor)
      assert_equal(primary[name].length, test_patterns[2].sample_length(tick_sample_length))
    end
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
    kit = Kit.new("test/sounds")
    kit.add("bass",  "bass_mono_8.wav")
    kit.add("snare", "snare_mono_8.wav")
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
end