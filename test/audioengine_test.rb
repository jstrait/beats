$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class AudioEngineTest < Test::Unit::TestCase
  FIXTURES = [:repeats_not_specified,
              :pattern_with_overflow,
              :example_no_kit,
              :example_with_kit]

  def load_fixtures
    test_engines = {}
    base_path = File.dirname(__FILE__) + "/.."
    song_parser = SongParser.new()
    
    test_engines[:blank] = AudioEngine.new(Song.new(), Kit.new(base_path, {}))

    FIXTURES.each do |fixture_name|
      song, kit = song_parser.parse(base_path, YAML.load_file("test/fixtures/valid/#{fixture_name}.txt"))
      test_engines[fixture_name] = AudioEngine.new(song, kit)
    end
     
    return test_engines 
  end

  def test_initialize
    test_engines = load_fixtures()

    assert_equal(5512.5, test_engines[:blank].tick_sample_length)
    assert_equal(6615.0, test_engines[:repeats_not_specified].tick_sample_length)
  end
end
