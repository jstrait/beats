$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class AudioUtilsTest < Test::Unit::TestCase
  def test_composite
    assert_equal([], AudioUtils.composite([]))

    # Mono
    assert_equal([10, 20, 30, 40], AudioUtils.composite([[10, 20, 30, 40]]))
    assert_equal([30, 50, 70, -10], AudioUtils.composite([[10, 20, 30, 40], [20, 30, 40, -50]]))

    # Stereo
    assert_equal([[10, 20], [30, 40]], AudioUtils.composite([[[10, 20], [30, 40]]]))
    assert_equal([[30, 50], [70, -10]], AudioUtils.composite([[[10, 20], [30, 40]], [[20, 30], [40, -50]]]))
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
end
