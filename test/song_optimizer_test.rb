require "includes"

class MockSongOptimizer < SongOptimizer
  def clone_song_ignoring_patterns_and_flow(original_song)
    super
  end
end

class SongOptimizerTest < Minitest::Test
  FIXTURE_BASE_PATH = File.dirname(__FILE__) + "/.."

  EXAMPLE_SONG_YAML = "
Song:
  Tempo: 135
  Flow:
    - Verse:   x2
    - Chorus:  x4
    - Verse:   x2
    - Chorus:  x4
  Kit:
    - bass:       sounds/bass_mono_8.wav
    - snare:      sounds/snare_mono_8.wav
    - hh_closed:  sounds/hh_closed_mono_8.wav
    - agogo:      sounds/agogo_high_mono_8.wav

Verse:
  - bass:             X...X...X...X...
  - snare:            ..............X.
  - hh_closed:        X.XXX.XXX.X.X.X.
  - agogo:            ..............XX

Chorus:
  - bass:             X...X...XX..X...
  - snare:            ....X.......X...
  - hh_closed:        X.XXX.XXX.XX..X.
  - sounds/tom4_mono_8.wav:  ...........X....
  - sounds/tom2_mono_8.wav:  ..............X."

  EXAMPLE_SONG_YAML_EMPTY_SUB_PATTERN = "
Song:
  Tempo: 135
  Flow:
    - Verse:   x1
  Kit:
    - bass:   sounds/bass_mono_8.wav
    - snare:  sounds/snare_mono_8.wav

