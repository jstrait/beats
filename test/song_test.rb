$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class MockSong < Song
  attr_reader :patterns
  attr_accessor :kit
end

class SongTest < Test::Unit::TestCase
  DEFAULT_TEMPO = 120
  
  def generate_test_data
    kit = Kit.new()
    kit.add("bass.wav",      "sounds/bass.wav")
    kit.add("snare.wav",     "sounds/snare.wav")
    kit.add("hh_closed.wav", "sounds/hh_closed.wav")
    kit.add("ride.wav",      "sounds/ride.wav")
    
    test_songs = {}
    
    test_songs[:blank] = MockSong.new
    
    test_songs[:no_structure] = MockSong.new
    verse = test_songs[:no_structure].pattern :verse
    verse.track "bass.wav",      kit.get_sample_data("bass.wav"),      "X.......X......."
    verse.track "snare.wav",     kit.get_sample_data("snare.wav"),     "....X.......X..."
    verse.track "hh_closed.wav", kit.get_sample_data("hh_closed.wav"), "X.X.X.X.X.X.X.X."
    
    test_songs[:from_code] = MockSong.new
    verse = test_songs[:from_code].pattern :verse
    verse.track "bass.wav",      kit.get_sample_data("bass.wav"),      "X.......X......."
    verse.track "snare.wav",     kit.get_sample_data("snare.wav"),     "....X.......X..."
    verse.track "hh_closed.wav", kit.get_sample_data("hh_closed.wav"), "X.X.X.X.X.X.X.X."
    chorus = test_songs[:from_code].pattern :chorus
    chorus.track "bass.wav",  kit.get_sample_data("bass.wav"),  "X......."
    chorus.track "snare.wav", kit.get_sample_data("snare.wav"), "....X..X"
    chorus.track "ride.wav",  kit.get_sample_data("ride.wav"),  "X.....X."
    test_songs[:from_code].structure = [:verse, :chorus, :verse, :chorus, :chorus]
    test_songs[:from_code].kit = kit
    
    valid_yaml_string = "# An example song

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
  - sounds/bass.wav:      X...X...X...XX..X...X...XX..X...
  - sounds/snare.wav:     ..X...X...X...X.X...X...X...X...
# Here is a comment
  - sounds/hh_closed.wav: X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.
  - sounds/hh_open.wav:   X...............X..............X
# Here is another comment
Chorus:
  - sounds/bass.wav:      X...X...XXXXXXXXX...X...X...X...
  - sounds/snare.wav:     ...................X...X...X...X
  - sounds/hh_closed.wav: X.X.XXX.X.X.XXX.X.X.XXX.X.X.XXX. # It's comment time
  - sounds/hh_open.wav:   ........X.......X.......X.......
  - sounds/ride.wav:      ....X...................X.......


