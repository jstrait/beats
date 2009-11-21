$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class SongTest < Test::Unit::TestCase
  MIN_SAMPLE_8BIT = 0
  MAX_SAMPLE_8BIT = 255
  
  def test_add
    # Test adding sounds with progressively higher bits per sample and num channels.
    # Verify that kit.bits_per_sample and kit.num_channels is ratcheted up.
    kit = Kit.new()
    assert_equal(kit.bits_per_sample, 0)
    assert_equal(kit.num_channels, 0)
    assert_equal(kit.size, 0)
    kit.add("mono8", "test/sounds/bass_mono_8.wav")
    assert_equal(kit.bits_per_sample, 8)
    assert_equal(kit.num_channels, 1)
    assert_equal(kit.size, 1)
    kit.add("mono16", "test/sounds/bass_mono_16.wav")
    assert_equal(kit.bits_per_sample, 16)
    assert_equal(kit.num_channels, 1)
    assert_equal(kit.size, 2)
    kit.add("stereo16", "test/sounds/bass_stereo_16.wav")
    assert_equal(kit.bits_per_sample, 16)
    assert_equal(kit.num_channels, 2)
    assert_equal(kit.size, 3)
    
    # Test adding sounds with progressively lower bits per sample and num channels.
    # Verify that kit.bits_per_sample and kit.num_channels doesn't change.
    kit = Kit.new()
    assert_equal(kit.bits_per_sample, 0)
    assert_equal(kit.num_channels, 0)
    kit.add("stereo16", "test/sounds/bass_stereo_16.wav")
    assert_equal(kit.bits_per_sample, 16)
    assert_equal(kit.num_channels, 2)
    kit.add("mono16", "test/sounds/bass_mono_16.wav")
    assert_equal(kit.bits_per_sample, 16)
    assert_equal(kit.num_channels, 2)
    kit.add("mono8", "test/sounds/bass_mono_8.wav")
    assert_equal(kit.bits_per_sample, 16)
    assert_equal(kit.num_channels, 2)
  end
  
  def test_get_sample_data
    kit = Kit.new()
    
    assert_raise(StandardError) { kit.get_sample_data("nonexistant") }
    
    # Test adding sounds with progressively higher bits per sample and num channels.
    # Verify that sample data bits per sample and num channels is ratcheted up.
    kit.add("mono8", "test/sounds/bass_mono_8.wav")
    sample_data = kit.get_sample_data("mono8")
    assert(sample_data.max <= MAX_SAMPLE_8BIT)
    assert(sample_data.min >= MIN_SAMPLE_8BIT)
    all_are_fixnums = true
    sample_data.each {|sample|
      all_are_fixnums &&= sample.class == Fixnum
    }
    assert(all_are_fixnums)
    
    kit.add("mono16", "test/sounds/bass_mono_16.wav")
    sample_data = kit.get_sample_data("mono8")
    assert(sample_data.max > MAX_SAMPLE_8BIT)
    assert(sample_data.min < MIN_SAMPLE_8BIT)
    all_are_fixnums = true
    sample_data.each {|sample|
      all_are_fixnums &&= sample.class == Fixnum
    }
    assert(all_are_fixnums)
    
    kit.add("stereo16", "test/sounds/bass_stereo_16.wav")
    sample_data = kit.get_sample_data("stereo16")
    assert(sample_data.flatten.max > MAX_SAMPLE_8BIT)
    assert(sample_data.flatten.min < MIN_SAMPLE_8BIT)
    all_are_arrays = true
    sample_data.each {|sample|
      all_are_arrays &&= sample.class == Array
    }
    assert(all_are_arrays)
    assert(sample_data.first.length == 2)
    
    
    # Test adding sounds with progressively lower bits per sample and num channels.
    # Verify that sample data bits per sample and num channels doesn't go down.
    kit = Kit.new()
    
    kit.add("stereo16", "test/sounds/bass_stereo_16.wav")
    sample_data = kit.get_sample_data("stereo16")
    assert(sample_data.flatten.max > MAX_SAMPLE_8BIT)
    assert(sample_data.flatten.min < MIN_SAMPLE_8BIT)
    all_are_arrays = true
    sample_data.each {|sample|
      all_are_arrays &&= sample.class == Array
    }
    assert(all_are_arrays)
    assert(sample_data.first.length == 2)
    
    kit.add("mono16", "test/sounds/bass_mono_16.wav")
    sample_data = kit.get_sample_data("mono16")
    assert(sample_data.flatten.max > MAX_SAMPLE_8BIT)
    assert(sample_data.flatten.min < MIN_SAMPLE_8BIT)
    all_are_arrays = true
    sample_data.each {|sample|
      all_are_arrays &&= sample.class == Array
    }
    assert(all_are_arrays)
    assert(sample_data.first.length == 2)
    
    kit.add("mono8", "test/sounds/bass_mono_8.wav")
    sample_data = kit.get_sample_data("mono8")
    assert(sample_data.flatten.max > MAX_SAMPLE_8BIT)
    assert(sample_data.flatten.min < MIN_SAMPLE_8BIT)
    all_are_arrays = true
    sample_data.each {|sample|
      all_are_arrays &&= sample.class == Array
    }
    assert(all_are_arrays)
    assert(sample_data.first.length == 2)
  end
end