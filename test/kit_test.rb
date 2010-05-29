$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class SongTest < Test::Unit::TestCase
  MIN_SAMPLE_8BIT = 0
  MAX_SAMPLE_8BIT = 255
  
  def test_valid_add
    # Test adding sounds with progressively higher bits per sample and num channels.
    # Verify that kit.bits_per_sample and kit.num_channels is ratcheted up.
    kit = Kit.new("test/sounds")
    assert_equal(0,  kit.bits_per_sample)
    assert_equal(0,  kit.num_channels)
    assert_equal(0,  kit.size)
    kit.add("mono8", "bass_mono_8.wav")
    assert_equal(8,  kit.bits_per_sample)
    assert_equal(1,  kit.num_channels)
    assert_equal(1,  kit.size)
    kit.add("mono16", "bass_mono_16.wav")
    assert_equal(16, kit.bits_per_sample)
    assert_equal(1,  kit.num_channels)
    assert_equal(2,  kit.size)
    kit.add("stereo16", "bass_stereo_16.wav")
    assert_equal(16, kit.bits_per_sample)
    assert_equal(2,  kit.num_channels)
    assert_equal(3,  kit.size)
    
    # Test adding sounds with progressively lower bits per sample and num channels.
    # Verify that kit.bits_per_sample and kit.num_channels doesn't change.
    kit = Kit.new("test/sounds")
    assert_equal(0,  kit.bits_per_sample)
    assert_equal(0,  kit.num_channels)
    kit.add("stereo16", "bass_stereo_16.wav")
    assert_equal(16, kit.bits_per_sample)
    assert_equal(2,  kit.num_channels)
    kit.add("mono16", "bass_mono_16.wav")
    assert_equal(16, kit.bits_per_sample)
    assert_equal(2,  kit.num_channels)
    kit.add("mono8", "bass_mono_8.wav")
    assert_equal(16, kit.bits_per_sample)
    assert_equal(2,  kit.num_channels)
  end
  
  def test_invalid_add
    kit = Kit.new("test/sounds")
    assert_raise(SoundNotFoundError) { kit.add("i_do_not_exist", "i_do_not_exist.wav") }
  end

  def test_get_sample_data
    kit = Kit.new("test/sounds")
    
    assert_raise(StandardError) { kit.get_sample_data("nonexistant") }
    
    # Test adding sounds with progressively higher bits per sample and num channels.
    # Verify that sample data bits per sample and num channels is ratcheted up.
    kit.add("mono8", "bass_mono_8.wav")
    sample_data = kit.get_sample_data("mono8")
    assert(sample_data.max <= MAX_SAMPLE_8BIT)
    assert(sample_data.min >= MIN_SAMPLE_8BIT)
    all_are_fixnums = true
    sample_data.each do |sample|
      all_are_fixnums &&= sample.class == Fixnum
    end
    assert(all_are_fixnums)
    
    kit.add("mono16", "bass_mono_16.wav")
    sample_data = kit.get_sample_data("mono8")
    assert(sample_data.max > MAX_SAMPLE_8BIT)
    assert(sample_data.min < MIN_SAMPLE_8BIT)
    all_are_fixnums = true
    sample_data.each do |sample|
      all_are_fixnums &&= sample.class == Fixnum
    end
    assert(all_are_fixnums)
    
    kit.add("stereo16", "bass_stereo_16.wav")
    sample_data = kit.get_sample_data("stereo16")
    assert(sample_data.flatten.max > MAX_SAMPLE_8BIT)
    assert(sample_data.flatten.min < MIN_SAMPLE_8BIT)
    all_are_arrays = true
    sample_data.each do |sample|
      all_are_arrays &&= sample.class == Array
    end
    assert(all_are_arrays)
    assert(sample_data.first.length == 2)
    
    
    # Test adding sounds with progressively lower bits per sample and num channels.
    # Verify that sample data bits per sample and num channels doesn't go down.
    kit = Kit.new("test/sounds")
    
    kit.add("stereo16", "bass_stereo_16.wav")
    sample_data = kit.get_sample_data("stereo16")
    assert(sample_data.flatten.max > MAX_SAMPLE_8BIT)
    assert(sample_data.flatten.min < MIN_SAMPLE_8BIT)
    all_are_arrays = true
    sample_data.each do |sample|
      all_are_arrays &&= sample.class == Array
    end
    assert(all_are_arrays)
    assert(sample_data.first.length == 2)
    
    kit.add("mono16", "bass_mono_16.wav")
    sample_data = kit.get_sample_data("mono16")
    assert(sample_data.flatten.max > MAX_SAMPLE_8BIT)
    assert(sample_data.flatten.min < MIN_SAMPLE_8BIT)
    all_are_arrays = true
    sample_data.each do |sample|
      all_are_arrays &&= sample.class == Array
    end
    assert(all_are_arrays)
    assert(sample_data.first.length == 2)
    
    kit.add("mono8", "bass_mono_8.wav")
    sample_data = kit.get_sample_data("mono8")
    assert(sample_data.flatten.max > MAX_SAMPLE_8BIT)
    assert(sample_data.flatten.min < MIN_SAMPLE_8BIT)
    all_are_arrays = true
    sample_data.each do |sample|
      all_are_arrays &&= sample.class == Array
    end
    assert(all_are_arrays)
    assert(sample_data.first.length == 2)
  end
end