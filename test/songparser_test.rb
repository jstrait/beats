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

    repeats_not_specified_yaml = "
Song:
  Tempo: 100
  Structure:
    - Verse

Verse:
  - test/sounds/bass_mono_8.wav: X"
    test_songs[:repeats_not_specified] = SongParser.new().parse(File.dirname(__FILE__) + "/..", repeats_not_specified_yaml)

    overflow_yaml = "
Song:
  Tempo: 100
  Structure:
    - Verse: x2

Verse:
  - test/sounds/snare_mono_8.wav: ...X"
    test_songs[:overflow] = SongParser.new().parse(File.dirname(__FILE__) + "/..", overflow_yaml)

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
  - test/sounds/bass_mono_8.wav:      X...X...X...XX..X...X...XX..X...
  - test/sounds/snare_mono_8.wav:     ..X...X...X...X.X...X...X...X...
# Here is a comment
  - test/sounds/hh_closed_mono_8.wav: X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.
  - test/sounds/hh_open_mono_8.wav:   X...............X..............X
# Here is another comment
Chorus:
  - test/sounds/bass_mono_8.wav:      X...X...XXXXXXXXX...X...X...X...
  - test/sounds/snare_mono_8.wav:     ...................X...X...X...X
  - test/sounds/hh_closed_mono_8.wav: X.X.XXX.X.X.XXX.X.X.XXX.X.X.XXX. # It's comment time
  - test/sounds/hh_open_mono_8.wav:   ........X.......X.......X.......
  - test/sounds/ride_mono_8.wav:      ....X...................X.......


Bridge:
  - test/sounds/hh_closed_mono_8.wav: XX.XXX.XXX.XXX.XXX.XXX.XXX.XXX.X"
      test_songs[:from_valid_yaml_string] = SongParser.new().parse(File.dirname(__FILE__) + "/..", valid_yaml_string)

      return test_songs
  end

  def test_valid_initialize
    test_songs = SongParserTest.generate_test_data()
    
    assert_equal(test_songs[:from_valid_yaml_string].structure, [:verse, :verse, :chorus, :chorus, :verse, :verse, :chorus, :chorus, :chorus, :chorus, :bridge, :chorus, :chorus, :chorus, :chorus])
    assert_equal(test_songs[:from_valid_yaml_string].tempo, 99)
    assert_equal(test_songs[:from_valid_yaml_string].tick_sample_length, (Song::SAMPLE_RATE * Song::SECONDS_PER_MINUTE) / 99 / 4.0)
    assert_equal(test_songs[:from_valid_yaml_string].patterns.keys.map{|key| key.to_s}.sort, ["bridge", "chorus", "verse"])
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
      - test/sounds/bass_mono_8.wav:      X...X...X...XX..X...X...XX..X..."
    assert_raise(SongParseError) { song = SongParser.new().parse(File.dirname(__FILE__) + "/..", invalid_tempo_yaml_string) }

    invalid_structure_yaml_string = "# Invalid structure song
    Song:
      Tempo: 100
      Structure:
        - Verse:  x2
        - Chorus: x1

    Verse:
      - test/sounds/bass_mono_8.wav:      X...X...X...XX..X...X...XX..X..."
    assert_raise(SongParseError) { song = SongParser.new().parse(File.dirname(__FILE__) + "/..", invalid_structure_yaml_string) }
    
    invalid_repeats_yaml_string = "    # Invalid structure song
    Song:
      Tempo: 100
      Structure:
        - Verse:  x2a

    Verse:
      - test/sounds/bass_mono_8.wav:      X...X...X...XX..X...X...XX..X..."
    assert_raise(SongParseError) { song = SongParser.new().parse(File.dirname(__FILE__) + "/..", invalid_repeats_yaml_string) }
  end
end