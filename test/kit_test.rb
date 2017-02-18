require 'includes'

class KitTest < Minitest::Test
  def test_kit_with_items
    kit = Kit.new({'label1' => [1,2,3], 'label2' => [4,5,6], 'label3' => [7,8,9]}, 1, 16)

    assert_equal([1,2,3], kit.get_sample_data('label1'))
    assert_equal([4,5,6], kit.get_sample_data('label2'))
    assert_raises(Kit::LabelNotFoundError) { kit.get_sample_data('nope') }
    assert_equal([7,8,9], kit.get_sample_data('label3'))
  end

  def test_kit_with_no_items
    kit = Kit.new({}, 1, 16)
    assert_raises(Kit::LabelNotFoundError) { kit.get_sample_data('foo') }
  end

  def test_num_channels
    kit = Kit.new({}, 2, 16)
    assert_equal(2, kit.num_channels)
  end

  def test_bits_per_sample
    kit = Kit.new({}, 2, 16)
    assert_equal(16, kit.bits_per_sample)
  end
end

