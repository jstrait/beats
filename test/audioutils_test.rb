$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class AudioUtilsTest < Test::Unit::TestCase
  def test_composite
    assert_equal([], AudioUtils.composite([]))

    # Mono
    assert_equal([10, 20, 30, 40], AudioUtils.composite([[10, 20, 30, 40]]))
    assert_equal([30, 50, 70, -10], AudioUtils.composite([[10, 20, 30, 40], [20, 30, 40, -50]]))
    assert_equal([70, 80, 60], AudioUtils.composite([[20, 30], [10], [40, 50, 60]]))

    # Stereo
    assert_equal([[10, 20], [30, 40]], AudioUtils.composite([[[10, 20], [30, 40]]]))
    assert_equal([[30, 50], [70, -10]], AudioUtils.composite([[[10, 20], [30, 40]], [[20, 30], [40, -50]]]))
    assert_equal([[90, 120], [120, 140], [100, 110]], AudioUtils.composite([[[20, 30], [40, 50]], [[10, 20]], [[60, 70], [80, 90], [100, 110]]]))
  end

  def test_num_channels
    assert_equal(1, AudioUtils.num_channels([1, 2, 3, 4]))
    assert_equal(2, AudioUtils.num_channels([[1, 2], [3, 4], [5, 6], [7, 8]]))
  end

  def test_normalize
    assert_equal([], AudioUtils.normalize([], 5))
    assert_equal([100, 200, 300, 400, 500], AudioUtils.normalize([100, 200, 300, 400, 500], 1))
    assert_equal([20, 40, 60, 80, 100], AudioUtils.normalize([100, 200, 300, 400, 500], 5))
  end

  S  = [-100, 200, 300, -400]    # Sample data for a sound. Unrealistically short for clarity.
  SL = S + [0, 0]                # Sound when tick sample length is longer than full sound length
  SS = [-100, 200]               # Sound when tick sample length is less than full sound length
  SO = [300, -400]               # Sound overflow when tick sample length is less than full sound length
  TE = [0, 0, 0, 0]              # A tick with no sound, with length equal to S
  TL = [0, 0, 0, 0, 0, 0]        # A tick with no sound, longer than full sound length
  TS = [0, 0]                    # A tick with no sound, shorter than full sound length

  # These tests use unrealistically short sounds and tick sample lengths, to make tests a lot easier to work with.
  def test_generate_rhythm_sample_data
    
    # 1.) Tick sample length is equal to the length of the sound sample data.
    #     When this is the case, overflow should never occur.
    helper_generate_rhythm [0],          4, []
    helper_generate_rhythm [0, 1],       4, S
    helper_generate_rhythm [0, 2],       4, S + TE
    helper_generate_rhythm [1, 1],       4, TE + S
    helper_generate_rhythm [3, 2],       4, (TE * 3) + S + TE
    helper_generate_rhythm [1, 2, 1, 2], 4, TE + S + TE + S + S + TE
  
    # 2.) Tick sample length is longer than the sound sample data. This is similar to (1), except that there should
    #     be some extra silence after the end of each trigger.
    #     Like (1), overflow should never occur.
    helper_generate_rhythm [0],          6, []
    helper_generate_rhythm [0, 1],       6, SL
    helper_generate_rhythm [0, 2],       6, SL + TL
    helper_generate_rhythm [1, 1],       6, TL + SL
    helper_generate_rhythm [3, 2],       6, (TL * 3) + SL + TL
    helper_generate_rhythm [1, 2, 1, 2], 6, TL + SL + TL + SL + SL + TL

    # 3.) Tick sample length is less than the sound sample data. Overflow will now occur!
    helper_generate_rhythm [0],          2, [],              []
    helper_generate_rhythm [0, 1],       2, SS,              SO
    helper_generate_rhythm [0, 2],       2, S,               []
    helper_generate_rhythm [1, 1],       2, TS + SS,         SO
    helper_generate_rhythm [3, 2],       2, (TS * 3) + S,    []
    helper_generate_rhythm [1, 2, 1, 2], 2, TS + S + SS + S, []
  end

  def helper_generate_rhythm(beats, tick_sample_length, expected_primary, expected_overflow = [])
    actual = AudioUtils.generate_rhythm(beats, tick_sample_length, S)
    
    assert_equal(Hash,                     actual.class)
    assert_equal(["overflow", "primary"],  actual.keys.map{|key| key.to_s}.sort)
    assert_equal(expected_primary,         actual[:primary])
    assert_equal(expected_overflow,        actual[:overflow])
  end
end
