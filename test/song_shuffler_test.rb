require 'includes'

class SongShufflerTest < Test::Unit::TestCase
  def test_full_song
    base_path = File.dirname(__FILE__) + "/sounds"
    song, kit = SongParser.new.parse(base_path, File.read("test/fixtures/valid/example_mono_16_base_path.txt"))

    shuffled_song = Transforms::SongShuffler.transform(song)

    assert_equal(160, shuffled_song.tempo)
    assert_equal([:verse, :verse, :chorus, :chorus, :chorus, :chorus,
                  :verse, :verse, :chorus, :chorus, :chorus, :chorus],
                 shuffled_song.flow)

    assert_equal([:chorus, :verse], shuffled_song.patterns.keys.sort)

    chorus_pattern = shuffled_song.patterns[:chorus]
    assert_equal(["bass",
                  "snare",
                  "hh_closed",
                  "hh_closed2",
                  "tom4_mono_16.wav",
                  "tom2_mono_16.wav"],
                 chorus_pattern.tracks.keys)

    assert_equal("X.....X.....X.X...X.....", chorus_pattern.tracks["bass"].rhythm)
    assert_equal("......X...........X.....", chorus_pattern.tracks["snare"].rhythm)
    assert_equal("X..X.XX..X.X............", chorus_pattern.tracks["hh_closed"].rhythm)
    assert_equal("............X..X.X...X..", chorus_pattern.tracks["hh_closed2"].rhythm)
    assert_equal(".................X......", chorus_pattern.tracks["tom4_mono_16.wav"].rhythm)
    assert_equal(".....................X..", chorus_pattern.tracks["tom2_mono_16.wav"].rhythm)

    verse_pattern = shuffled_song.patterns[:verse]
    assert_equal(["bass",
                  "snare",
                  "hh_closed",
                  "hh_closed2",
                  "agogo"],
                 verse_pattern.tracks.keys)

    assert_equal("X.....X.....X.....X.....", verse_pattern.tracks["bass"].rhythm)
    assert_equal(".....................X..", verse_pattern.tracks["snare"].rhythm)
    assert_equal("X..X.XX..X.X............", verse_pattern.tracks["hh_closed"].rhythm)
    assert_equal("............X..X..X..X..", verse_pattern.tracks["hh_closed2"].rhythm)
    assert_equal(".....................X.X", verse_pattern.tracks["agogo"].rhythm)
  end

  def test_odd_pattern_length
    song = Song.new

    pattern = song.pattern(:my_pattern)
    pattern.track("track1", "X..X..X")

    song.pattern(pattern)

    shuffled_song = Transforms::SongShuffler.transform(song)
    shuffled_pattern = shuffled_song.patterns[:my_pattern]
    assert_equal("X....X...X", shuffled_pattern.tracks["track1"].rhythm)
  end

  def test_fractional_tempo_rounded_up
    song = Song.new
    song.tempo = 140
    
    song = Transforms::SongShuffler.transform(song)
    assert_equal(187, song.tempo)   # 186.66666666666666 rounded up
  end

  def test_fractional_tempo_rounded_down
    song = Song.new
    song.tempo = 145
    
    song = Transforms::SongShuffler.transform(song)
    assert_equal(193, song.tempo)   # 193.33333333333331 rounded down
  end
end
