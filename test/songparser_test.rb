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

    no_tempo_yaml = "
Song:
  Structure:
    - Verse: x1

Verse:
  - test/sounds/bass_mono_8.wav: X"
    test_songs[:no_tempo] = SongParser.new().parse(base_path, no_tempo_yaml)

    repeats_not_specified_yaml = "
Song:
  Tempo: 100
  Structure:
    - Verse

Verse:
  - test/sounds/bass_mono_8.wav: X"
    test_songs[:repeats_not_specified] = SongParser.new().parse(base_path, repeats_not_specified_yaml)

    overflow_yaml = "
Song:
  Tempo: 100
  Structure:
    - Verse: x2

Verse:
  - test/sounds/snare_mono_8.wav: ...X"
    test_songs[:overflow] = SongParser.new().parse(base_path, overflow_yaml)

    valid_yaml_string = "# An example song
  
Song:
  Tempo: 99
  Structure:
    - Verse:     x2
    - Chorus:    x2
    - Verse:     x2
    - Chorus:    x4
    - Bridge:    x1
    - Undefined: x0  # This is legal as long as num repeats is 0.
    - Chorus:    x4

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
    test_songs[:from_valid_yaml_string] = SongParser.new().parse(base_path, valid_yaml_string)

    valid_yaml_string_with_kit = "# An example song

Song:
  Tempo: 99
  Kit:
    - bass:     test/sounds/bass_mono_8.wav
    - snare:    test/sounds/snare_mono_8.wav
    - hhclosed: test/sounds/hh_closed_mono_8.wav
    - hhopen:   test/sounds/hh_open_mono_8.wav
  Structure:
    - Verse:  x2
    - Chorus: x2
    - Verse:  x2
    - Chorus: x4
    - Bridge: x1
    - Undefined: x0  # This is legal as long as num repeats is 0.
    - Chorus: x4

Verse:
  - bass:      X...X...X...XX..X...X...XX..X...
  - snare:     ..X...X...X...X.X...X...X...X...
# Here is a comment
  - hhclosed:  X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.
  - hhopen:    X...............X..............X
# Here is another comment
Chorus:
  - bass:      X...X...XXXXXXXXX...X...X...X...
  - snare:     ...................X...X...X...X
  - test/sounds/hh_closed_mono_8.wav: X.X.XXX.X.X.XXX.X.X.XXX.X.X.XXX. # It's comment time
  - hhopen:    ........X.......X.......X.......
  - test/sounds/ride_mono_8.wav:      ....X...................X.......

Bridge:
  - hhclosed: XX.XXX.XXX.XXX.XXX.XXX.XXX.XXX.X"
    test_songs[:from_valid_yaml_string_with_kit] = SongParser.new().parse(base_path, valid_yaml_string_with_kit)

    valid_yaml_string_with_empty_track = "# An song which has a track with no rhythm
  
Song:
  Tempo: 99
  Structure:
    - Verse:     x1

Verse:
  - test/sounds/bass_mono_8.wav:
  - test/sounds/snare_mono_8.wav: X...X..."
    test_songs[:from_valid_yaml_string_with_empty_track] = SongParser.new().parse(base_path, valid_yaml_string_with_empty_track)

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
    [:from_valid_yaml_string, :from_valid_yaml_string_with_kit].each {|song_key|
      song = test_songs[song_key]
      assert_equal(song.structure, [:verse, :verse, :chorus, :chorus, :verse, :verse, :chorus, :chorus, :chorus, :chorus, :bridge, :chorus, :chorus, :chorus, :chorus])
      assert_equal(song.tempo, 99)
      assert_equal(song.tick_sample_length, (Song::SAMPLE_RATE * Song::SECONDS_PER_MINUTE) / 99 / 4.0)
      assert_equal(song.patterns.keys.map{|key| key.to_s}.sort, ["bridge", "chorus", "verse"])
      assert_equal(song.patterns[:verse].tracks.length, 4)
      assert_equal(song.patterns[:chorus].tracks.length, 5)
      assert_equal(song.patterns[:bridge].tracks.length, 1)
    }
    
    song = test_songs[:from_valid_yaml_string_with_empty_track]
    assert_equal(1, song.patterns.length)
    assert_equal(2, song.patterns[:verse].tracks.length)
    assert_equal("........", song.patterns[:verse].tracks["test/sounds/bass_mono_8.wav"].rhythm)
    assert_equal("X...X...", song.patterns[:verse].tracks["test/sounds/snare_mono_8.wav"].rhythm)
  end
  
  def test_invalid_parse
    no_header_yaml_string = "# Song with no header
    Verse:
      - test/sounds/bass_mono_8.wav:      X...X...X...XX..X...X...XX..X..."
    assert_raise(SongParseError) { song = SongParser.new().parse(File.dirname(__FILE__) + "/..", no_header_yaml_string) }
    
    sound_doesnt_exist_yaml_string = "# Song with non-existent sound
    Song:
      Tempo: 100
      Structure:
        - Verse: x1
        
    Verse:
      - test/sounds/i_do_not_exist.wav: X...X..."
    assert_raise(SongParseError) { song = SongParser.new().parse(File.dirname(__FILE__) + "/..", sound_doesnt_exist_yaml_string) }
    
    
    sound_doesnt_exist_in_kit_yaml_string = "# Song with non-existent sound in Kit
    Song:
      Tempo: 100
      Structure:
        - Verse: x1
      Kit:
        - bad: test/sounds/i_do_not_exist.wav
      
    Verse:
      - bad: X...X..."
    assert_raise(SongParseError) { song = SongParser.new().parse(File.dirname(__FILE__) + "/..", sound_doesnt_exist_in_kit_yaml_string) }
    
    invalid_tempo_yaml_string = "# Song with invalid tempo
    Song:
      Tempo: 100a
      Structure:
        - Verse:  x2

    Verse:
      - test/sounds/bass_mono_8.wav:      X...X...X...XX..X...X...XX..X..."
    assert_raise(SongParseError) { song = SongParser.new().parse(File.dirname(__FILE__) + "/..", invalid_tempo_yaml_string) }

    invalid_structure_yaml_string = "# Song whose structure references non-existent pattern
    Song:
      Tempo: 100
      Structure:
        - Verse:  x2
        - Chorus: x1

    Verse:
      - test/sounds/bass_mono_8.wav:      X...X...X...XX..X...X...XX..X..."
    assert_raise(SongParseError) { song = SongParser.new().parse(File.dirname(__FILE__) + "/..", invalid_structure_yaml_string) }
    
    no_structure_yaml_string = "# Song without a structure section in the header
    Song:
      Tempo: 100

    Verse:
      - test/sounds/bass_mono_8.wav:      X...X...X...XX..X...X...XX..X..."
    assert_raise(SongParseError) { song = SongParser.new().parse(File.dirname(__FILE__) + "/..", no_structure_yaml_string) }
    
    invalid_repeats_yaml_string = "# Song with invalid number of repeats for pattern
    Song:
      Tempo: 100
      Structure:
        - Verse:  x2a

    Verse:
      - test/sounds/bass_mono_8.wav:      X...X...X...XX..X...X...XX..X..."
    assert_raise(SongParseError) { song = SongParser.new().parse(File.dirname(__FILE__) + "/..", invalid_repeats_yaml_string) }
  end
end