Bridge:
  - sounds/hh_closed.wav: XX.XXX.XXX.XXX.XXX.XXX.XXX.XXX.X"
  
    test_songs[:from_valid_yaml_string] = MockSong.new(valid_yaml_string)
    
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
    
    assert_equal(test_songs[:from_valid_yaml_string].structure, [:verse, :verse, :chorus, :chorus, :verse, :verse, :chorus, :chorus, :chorus, :chorus, :bridge, :chorus, :chorus, :chorus, :chorus])
    assert_equal(test_songs[:from_valid_yaml_string].tempo, 99)
    assert_equal(test_songs[:from_valid_yaml_string].tick_sample_length, (Song::SAMPLE_RATE * Song::SECONDS_PER_MINUTE) / 99 / 4.0)
    #assert_equal(test_songs[:from_valid_yaml_string].patterns.keys.sort, [:bridge, :chorus, :verse])
    assert_equal(test_songs[:from_valid_yaml_string].patterns[:verse].tracks.length, 4)
    assert_equal(test_songs[:from_valid_yaml_string].patterns[:chorus].tracks.length, 5)
    assert_equal(test_songs[:from_valid_yaml_string].patterns[:bridge].tracks.length, 1)
  end
  
  def test_invalid_initialize
    invalid_tempo_yaml_string = "# Invalid tempo song
    Song:
      Tempo: 100a
      Structure:
        - Verse:  x2

    Verse:
      - sounds/bass.wav:      X...X...X...XX..X...X...XX..X..."
    assert_raise(SongParseError) { song = MockSong.new(invalid_tempo_yaml_string) }
    
    invalid_structure_yaml_string = "# Invalid structure song
    Song:
      Tempo: 100
      Structure:
        - Verse:  x2
        - Chorus: x1

    Verse:
      - sounds/bass.wav:      X...X...X...XX..X...X...XX..X..."
    assert_raise(SongParseError) { song = MockSong.new(invalid_structure_yaml_string) }
    
    invalid_repeats_yaml_string = "    # Invalid structure song
    Song:
      Tempo: 100
      Structure:
        - Verse:  x2a

    Verse:
      - sounds/bass.wav:      X...X...X...XX..X...X...XX..X..."
    assert_raise(SongParseError) { song = MockSong.new(invalid_repeats_yaml_string) }
  end
  
  def test_total_tracks
    test_songs = generate_test_data()
    
    assert_equal(test_songs[:blank].total_tracks, 0)
    assert_equal(test_songs[:no_structure].total_tracks, 3)
    assert_equal(test_songs[:from_code].total_tracks, 3)
    assert_equal(test_songs[:from_valid_yaml_string].total_tracks, 5)
  end
  
  def test_sample_length
    test_songs = generate_test_data()

    assert_equal(test_songs[:blank].sample_length, 0)
    assert_equal(test_songs[:no_structure].sample_length, 0)
    assert_equal(test_songs[:from_code].sample_length,
                            (test_songs[:from_code].tick_sample_length * 16 * 2) +
                            (test_songs[:from_code].tick_sample_length * 8 * 3))
    assert_equal(test_songs[:from_code].sample_length,
                            ((test_songs[:from_code].tick_sample_length * 16).floor * 2) +
                            ((test_songs[:from_code].tick_sample_length * 8).floor * 3))
    assert_equal(test_songs[:from_code].sample_length,
                            ((test_songs[:from_code].tick_sample_length * 16).floor * 2) +
                            ((test_songs[:from_code].tick_sample_length * 8).floor * 3))
  end
  
  def test_sample_length_with_overflow
    test_songs = generate_test_data()
    
    assert_equal(test_songs[:blank].sample_length_with_overflow, 0)
    assert_equal(test_songs[:no_structure].sample_length_with_overflow, 0)
    snare_overflow =
      (test_songs[:from_code].kit.get_sample_data("snare.wav").length -
       test_songs[:from_code].tick_sample_length).ceil
    assert_equal(test_songs[:from_code].sample_length_with_overflow, test_songs[:from_code].sample_length + snare_overflow)
    snare_overflow =
      (test_songs[:from_valid_yaml_string].kit.get_sample_data("sounds/snare.wav").length -
       test_songs[:from_valid_yaml_string].tick_sample_length).ceil
    assert_equal(test_songs[:from_valid_yaml_string].sample_length_with_overflow, test_songs[:from_valid_yaml_string].sample_length + snare_overflow)
  end
  
  def test_sample_data
    test_songs = generate_test_data()
    
    test_songs.values.each {|song|
      sample_data = song.sample_data("", false)
      assert_equal(sample_data.class, Array)
      assert_equal(sample_data.length, song.sample_length_with_overflow)
      sample_data = song.sample_data("", true)
      assert_equal(sample_data.class, Hash)
    }
    assert_equal(test_songs[:from_code].sample_data("verse", false).class, Array)
    assert_equal(test_songs[:from_code].sample_data("verse", true).class, Hash)
    assert_equal(test_songs[:from_valid_yaml_string].sample_data("verse", false).class, Array)
    assert_equal(test_songs[:from_valid_yaml_string].sample_data("verse", true).class, Hash)
  end
end