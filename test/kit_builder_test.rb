require 'includes'

class KitBuilderTest < Test::Unit::TestCase
  def test_has_label?
    kit_builder = KitBuilder.new("test/sounds")

    assert_equal(false, kit_builder.has_label?("label1"))
    assert_equal(false, kit_builder.has_label?("label2"))

    kit_builder.add_item("label1", "bass_mono_8.wav")
    assert_equal(true,  kit_builder.has_label?("label1"))
    assert_equal(false, kit_builder.has_label?("label2"))
  end

  def test_build_kit_happy_path
    kit_builder = KitBuilder.new("test/sounds")

    kit_builder.add_item("mono8", "bass_stereo_8.wav")
    kit_builder.add_item("bass_mono_16.wav", "bass_mono_16.wav")

    kit = kit_builder.build_kit

    assert_equal(Kit, kit.class)
    assert_equal(2, kit.num_channels)
    assert_equal(16, kit.bits_per_sample)
    assert_equal(Array, kit.get_sample_data('mono8').class)
    assert_equal(Array, kit.get_sample_data('bass_mono_16.wav').class)
  end

  def test_build_kit_no_sounds
    kit_builder = KitBuilder.new("test/sounds")

    kit = kit_builder.build_kit
    assert_equal(Kit, kit.class)
    assert_equal(1, kit.num_channels)
    assert_equal(16, kit.bits_per_sample)
  end

  def test_build_kit_with_non_existent_sound_file
    kit_builder = KitBuilder.new("test/sounds")
    kit_builder.add_item("fake", "i_do_not_exist.wav")

    assert_raise(KitBuilder::SoundFileNotFoundError) { kit_builder.build_kit }
  end

  def test_build_kit_with_invalid_sound_file
    kit_builder = KitBuilder.new("test/sounds")
    kit_builder.add_item("ruby_file", "../kit_builder_test.rb")

    assert_raise(KitBuilder::InvalidSoundFormatError) { kit_builder.build_kit }
  end
end
