require 'includes'

class SongParserTest < Test::Unit::TestCase
  FIXTURE_BASE_PATH = File.dirname(__FILE__) + "/.."

  # TODO: Add fixture for track with no rhythm
  VALID_FIXTURES =   [:no_tempo,
                      :repeats_not_specified,
                      :pattern_with_overflow,
                      :example_no_kit,
                      :example_with_kit,
                      :example_with_empty_track,
                      :multiple_tracks_same_sound,
                      :with_structure,
                      :example_swung_8th,
                      :example_swung_16th,
                      :example_unswung]

  INVALID_FIXTURES = [:bad_repeat_count,
                      :bad_flow,
                      :bad_tempo,
                      :bad_swing_rate_1,
                      :bad_swing_rate_2,
                      :no_header,
                      :no_flow,
                      :pattern_with_no_tracks,
                      :sound_in_kit_not_found,
                      :sound_in_track_not_found,
                      :sound_in_kit_wrong_format,
                      :sound_in_track_wrong_format]

  def self.load_fixture(fixture_name)
    SongParser.new().parse(FIXTURE_BASE_PATH, File.read("test/fixtures/#{fixture_name}"))
  end

  def self.generate_test_data
    test_songs = {}
    test_kits = {}

    VALID_FIXTURES.each do |fixture_name|
      song, kit = load_fixture("valid/#{fixture_name}.txt")
      test_songs[fixture_name] = song
      test_kits[fixture_name] = kit
    end

    return test_songs, test_kits
  end

  # TODO: Add somes tests to validate the Kits
  def test_valid_parse
    test_songs, test_kits = SongParserTest.generate_test_data()

    assert_equal(120, test_songs[:no_tempo].tempo)
    assert_equal([:verse], test_songs[:no_tempo].flow)

    assert_equal(100, test_songs[:repeats_not_specified].tempo)
    assert_equal([:verse], test_songs[:repeats_not_specified].flow)

    # These two songs should be the same, except that one uses a kit in the song header
    # and the other doesn't.
    [:example_no_kit, :example_with_kit].each do |song_key|
      song = test_songs[song_key]
      assert_equal([:verse, :verse,
                    :chorus, :chorus,
                    :verse, :verse,
                    :chorus, :chorus, :chorus, :chorus,
                    :bridge,
                    :chorus, :chorus, :chorus, :chorus],
                   song.flow)
      assert_equal(99, song.tempo)
      assert_equal(["bridge", "chorus", "verse"], song.patterns.keys.map{|key| key.to_s}.sort)
      assert_equal(4, song.patterns[:verse].tracks.length)
      assert_equal(5, song.patterns[:chorus].tracks.length)
      assert_equal(1, song.patterns[:bridge].tracks.length)
    end

    song = test_songs[:example_with_empty_track]
    assert_equal(1, song.patterns.length)
    assert_equal(2, song.patterns[:verse].tracks.length)
    assert_equal("........", song.patterns[:verse].tracks["test/sounds/bass_mono_8.wav"].rhythm)
    assert_equal("X...X...", song.patterns[:verse].tracks["test/sounds/snare_mono_8.wav"].rhythm)

    song = test_songs[:multiple_tracks_same_sound]
    assert_equal(2, song.patterns.length)
    assert_equal(7, song.patterns[:verse].tracks.length)
    assert_equal(["agogo", "bass", "bass2", "bass3", "bass4", "hh_closed", "snare"],
                 song.patterns[:verse].tracks.keys.sort)
    assert_equal("X...............", song.patterns[:verse].tracks["bass"].rhythm)
    assert_equal("....X...........", song.patterns[:verse].tracks["bass2"].rhythm)
    assert_equal("........X.......", song.patterns[:verse].tracks["bass3"].rhythm)
    assert_equal("............X...", song.patterns[:verse].tracks["bass4"].rhythm)
    assert_equal("..............X.", song.patterns[:verse].tracks["snare"].rhythm)
    assert_equal("X.XXX.XXX.X.X.X.", song.patterns[:verse].tracks["hh_closed"].rhythm)
    assert_equal("..............XX", song.patterns[:verse].tracks["agogo"].rhythm)

    song = test_songs[:with_structure]
    assert_equal([:verse, :verse], song.flow)
    assert_equal(1, song.patterns.length)
    assert_equal(1, song.patterns[:verse].tracks.length)
    assert_equal("X...X...", song.patterns[:verse].tracks["test/sounds/bass_mono_8.wav"].rhythm)

    song = test_songs[:example_swung_8th]
    assert_equal(180, song.tempo)
    assert_equal([:verse, :verse, :chorus, :chorus], song.flow)
    assert_equal(2, song.patterns.length)
    assert_equal(2, song.patterns[:verse].tracks.length)
    assert_equal("X.....X.....", song.patterns[:verse].tracks["bass"].rhythm)
    assert_equal("....X.....X.", song.patterns[:verse].tracks["snare"].rhythm)
    assert_equal(2, song.patterns[:chorus].tracks.length)
    assert_equal("X.X.XXX.X.XX", song.patterns[:chorus].tracks["bass"].rhythm)
    assert_equal("..X..X..X..X", song.patterns[:chorus].tracks["snare"].rhythm)

    song = test_songs[:example_swung_16th]
    assert_equal(180, song.tempo)
    assert_equal([:verse, :verse, :chorus, :chorus], song.flow)
    assert_equal(2, song.patterns.length)
    assert_equal(2, song.patterns[:verse].tracks.length)
    assert_equal("X.....X.....", song.patterns[:verse].tracks["bass"].rhythm)
    assert_equal("...X.....X..", song.patterns[:verse].tracks["snare"].rhythm)
    assert_equal(2, song.patterns[:chorus].tracks.length)
    assert_equal("X.XX.XX.XX.X", song.patterns[:chorus].tracks["bass"].rhythm)
    assert_equal("..X..X..X..X", song.patterns[:chorus].tracks["snare"].rhythm)

    song = test_songs[:example_unswung]
    assert_equal(120, song.tempo)
    assert_equal([:verse, :verse, :chorus, :chorus], song.flow)
    assert_equal(2, song.patterns.length)
    assert_equal(2, song.patterns[:verse].tracks.length)
    assert_equal("X...X...", song.patterns[:verse].tracks["bass"].rhythm)
    assert_equal("..X...X.", song.patterns[:verse].tracks["snare"].rhythm)
    assert_equal(2, song.patterns[:chorus].tracks.length)
    assert_equal("XXXXXXXX", song.patterns[:chorus].tracks["bass"].rhythm)
    assert_equal(".X.X.X.X", song.patterns[:chorus].tracks["snare"].rhythm)
  end

  def test_invalid_parse
    INVALID_FIXTURES.each do |fixture|
      assert_raise(SongParseError) do
        song = SongParserTest.load_fixture("invalid/#{fixture}.txt")
      end
    end

    assert_raise(InvalidRhythmError) do
      song = SongParserTest.load_fixture("invalid/bad_rhythm.txt")
    end
  end
end
