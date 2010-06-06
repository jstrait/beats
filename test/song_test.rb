$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class SongTest < Test::Unit::TestCase
  DEFAULT_TEMPO = 120
  
  def generate_test_data
    kit = Kit.new("test/sounds")
    kit.add("bass.wav",      "bass_mono_8.wav")
    kit.add("snare.wav",     "snare_mono_8.wav")
    kit.add("hh_closed.wav", "hh_closed_mono_8.wav")
    kit.add("ride.wav",      "ride_mono_8.wav")
    
    test_songs = {}
    base_path = File.dirname(__FILE__) + "/.."

    test_songs[:blank] = Song.new(base_path)
    
    test_songs[:no_structure] = Song.new(base_path)
    verse = test_songs[:no_structure].pattern :verse
    verse.track "bass.wav",      kit.get_sample_data("bass.wav"),      "X.......X......."
    verse.track "snare.wav",     kit.get_sample_data("snare.wav"),     "....X.......X..."
    verse.track "hh_closed.wav", kit.get_sample_data("hh_closed.wav"), "X.X.X.X.X.X.X.X."
    
    test_songs[:repeats_not_specified] = SongParser.new().parse(base_path, YAML.load_file("test/fixtures/valid/repeats_not_specified.txt"))
    test_songs[:overflow] = SongParser.new().parse(base_path, YAML.load_file("test/fixtures/valid/pattern_with_overflow.txt"))
    test_songs[:from_valid_yaml_string] = SongParser.new().parse(base_path, YAML.load_file("test/fixtures/valid/example_no_kit.txt"))
    test_songs[:from_valid_yaml_string_with_kit] = SongParser.new().parse(base_path, YAML.load_file("test/fixtures/valid/example_with_kit.txt"))
    
    test_songs[:from_code] = Song.new(base_path)
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
    
    return test_songs
  end
    
  def test_initialize
    test_songs = generate_test_data()
    
    assert_equal([], test_songs[:blank].structure)
    assert_equal((Song::SAMPLE_RATE * Song::SECONDS_PER_MINUTE) / DEFAULT_TEMPO / 4.0,
                 test_songs[:blank].tick_sample_length)
    
    assert_equal([], test_songs[:no_structure].structure)
    assert_equal((Song::SAMPLE_RATE * Song::SECONDS_PER_MINUTE) / DEFAULT_TEMPO / 4.0,
                 test_songs[:no_structure].tick_sample_length)
    
    assert_equal([:verse, :chorus, :verse, :chorus, :chorus], test_songs[:from_code].structure)
    assert_equal((Song::SAMPLE_RATE * Song::SECONDS_PER_MINUTE) / DEFAULT_TEMPO / 4.0,
                 test_songs[:from_code].tick_sample_length)
  end
  
  def test_total_tracks
    test_songs = generate_test_data()
    
    assert_equal(0, test_songs[:blank].total_tracks)
    assert_equal(3, test_songs[:no_structure].total_tracks)
    assert_equal(3, test_songs[:from_code].total_tracks)
    assert_equal(1, test_songs[:repeats_not_specified].total_tracks)
    assert_equal(1, test_songs[:overflow].total_tracks)
    assert_equal(5, test_songs[:from_valid_yaml_string].total_tracks)
  end
  
  def test_track_names
    test_songs = generate_test_data()
    
    assert_equal([], test_songs[:blank].track_names)
    assert_equal(["bass.wav", "hh_closed.wav", "snare.wav"], test_songs[:no_structure].track_names)
    assert_equal(["bass.wav", "hh_closed.wav", "ride.wav", "snare.wav"], test_songs[:from_code].track_names)
    assert_equal(["test/sounds/bass_mono_8.wav"], test_songs[:repeats_not_specified].track_names)
    assert_equal(["test/sounds/snare_mono_8.wav"], test_songs[:overflow].track_names)
    assert_equal(["test/sounds/bass_mono_8.wav",
                  "test/sounds/hh_closed_mono_8.wav",
                  "test/sounds/hh_open_mono_8.wav",
                  "test/sounds/ride_mono_8.wav",
                  "test/sounds/snare_mono_8.wav"],
                  test_songs[:from_valid_yaml_string].track_names)
  end
  
  def test_sample_length
    test_songs = generate_test_data()

    assert_equal(0, test_songs[:blank].sample_length)
    assert_equal(0, test_songs[:no_structure].sample_length)
    
    assert_equal((test_songs[:from_code].tick_sample_length * 16 * 2) +
                     (test_songs[:from_code].tick_sample_length * 8 * 3),
                 test_songs[:from_code].sample_length)
                            
    assert_equal(test_songs[:repeats_not_specified].tick_sample_length,
                 test_songs[:repeats_not_specified].sample_length)
                            
    assert_equal(test_songs[:overflow].tick_sample_length * 8, test_songs[:overflow].sample_length)
  end
  
  def test_sample_length_with_overflow
    test_songs = generate_test_data()
    
    assert_equal(0, test_songs[:blank].sample_length_with_overflow)
    assert_equal(0, test_songs[:no_structure].sample_length_with_overflow)
    
    snare_overflow =
      (test_songs[:from_code].kit.get_sample_data("snare.wav").length -
       test_songs[:from_code].tick_sample_length).ceil   
    assert_equal(test_songs[:from_code].sample_length + snare_overflow, test_songs[:from_code].sample_length_with_overflow)    
    
    assert_equal(test_songs[:repeats_not_specified].tick_sample_length,
                 test_songs[:repeats_not_specified].sample_length_with_overflow)
    
    snare_overflow =
      (test_songs[:overflow].kit.get_sample_data("test/sounds/snare_mono_8.wav").length -
       test_songs[:overflow].tick_sample_length).ceil
    assert_equal((test_songs[:overflow].tick_sample_length * 8) + snare_overflow,
                 test_songs[:overflow].sample_length_with_overflow)
    
    snare_overflow =
      (test_songs[:from_valid_yaml_string].kit.get_sample_data("test/sounds/snare_mono_8.wav").length -
       test_songs[:from_valid_yaml_string].tick_sample_length).ceil
    assert_equal(test_songs[:from_valid_yaml_string].sample_length + snare_overflow,
                 test_songs[:from_valid_yaml_string].sample_length_with_overflow)
  end
  
  # Since the sample_data() method is gone (replaced by write_to_file()), these tests no longer work.
  # Keeping this code around though until it can be replaced by equivalent integration tests for
  # write_to_file().
  #def test_sample_data
  #  test_songs = generate_test_data()
  #  
  # test_songs.values.each do |song|
  #    sample_data = song.sample_data(false)
  #    assert_equal(Array, sample_data.class)
  #    assert_equal(song.sample_length_with_overflow, sample_data.length)
  #    sample_data = song.sample_data(true)
  #    assert_equal(Hash, sample_data.class)
  #  end
  #  
  #  [:from_code, :repeats_not_specified, :overflow, :from_valid_yaml_string].each do |key|
  #    assert_equal(Array, test_songs[key].sample_data(false, "verse").class)
  #    assert_equal(Hash, test_songs[key].sample_data(true, "verse").class)
  #  end
  #  
  #  #assert_raise(ArgumentError) { test_songs[:from_valid_yaml_string].sample_data(true, "") }
  #  
  #  snare_sample_data = test_songs[:overflow].kit.get_sample_data("test/sounds/snare_mono_8.wav")
  #  expected = [].fill(0, 0, test_songs[:overflow].tick_sample_length * 4)
  #  expected[0...(snare_sample_data.length)] = snare_sample_data
  #  expected += snare_sample_data
  #  expected = [].fill(0, 0, test_songs[:overflow].tick_sample_length * 3) + expected
  #  assert_equal(expected[0], test_songs[:overflow].sample_data(false)[0])
  #end
  
  def test_copy_ignoring_patterns_and_structure
    test_songs = generate_test_data()
    original_song = test_songs[:from_valid_yaml_string]
    cloned_song = original_song.copy_ignoring_patterns_and_structure()
    
    assert_not_equal(cloned_song, original_song)
    assert_equal(cloned_song.tempo, original_song.tempo)
    assert_equal(cloned_song.kit, original_song.kit)
    assert_equal(cloned_song.tick_sample_length, original_song.tick_sample_length)
    assert_equal([], cloned_song.structure)
    assert_equal({}, cloned_song.patterns)
  end
  
  def test_remove_unused_patterns
    test_songs = generate_test_data()
    
    assert_equal(1, test_songs[:no_structure].patterns.length)
    test_songs[:no_structure].remove_unused_patterns()
    assert_equal({}, test_songs[:no_structure].patterns)
    
    assert_equal(3, test_songs[:from_valid_yaml_string].patterns.length)
    test_songs[:from_valid_yaml_string].remove_unused_patterns()
    assert_equal(3, test_songs[:from_valid_yaml_string].patterns.length)
    assert_equal(Hash, test_songs[:from_valid_yaml_string].patterns.class)
  end
  
  def test_to_yaml
    test_songs = generate_test_data()
    result = test_songs[:from_valid_yaml_string_with_kit].to_yaml
    
    assert_equal(
"Song:
  Tempo: 99
  Structure:
    - Verse:   x2
    - Chorus:  x2
    - Verse:   x2
    - Chorus:  x4
    - Bridge:  x1
    - Chorus:  x4
  Kit:
    - bass:      test/sounds/bass_mono_8.wav
    - hhclosed:  test/sounds/hh_closed_mono_8.wav
    - hhopen:    test/sounds/hh_open_mono_8.wav
    - snare:     test/sounds/snare_mono_8.wav

Bridge:
  - hhclosed:  XX.XXX.XXX.XXX.XXX.XXX.XXX.XXX.X

Chorus:
  - bass:                              X...X...XXXXXXXXX...X...X...X...
  - hhopen:                            ........X.......X.......X.......
  - snare:                             ...................X...X...X...X
  - test/sounds/hh_closed_mono_8.wav:  X.X.XXX.X.X.XXX.X.X.XXX.X.X.XXX.
  - test/sounds/ride_mono_8.wav:       ....X...................X.......

Verse:
  - bass:      X...X...X...XX..X...X...XX..X...
  - hhclosed:  X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.
  - hhopen:    X...............X..............X
  - snare:     ..X...X...X...X.X...X...X...X...
",
      result)
  end
end