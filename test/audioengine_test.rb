$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class AudioEngineTest < Test::Unit::TestCase
  FIXTURES = [:repeats_not_specified,
              :pattern_with_overflow,
              :example_no_kit,
              :example_with_kit]

  def load_song_fixtures
    test_songs = {}
    base_path = File.dirname(__FILE__) + "/.."
    song_parser = SongParser.new()
    
    test_songs[:blank] = AudioEngine.new(Song.new(), Kit.new(base_path, {}))


    FIXTURES.each do |fixture_name|
      song, kit = song_parser.parse(base_path, YAML.load_file("test/fixtures/valid/#{fixture_name}.txt"))
      test_songs[fixture_name] = AudioEngine.new(song, kit)
    end
     
    return test_songs 
  end

  def test_initialize
    test_songs = load_song_fixtures()

    assert_equal(5512.5, test_songs[:blank].tick_sample_length)
    assert_equal(6615.0, test_songs[:repeats_not_specified].tick_sample_length)
  end
end
