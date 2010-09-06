$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class SongParserTest < Test::Unit::TestCase
  FIXTURE_BASE_PATH = File.dirname(__FILE__) + "/.."
  
  def self.load_fixture(fixture_name)
    return SongParser.new().parse(FIXTURE_BASE_PATH, YAML.load_file("test/fixtures/#{fixture_name}"))
  end
  
  def self.generate_test_data
    kit = Kit.new("test/sounds", {"bass.wav"      => "bass_mono_8.wav",
                                  "snare.wav"     => "snare_mono_8.wav",
                                  "hh_closed.wav" => "hh_closed_mono_8.wav",
                                  "ride.wav"      => "ride_mono_8.wav"})

    test_songs = {}
    
    # TODO: Add fixture for track with no rhythm
    test_songs[:no_tempo] = load_fixture("valid/no_tempo.txt")
    test_songs[:repeats_not_specified] = load_fixture("valid/repeats_not_specified.txt")
    test_songs[:overflow] = load_fixture("valid/pattern_with_overflow.txt")
    test_songs[:from_valid_yaml_string] = load_fixture("valid/example_no_kit.txt")
    test_songs[:from_valid_yaml_string_with_kit] = load_fixture("valid/example_with_kit.txt")
    test_songs[:from_valid_yaml_string_with_empty_track] = load_fixture("valid/example_with_empty_track.txt")
    test_songs[:multiple_tracks_same_sound] = load_fixture("valid/multiple_tracks_same_sound.txt")

    return test_songs
  end

  def test_valid_parse
    test_songs = SongParserTest.generate_test_data()
    
    assert_equal(120, test_songs[:no_tempo].tempo)
    assert_equal([:verse], test_songs[:no_tempo].flow)
    
    assert_equal(100, test_songs[:repeats_not_specified].tempo)
    assert_equal([:verse], test_songs[:repeats_not_specified].flow)
    
    # These two songs should be the same, except that one uses a kit in the song header
    # and the other doesn't.
    [:from_valid_yaml_string, :from_valid_yaml_string_with_kit].each do |song_key|
      song = test_songs[song_key]
      assert_equal([:verse, :verse,
                    :chorus, :chorus,
                    :verse, :verse,
                    :chorus, :chorus, :chorus, :chorus,
                    :bridge,
                    :chorus, :chorus, :chorus, :chorus],
                   song.flow)
      assert_equal(99, song.tempo)
      assert_equal((Song::SAMPLE_RATE * Song::SECONDS_PER_MINUTE) / 99 / 4.0, song.tick_sample_length)
      assert_equal(["bridge", "chorus", "verse"], song.patterns.keys.map{|key| key.to_s}.sort)
      assert_equal(4, song.patterns[:verse].tracks.length)
      assert_equal(5, song.patterns[:chorus].tracks.length)
      assert_equal(1, song.patterns[:bridge].tracks.length)
    end
    
    song = test_songs[:from_valid_yaml_string_with_empty_track]
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
  end
  
  def test_invalid_parse
    invalid_fixtures = ["bad_repeat_count",
                        "bad_flow",
                        "bad_tempo",
                        "no_header",
                        "no_flow",
                        "pattern_with_no_tracks",
                        "sound_in_kit_not_found",
                        "sound_in_track_not_found",
                        "sound_in_kit_wrong_format",
                        "sound_in_track_wrong_format"]
    
    invalid_fixtures.each do |fixture|
      assert_raise(SongParseError) do
        song = SongParserTest.load_fixture("invalid/#{fixture}.txt")
      end
    end
    
    assert_raise(InvalidRhythmError) do
      song = SongParserTest.load_fixture("invalid/bad_rhythm.txt")
    end
  end
end