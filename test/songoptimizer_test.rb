$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class MockSongOptimizer < SongOptimizer
  def clone_song_ignoring_patterns_and_structure(original_song)
    return super
  end
end

class SongOptimizerTest < Test::Unit::TestCase
  EXAMPLE_SONG_YAML = "
Song:
  Tempo: 135
  Structure:
    - Verse:   x2
    - Chorus:  x4
    - Verse:   x2
    - Chorus:  x4
  Kit:
    - bass:       sounds/bass.wav
    - snare:      sounds/snare.wav
    - hh_closed:  sounds/hh_closed.wav
    - agogo:      sounds/agogo_high.wav

Verse:
  - bass:             X...X...X...X...
  - snare:            ..............X.
  - hh_closed:        X.XXX.XXX.X.X.X.
  - agogo:            ..............XX

Chorus:
  - bass:             X...X...XX..X...
  - snare:            ....X.......X...
  - hh_closed:        X.XXX.XXX.XX..X.
  - sounds/tom4.wav:  ...........X....
  - sounds/tom2.wav:  ..............X."

  def test_clone_song_ignoring_patterns_and_structure
    mock_song_optimizer = MockSongOptimizer.new()
    parser = SongParser.new()
    original_song = parser.parse(File.dirname(__FILE__) + "/..", EXAMPLE_SONG_YAML)
    cloned_song = mock_song_optimizer.clone_song_ignoring_patterns_and_structure(original_song)
    
    assert_not_equal(cloned_song, original_song)
    assert_equal(cloned_song.tempo, original_song.tempo)
    assert_equal(cloned_song.kit, original_song.kit)
    assert_equal(cloned_song.tick_sample_length, original_song.tick_sample_length)
    assert_not_equal([:verse, :chorus, :verse, :chorus], original_song.structure)
    assert_equal([], cloned_song.structure)
    assert_equal({}, cloned_song.patterns)
  end

  def test_optimize
    parser = SongParser.new()
    original_song = parser.parse(File.dirname(__FILE__) + "/..", EXAMPLE_SONG_YAML)
    
    optimizer = SongOptimizer.new()
    optimized_song = optimizer.optimize(original_song, 4)
    
    assert_equal(optimized_song.tempo, 135)
    #assert_equal(optimized_song.total_tracks, 5)
    assert_equal(original_song.kit, optimized_song.kit)
    assert_equal(original_song.sample_length, optimized_song.sample_length)
    assert_equal(original_song.sample_length_with_overflow, optimized_song.sample_length_with_overflow)
    #assert_equal(original_song.sample_data(false), optimized_song.sample_data(false))
    
    pattern = optimized_song.patterns[:verse0]
    assert_equal(pattern.tracks.keys.sort, ["bass", "hh_closed"])
    assert_equal(pattern.tracks["bass"].pattern, "X...")
    assert_equal(pattern.tracks["hh_closed"].pattern, "X.XX")
    
    pattern = optimized_song.patterns[:verse4]
    assert_equal(pattern.tracks.keys.sort, ["bass", "hh_closed"])
    assert_equal(pattern.tracks["bass"].pattern, "X...")
    assert_equal(pattern.tracks["hh_closed"].pattern, "X.XX")
    
    pattern = optimized_song.patterns[:verse8]
    assert_equal(pattern.tracks.keys.sort, ["bass", "hh_closed"])
    assert_equal(pattern.tracks["bass"].pattern, "X...")
    assert_equal(pattern.tracks["hh_closed"].pattern, "X.X.")
    
    pattern = optimized_song.patterns[:verse12]
    assert_equal(pattern.tracks.keys.sort, ["agogo", "bass", "hh_closed", "snare"])
    assert_equal(pattern.tracks["bass"].pattern, "X...")
    assert_equal(pattern.tracks["snare"].pattern, "..X.")
    assert_equal(pattern.tracks["hh_closed"].pattern, "X.X.")
    assert_equal(pattern.tracks["agogo"].pattern, "..XX")
    
    pattern = optimized_song.patterns[:chorus0]
    assert_equal(pattern.tracks.keys.sort, ["bass", "hh_closed"])
    assert_equal(pattern.tracks["bass"].pattern, "X...")
    assert_equal(pattern.tracks["hh_closed"].pattern, "X.XX")
    
    pattern = optimized_song.patterns[:chorus4]
    assert_equal(pattern.tracks.keys.sort, ["bass", "hh_closed", "snare"])
    assert_equal(pattern.tracks["bass"].pattern, "X...")
    assert_equal(pattern.tracks["snare"].pattern, "X...")
    assert_equal(pattern.tracks["hh_closed"].pattern, "X.XX")
    
    pattern = optimized_song.patterns[:chorus8]
    assert_equal(pattern.tracks.keys.sort, ["bass", "hh_closed", "sounds/tom4.wav"])
    assert_equal(pattern.tracks["bass"].pattern, "XX..")
    assert_equal(pattern.tracks["hh_closed"].pattern, "X.XX")
    assert_equal(pattern.tracks["sounds/tom4.wav"].pattern, "...X")
    
    pattern = optimized_song.patterns[:chorus12]
    assert_equal(pattern.tracks.keys.sort, ["bass", "hh_closed", "snare", "sounds/tom2.wav"])
    assert_equal(pattern.tracks["bass"].pattern, "X...")
    assert_equal(pattern.tracks["snare"].pattern, "X...")
    assert_equal(pattern.tracks["hh_closed"].pattern, "..X.")
    assert_equal(pattern.tracks["sounds/tom2.wav"].pattern, "..X.")
    
    assert_equal(optimized_song.structure, [:verse0, :verse4, :verse8, :verse12,
                                            :verse0, :verse4, :verse8, :verse12,
                                            :chorus0, :chorus4, :chorus8, :chorus12,
                                            :chorus0, :chorus4, :chorus8, :chorus12,
                                            :chorus0, :chorus4, :chorus8, :chorus12,
                                            :chorus0, :chorus4, :chorus8, :chorus12,
                                            :verse0, :verse4, :verse8, :verse12,
                                            :verse0, :verse4, :verse8, :verse12,
                                            :chorus0, :chorus4, :chorus8, :chorus12,
                                            :chorus0, :chorus4, :chorus8, :chorus12,
                                            :chorus0, :chorus4, :chorus8, :chorus12,
                                            :chorus0, :chorus4, :chorus8, :chorus12])
  end
end