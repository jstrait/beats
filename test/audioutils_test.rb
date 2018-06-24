require 'includes'

class AudioUtilsTest < Minitest::Test
  def test_composite
    # Mono empty arrays
    assert_equal([], AudioUtils.composite([], 1))
    assert_equal([], AudioUtils.composite([[]], 1))
    assert_equal([], AudioUtils.composite([[], [], [], []], 1))

    # Stereo empty arrays
    assert_equal([], AudioUtils.composite([], 2))
    assert_equal([], AudioUtils.composite([[]], 2))
    assert_equal([], AudioUtils.composite([[], [], [], []], 2))

    # Mono
    assert_equal([10, 20, 30, 40], AudioUtils.composite([[10, 20, 30, 40]], 1))
    assert_equal([10, 20, 30, 40], AudioUtils.composite([[10, 20, 30, 40], []], 1))
    assert_equal([30, 50, 70, -10], AudioUtils.composite([[10, 20, 30, 40], [20, 30, 40, -50]], 1))
    assert_equal([70, 80, 60], AudioUtils.composite([[20, 30], [10], [40, 50, 60]], 1))

    # Stereo
    assert_equal([[10, 20], [30, 40]], AudioUtils.composite([[[10, 20], [30, 40]]], 2))
    assert_equal([[10, 20], [30, 40]], AudioUtils.composite([[[10, 20], [30, 40]], []], 2))
    assert_equal([[30, 50], [70, -10]], AudioUtils.composite([[[10, 20], [30, 40]], [[20, 30], [40, -50]]], 2))
    assert_equal([[90, 120], [120, 140], [100, 110]], AudioUtils.composite([[[20, 30], [40, 50]], [[10, 20]], [[60, 70], [80, 90], [100, 110]]], 2))
  end

  def test_scale
    assert_equal([], AudioUtils.scale([], 1, 5))
    assert_equal([], AudioUtils.scale([], 2, 5))
    assert_equal([100, 200, 300, 400, 500], AudioUtils.scale([100, 200, 300, 400, 500], 1, 1))
    assert_equal([20, 40, 60, 80, 100], AudioUtils.scale([100, 200, 300, 400, 500], 1, 5))

    assert_equal([[100, 200], [300, 400], [500, 600]], AudioUtils.scale([[100, 200], [300, 400], [500, 600]], 2, 1))
    assert_equal([[20, 40], [60, 80], [100, 120]], AudioUtils.scale([[100, 200], [300, 400], [500, 600]], 2, 5))

    assert_equal([[10, 20, 30], [100, 200, 300], [1000, 2000, 3000]], AudioUtils.scale([[10, 20, 30], [100, 200, 300], [1000, 2000, 3000]], 3, 1))
    assert_equal([[5, 10, 15], [50, 100, 150], [500, 1000, 1500]], AudioUtils.scale([[10, 20, 30], [100, 200, 300], [1000, 2000, 3000]], 3, 2))
  end

  def test_step_sample_length
    assert_equal(6615.0, AudioUtils.step_sample_length(44100, 100))
    assert_equal(3307.5, AudioUtils.step_sample_length(44100, 200))
    assert_equal(3307.5, AudioUtils.step_sample_length(22050, 100))

    assert_equal(6874.612880831729, AudioUtils.step_sample_length(44100, 96.2236))
    assert_equal(3437.3064404158645, AudioUtils.step_sample_length(22050, 96.2236))
  end
end
