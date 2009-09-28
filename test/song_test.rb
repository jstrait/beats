$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'song'
require 'pattern'
require 'track'

class MockSong < Song
  attr_reader :patterns
end

class SongTest < Test::Unit::TestCase
  DEFAULT_TEMPO = 120
  
  def generate_test_data
    test_songs = {}
    
    test_songs[:blank] = MockSong.new
    
    test_songs[:no_structure] = MockSong.new
    verse = test_songs[:no_structure].pattern :verse
    verse.track "bass.wav",  "X.......X......."
    verse.track "snare.wav", "....X.......X..."
    verse.track "hihat.wav", "X.X.X.X.X.X.X.X."
    
    test_songs[:from_code] = MockSong.new
    verse = test_songs[:from_code].pattern :verse
    verse.track "bass.wav",  "X.......X......."
    verse.track "snare.wav", "....X.......X..."
    verse.track "hihat.wav", "X.X.X.X.X.X.X.X."
    chorus = test_songs[:from_code].pattern :chorus
    chorus.track "bass.wav",  "X......."
    chorus.track "snare.wav", "....X..X"
    chorus.track "ride.wav",  "X.....X."
    test_songs[:from_code].structure = [:verse, :chorus, :verse, :chorus, :chorus]
    
    yaml_string = "# An example song

Song:
  Tempo: 99
  Structure:
    - Verse:  x2
    - Chorus: x2
    - Verse:  x2
    - Chorus: x4
    - Bridge: x1
    - Chorus: x4

Verse:
  bass.wav:    X...X...X...XX..X...X...XX..X...
  snare.wav:   ..X...X...X...X.X...X...X...X...
# Here is a comment
  hihat.wav:   X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.
  cymbal.wav:  X...............X..............X
# Here is another comment
Chorus:
  bass.wav:    X...X...XXXXXXXXX...X...X...X...
  snare.wav:   ...................X...X...X...X
  hihat.wav:   X.X.XXX.X.X.XXX.X.X.XXX.X.X.XXX. # It's comment time
  cymbal.wav:  ........X.......X.......X.......
  sine.wav:    ....X...................X.......


Bridge:
  hihat.wav:   XX.XXX.XXX.XXX.XXX.XXX.XXX.XXX.X"
    test_songs[:from_yaml_string] = MockSong.new(yaml_string)
    
    return test_songs
  end
  
  def test_initialize
    test_songs = generate_test_data
    
    assert_equal(test_songs[:blank].structure, [])
    assert_equal(test_songs[:blank].tick_sample_length, (Song::SAMPLE_RATE * Song::SECONDS_PER_MINUTE) / DEFAULT_TEMPO / 4.0)
    assert_equal(test_songs[:no_structure].structure, [])
    assert_equal(test_songs[:no_structure].tick_sample_length, (Song::SAMPLE_RATE * Song::SECONDS_PER_MINUTE) / DEFAULT_TEMPO / 4.0)
    assert_equal(test_songs[:from_code].structure, [:verse, :chorus, :verse, :chorus, :chorus])
    assert_equal(test_songs[:from_code].tick_sample_length, (Song::SAMPLE_RATE * Song::SECONDS_PER_MINUTE) / DEFAULT_TEMPO / 4.0)
    
    assert_equal(test_songs[:from_yaml_string].structure, [:verse, :verse, :chorus, :chorus, :verse, :verse, :chorus, :chorus, :chorus, :chorus, :bridge, :chorus, :chorus, :chorus, :chorus])
    assert_equal(test_songs[:from_yaml_string].tempo, 99)
    assert_equal(test_songs[:from_yaml_string].tick_sample_length, (Song::SAMPLE_RATE * Song::SECONDS_PER_MINUTE) / 99 / 4.0)
    assert_equal(test_songs[:from_yaml_string].patterns.keys.sort, [:bridge, :chorus, :verse])
    assert_equal(test_songs[:from_yaml_string].patterns[:verse].tracks.length, 4)
    assert_equal(test_songs[:from_yaml_string].patterns[:chorus].tracks.length, 5)
    assert_equal(test_songs[:from_yaml_string].patterns[:bridge].tracks.length, 1)
  end
  
  def test_sample_length
    test_songs = generate_test_data()

    assert_equal(test_songs[:blank].sample_length, 0)
    assert_equal(test_songs[:no_structure].sample_length, 0)
    assert_equal(test_songs[:from_code].sample_length,
                            (test_songs[:from_code].tick_sample_length * 16 * 2) +
                            (test_songs[:from_code].tick_sample_length * 8 * 3))
   
    assert_equal(test_songs[:blank].sample_length, 0)
    assert_equal(test_songs[:no_structure].sample_length, 0)
    assert_equal(test_songs[:from_code].sample_length,
                            ((test_songs[:from_code].tick_sample_length * 16).floor * 2) +
                            ((test_songs[:from_code].tick_sample_length * 8).floor * 3))
    
    assert_equal(test_songs[:blank].sample_length, 0)
    assert_equal(test_songs[:no_structure].sample_length, 0)
    assert_equal(test_songs[:from_code].sample_length,
                            ((test_songs[:from_code].tick_sample_length * 16).floor * 2) +
                            ((test_songs[:from_code].tick_sample_length * 8).floor * 3))
  end
end