require 'includes'

# Kit which allows directly changing the sound bank after initialization, to allows tests
# to use fixture data directly in the test instead of loading it from the file system.
class MutableKit < Kit
  attr_accessor :sound_bank
end

class KitTest < Test::Unit::TestCase
  MIN_SAMPLE_8BIT = 0
  MAX_SAMPLE_8BIT = 255

  def generate_test_data
    kits = {}

    # Kit with no sounds
    kits[:empty] = Kit.new("test/sounds", {})

    # Kits which only has simple sounds
    kits[:mono8]    = Kit.new("test/sounds", {"mono8" => "bass_mono_8.wav"})
    kits[:mono16]   = Kit.new("test/sounds", {"mono8"  => "bass_mono_8.wav",
                                              "mono16" => "bass_mono_16.wav"})
    kits[:stereo8]  = Kit.new("test/sounds", {"mono8"   => "bass_mono_8.wav",
                                              "stereo8" => "bass_stereo_8.wav"})
    kits[:stereo16] = Kit.new("test/sounds", {"mono8"    => "bass_mono_8.wav",
                                              "mono16"   => "bass_mono_16.wav",
                                              "stereo16" => "bass_stereo_16.wav"})

    # Kits which contain a composite sound
    #kits[:basic_composite] = Kit.new("test/sounds", {"mono8"  => "bass_mono_8.wav",
    #                                                 "composite_mono8" => ["snare_mono_8.wav", "tom3_mono_8.wav"]})
    #kits[:mismatched_bps_composite] = Kit.new("test/sounds", {"mono8"  => "bass_mono_8.wav",
    #                                                          "composite_mono16" => ["snare_mono_8.wav", "tom3_mono_16.wav"]})
    #kits[:mismatched_channels_composite] = Kit.new("test/sounds", {"mono8"  => "bass_mono_8.wav",
    #                                                               "composite_stereo16" => ["snare_stereo_16.wav", "tom3_mono_16.wav"]})
    #kits[:mismatched_everything_composite] = Kit.new("test/sounds", {"mono8"  => "bass_mono_8.wav",
    #                                                                 "composite_stereo16" => ["snare_stereo_8.wav", "tom3_mono_16.wav"]})

    kits
  end

  def test_valid_initialization
    kits = generate_test_data()

    assert_equal(16, kits[:empty].bits_per_sample)
    assert_equal(1, kits[:empty].num_channels)

    assert_equal(16, kits[:mono8].bits_per_sample)
    assert_equal(1, kits[:mono8].num_channels)

    assert_equal(16, kits[:mono16].bits_per_sample)
    assert_equal(1, kits[:mono16].num_channels)

    assert_equal(16, kits[:stereo8].bits_per_sample)
    assert_equal(2, kits[:stereo8].num_channels)

    assert_equal(16, kits[:stereo16].bits_per_sample)
    assert_equal(2, kits[:stereo16].num_channels)

    #assert_equal(16, kits[:basic_composite].bits_per_sample)
    #assert_equal(1, kits[:basic_composite].num_channels)

    #assert_equal(16, kits[:mismatched_bps_composite].bits_per_sample)
    #assert_equal(1, kits[:mismatched_bps_composite].num_channels)

    #assert_equal(16, kits[:mismatched_channels_composite].bits_per_sample)
    #assert_equal(2, kits[:mismatched_channels_composite].num_channels)

    #assert_equal(16, kits[:mismatched_everything_composite].bits_per_sample)
    #assert_equal(2, kits[:mismatched_everything_composite].num_channels)
  end

  def test_invalid_initialization
    # Tests for adding non-existant sound file to Kit
    assert_raise(SoundFileNotFoundError) { Kit.new("test/sounds", {"i_do_not_exist" => "i_do_not_exist.wav"}) }

    assert_raise(SoundFileNotFoundError) { Kit.new("test/sounds", {"mono16" => "bass_mono_16.wav",
                                                                   "i_do_not_exist" => "i_do_not_exist.wav"}) }

    #assert_raise(SoundFileNotFoundError) { Kit.new("test/sounds", {"mono16" => "bass_mono_16.wav",
    #                                                               "composite" => ["bass_mono_16.wav", "snare_mono_16.wav"],
    #                                                               "i_do_not_exist" => "i_do_not_exist.wav"}) }

    # Tests for adding invalid sound files to Kit
    assert_raise(InvalidSoundFormatError) { Kit.new("test", {"bad" => "kit_test.rb"}) }

    assert_raise(InvalidSoundFormatError) { Kit.new("test", {"mono16" => "sounds/bass_mono_16.wav",
                                                             "bad" => "kit_test.rb"}) }

    #assert_raise(InvalidSoundFormatError) { Kit.new("test", {"mono16" => "sounds/bass_mono_16.wav",
    #                                                         "composite" => ["sounds/bass_mono_16.wav", "sounds/snare_mono_16.wav"],
    #                                                         "bad" => "kit_test.rb"}) }
  end

  def test_get_sample_data
    kits = generate_test_data()
    # Should get an error when trying to get a non-existent sound
    assert_raise(StandardError) { kits[:mono8].get_sample_data("nonexistant") }

    [:mono8, :mono16].each do |kit_name|
      sample_data = kits[kit_name].get_sample_data("mono8")
      # Assert sample data is 16-bit. If max and min samples are outside 0-255 bounds, then it is.
      assert(sample_data.max > MAX_SAMPLE_8BIT)
      assert(sample_data.min < MIN_SAMPLE_8BIT)
      # Assert it has 1 channel. This is true if every item is a Fixnum.
      assert_equal([], sample_data.select {|sample| sample.class != Fixnum})
    end

    [:stereo8, :stereo16].each do |kit_name|
      sample_data = kits[kit_name].get_sample_data("mono8")
      # Assert sample data is 16-bit. If max and min samples are outside 0-255 bounds, then it is.
      assert(sample_data.flatten.max > MAX_SAMPLE_8BIT)
      assert(sample_data.flatten.min < MIN_SAMPLE_8BIT)
      # Assert it has 2 channels. This is true if every item is an Array.
      assert_equal([], sample_data.select {|sample| sample.class != Array})
    end

    #actual_sample_data = kits[:basic_composite].get_sample_data("composite_mono8")
    #expected_sample_data = WaveFile.open("test/sounds/composite_snare_mono_8_tom3_mono_8_mono_16.wav").sample_data
    #assert_equal(expected_sample_data, actual_sample_data)

    #actual_sample_data = kits[:mismatched_bps_composite].get_sample_data("composite_mono16")
    #expected_sample_data = WaveFile.open("test/sounds/composite_snare_mono_8_tom3_mono_16_mono_16.wav").sample_data
    #assert_equal(expected_sample_data, actual_sample_data)

    #actual_sample_data = kits[:mismatched_channels_composite].get_sample_data("composite_stereo16")
    #expected_sample_data = WaveFile.open("test/sounds/composite_snare_stereo_16_tom3_mono_16_stereo_16.wav").sample_data
    #assert_equal(expected_sample_data, actual_sample_data)

    #actual_sample_data = kits[:mismatched_everything_composite].get_sample_data("composite_stereo16")
    #expected_sample_data = WaveFile.open("test/sounds/composite_snare_stereo_8_tom3_mono_16_stereo_16.wav").sample_data
    #assert_equal(expected_sample_data[0..10], actual_sample_data[0..10])
  end

  def test_scale!
    sound_bank = {"a" => [-10, 0, 20], "b" => [], "c" => [12346, 9999]}

    kit = MutableKit.new(".", {})
    kit.sound_bank = sound_bank

    kit.scale!(5)
    assert_equal([-2, 0, 4], kit.get_sample_data("a"))
    assert_equal([], kit.get_sample_data("b"))
    assert_equal([2469, 1999], kit.get_sample_data("c"))

    kit.scale!(2)
    assert_equal([-1, 0, 2], kit.get_sample_data("a"))
    assert_equal([], kit.get_sample_data("b"))
    assert_equal([1234, 999], kit.get_sample_data("c"))
  end
end