Verse:
  - bass:   X.......X...
  - snare:  ..........X."

  def self.load_fixture(fixture_name)
    SongParser.parse(FIXTURE_BASE_PATH, File.read("test/fixtures/#{fixture_name}"))
  end

  def test_optimize
    original_song, _ = SongParser.parse(File.dirname(__FILE__), EXAMPLE_SONG_YAML)

    optimizer = SongOptimizer.new
    optimized_song = optimizer.optimize(original_song, 4)

    assert_equal(optimized_song.tempo, 135)
    #assert_equal(optimized_song.total_tracks, 5)

    # TODO: Add some sort of AudioEngine test to verify that optimized and unoptimized song have same sample data.
    #assert_equal(original_song.sample_length, optimized_song.sample_length)
    #assert_equal(original_song.sample_length_with_overflow, optimized_song.sample_length_with_overflow)
    #assert_equal(original_song.sample_data(false), optimized_song.sample_data(false))

    # Patterns :verse_0 and :verse_4 should be removed since they are identical to :chorus_0
    assert_equal([:chorus_0, :chorus_12, :chorus_4, :chorus_8, :verse_12, :verse_8],
                 optimized_song.patterns.keys.sort {|x, y| x.to_s <=> y.to_s })

    pattern = optimized_song.patterns[:verse_8]
    assert_equal(pattern.tracks.keys.sort, ["bass", "hh_closed"])
    assert_equal(pattern.tracks["bass"].rhythm, "X...")
    assert_equal(pattern.tracks["hh_closed"].rhythm, "X.X.")

    pattern = optimized_song.patterns[:verse_12]
    assert_equal(pattern.tracks.keys.sort, ["agogo", "bass", "hh_closed", "snare"])
    assert_equal(pattern.tracks["bass"].rhythm, "X...")
    assert_equal(pattern.tracks["snare"].rhythm, "..X.")
    assert_equal(pattern.tracks["hh_closed"].rhythm, "X.X.")
    assert_equal(pattern.tracks["agogo"].rhythm, "..XX")

    pattern = optimized_song.patterns[:chorus_0]
    assert_equal(pattern.tracks.keys.sort, ["bass", "hh_closed"])
    assert_equal(pattern.tracks["bass"].rhythm, "X...")
    assert_equal(pattern.tracks["hh_closed"].rhythm, "X.XX")

    pattern = optimized_song.patterns[:chorus_4]
    assert_equal(pattern.tracks.keys.sort, ["bass", "hh_closed", "snare"])
    assert_equal(pattern.tracks["bass"].rhythm, "X...")
    assert_equal(pattern.tracks["snare"].rhythm, "X...")
    assert_equal(pattern.tracks["hh_closed"].rhythm, "X.XX")

    pattern = optimized_song.patterns[:chorus_8]
    assert_equal(pattern.tracks.keys.sort, ["bass", "hh_closed", "sounds/tom4_mono_8.wav"])
    assert_equal(pattern.tracks["bass"].rhythm, "XX..")
    assert_equal(pattern.tracks["hh_closed"].rhythm, "X.XX")
    assert_equal(pattern.tracks["sounds/tom4_mono_8.wav"].rhythm, "...X")

    pattern = optimized_song.patterns[:chorus_12]
    assert_equal(pattern.tracks.keys.sort, ["bass", "hh_closed", "snare", "sounds/tom2_mono_8.wav"])
    assert_equal(pattern.tracks["bass"].rhythm, "X...")
    assert_equal(pattern.tracks["snare"].rhythm, "X...")
    assert_equal(pattern.tracks["hh_closed"].rhythm, "..X.")
    assert_equal(pattern.tracks["sounds/tom2_mono_8.wav"].rhythm, "..X.")

    assert_equal(optimized_song.flow, [:chorus_0, :chorus_0, :verse_8, :verse_12,
                                       :chorus_0, :chorus_0, :verse_8, :verse_12,
                                       :chorus_0, :chorus_4, :chorus_8, :chorus_12,
                                       :chorus_0, :chorus_4, :chorus_8, :chorus_12,
                                       :chorus_0, :chorus_4, :chorus_8, :chorus_12,
                                       :chorus_0, :chorus_4, :chorus_8, :chorus_12,
                                       :chorus_0, :chorus_0, :verse_8, :verse_12,
                                       :chorus_0, :chorus_0, :verse_8, :verse_12,
                                       :chorus_0, :chorus_4, :chorus_8, :chorus_12,
                                       :chorus_0, :chorus_4, :chorus_8, :chorus_12,
                                       :chorus_0, :chorus_4, :chorus_8, :chorus_12,
                                       :chorus_0, :chorus_4, :chorus_8, :chorus_12])
  end

  def test_optimize_song_nondivisible_max_pattern_length
    original_song, _ = SongParser.parse(File.dirname(__FILE__), EXAMPLE_SONG_YAML_EMPTY_SUB_PATTERN)

    optimizer = SongOptimizer.new
    optimized_song = optimizer.optimize(original_song, 7)

    pattern = optimized_song.patterns[:verse_0]
    assert_equal(["bass"], pattern.tracks.keys.sort)
    assert_equal("X......", pattern.tracks["bass"].rhythm)

    pattern = optimized_song.patterns[:verse_7]
    assert_equal(["bass", "snare"], pattern.tracks.keys.sort)
    assert_equal(".X...", pattern.tracks["bass"].rhythm)
    assert_equal("...X.", pattern.tracks["snare"].rhythm)

    assert_equal([:verse_0, :verse_7], optimized_song.flow)
  end

  def test_pattern_collision
    original_song, _ = SongOptimizerTest.load_fixture("valid/optimize_pattern_collision.txt")
    optimizer = SongOptimizer.new
    optimized_song = optimizer.optimize(original_song, 4)

    assert_equal([:verse2_0, :verse_0, :verse_20], optimized_song.patterns.keys.sort {|x, y| x.to_s <=> y.to_s })
  end

  def test_optimize_song_containing_empty_pattern
    original_song, _ = SongParser.parse(File.dirname(__FILE__), EXAMPLE_SONG_YAML_EMPTY_SUB_PATTERN)

    optimizer = SongOptimizer.new
    optimized_song = optimizer.optimize(original_song, 4)

    pattern = optimized_song.patterns[:verse_0]
    assert_equal(["bass"], pattern.tracks.keys.sort)
    assert_equal("X...", pattern.tracks["bass"].rhythm)

    pattern = optimized_song.patterns[:verse_4]
    assert_equal([Kit::PLACEHOLDER_TRACK_NAME], pattern.tracks.keys.sort)
    assert_equal("....", pattern.tracks[Kit::PLACEHOLDER_TRACK_NAME].rhythm)

    pattern = optimized_song.patterns[:verse_8]
    assert_equal(["bass", "snare"], pattern.tracks.keys.sort)
    assert_equal("X...", pattern.tracks["bass"].rhythm)
    assert_equal("..X.", pattern.tracks["snare"].rhythm)

    assert_equal([:verse_0, :verse_4, :verse_8], optimized_song.flow)
  end
end
