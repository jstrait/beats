$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class SongParserTest < Test::Unit::TestCase  
  def self.generate_test_data
    kit = Kit.new("test/sounds")
    kit.add("bass.wav",      "bass_mono_8.wav")
    kit.add("snare.wav",     "snare_mono_8.wav")
    kit.add("hh_closed.wav", "hh_closed_mono_8.wav")
    kit.add("ride.wav",      "ride_mono_8.wav")

    test_songs = {}
    base_path = File.dirname(__FILE__) + "/.."

    test_songs[:no_tempo] = SongParser.new().parse(base_path, YAML.load_file("test/fixtures/valid/no_tempo.txt"))
    test_songs[:repeats_not_specified] = SongParser.new().parse(base_path, YAML.load_file("test/fixtures/valid/repeats_not_specified.txt"))
    test_songs[:overflow] = SongParser.new().parse(base_path, YAML.load_file("test/fixtures/valid/pattern_with_overflow.txt"))
    # TODO: Add fixture for track with no rhythm
    test_songs[:from_valid_yaml_string] = SongParser.new().parse(base_path, YAML.load_file("test/fixtures/valid/example_no_kit.txt"))
    test_songs[:from_valid_yaml_string_with_kit] = SongParser.new().parse(base_path, YAML.load_file("test/fixtures/valid/example_with_kit.txt"))
    test_songs[:from_valid_yaml_string_with_empty_track] = SongParser.new().parse(base_path, YAML.load_file("test/fixtures/valid/example_with_empty_track.txt"))

    return test_songs
  end

  def test_valid_parse
    test_songs = SongParserTest.generate_test_data()
    
    assert_equal(test_songs[:no_tempo].tempo, 120)
    assert_equal(test_songs[:no_tempo].structure, [:verse])
    
    assert_equal(test_songs[:repeats_not_specified].tempo, 100)
    assert_equal(test_songs[:repeats_not_specified].structure, [:verse])
    
    # These two songs should be the same, except that one uses a kit in the song header
    # and the other doesn't.
    [:from_valid_yaml_string, :from_valid_yaml_string_with_kit].each do |song_key|
      song = test_songs[song_key]
      assert_equal(song.structure, [:verse, :verse, :chorus, :chorus, :verse, :verse, :chorus, :chorus, :chorus, :chorus, :bridge, :chorus, :chorus, :chorus, :chorus])
      assert_equal(song.tempo, 99)
      assert_equal(song.tick_sample_length, (Song::SAMPLE_RATE * Song::SECONDS_PER_MINUTE) / 99 / 4.0)
      assert_equal(song.patterns.keys.map{|key| key.to_s}.sort, ["bridge", "chorus", "verse"])
      assert_equal(song.patterns[:verse].tracks.length, 4)
      assert_equal(song.patterns[:chorus].tracks.length, 5)
      assert_equal(song.patterns[:bridge].tracks.length, 1)
    end
    
    song = test_songs[:from_valid_yaml_string_with_empty_track]
    assert_equal(1, song.patterns.length)
    assert_equal(2, song.patterns[:verse].tracks.length)
    assert_equal("........", song.patterns[:verse].tracks["test/sounds/bass_mono_8.wav"].rhythm)
    assert_equal("X...X...", song.patterns[:verse].tracks["test/sounds/snare_mono_8.wav"].rhythm)
  end
  
  def test_invalid_parse
    invalid_fixtures = ["bad_repeat_count",
                        "bad_structure",
                        "bad_tempo",
                        "no_header",
                        "no_structure",
                        "sound_in_track_not_found",
                        "sound_in_kit_not_found",]
    
    invalid_fixtures.each do |fixture|
      assert_raise(SongParseError) do
        song = SongParser.new().parse(File.dirname(__FILE__) + "/..",
                                      YAML.load_file("test/fixtures/invalid/" + fixture + ".txt"))
      end
    end
    
    assert_raise(InvalidRhythmError) do
      song = SongParser.new().parse(File.dirname(__FILE__) + "/..",
                                    YAML.load_file("test/fixtures/invalid/bad_rhythm.txt"))
    end
  end
end