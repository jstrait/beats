$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class AudioUtilsTest < Test::Unit::TestCase
  def load_song_fixtures
    test_songs = {}
    base_path = File.dirname(__FILE__) + "/.."
    
    test_songs[:blank] = Song.new(base_path)
    test_songs[:repeats_not_specified] = SongParser.new().parse(base_path, YAML.load_file("test/fixtures/valid/repeats_not_specified.txt"))
    test_songs[:overflow] = SongParser.new().parse(base_path, YAML.load_file("test/fixtures/valid/pattern_with_overflow.txt"))
    test_songs[:from_valid_yaml_string] = SongParser.new().parse(base_path, YAML.load_file("test/fixtures/valid/example_no_kit.txt"))
    test_songs[:from_valid_yaml_string_with_kit] = SongParser.new().parse(base_path, YAML.load_file("test/fixtures/valid/example_with_kit.txt"))
     
    return test_songs 
  end

  def test_initialize
    test_songs = load_song_fixtures()

    assert_equal(5512.5, AudioEngine.new(test_songs[:blank], nil).tick_sample_length)
    assert_equal(6615.0, AudioEngine.new(test_songs[:repeats_not_specified], nil).tick_sample_length)
  end

  def test_song_sample_length
    test_songs = load_song_fixtures()
    
    # TO DO: Replace these with simpler examples
    assert_equal(0, AudioEngine.new(test_songs[:blank], nil).song_sample_length)    
    assert_equal(6615, AudioEngine.new(test_songs[:repeats_not_specified], nil).song_sample_length)
    assert_equal(61005, AudioEngine.new(test_songs[:overflow], nil).song_sample_length)
    assert_equal(3215289, AudioEngine.new(test_songs[:from_valid_yaml_string], nil).song_sample_length)
    assert_equal(3215289, AudioEngine.new(test_songs[:from_valid_yaml_string_with_kit], nil).song_sample_length)
  end
end
