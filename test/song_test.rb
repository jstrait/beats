require 'includes'

class SongTest < Minitest::Test
  FIXTURES = [:repeats_not_specified,
              :pattern_with_overflow,
              :example_no_kit,
              :example_with_kit]

  def generate_test_data
    test_songs = {}
    base_path = File.dirname(__FILE__) + "/.."

    test_songs[:blank] = Song.new

    test_songs[:no_flow] = Song.new
    verse_tracks = [
      Track.new("bass.wav",      "X.......X......."),
      Track.new("snare.wav",     "....X.......X..."),
      Track.new("hh_closed.wav", "X.X.X.X.X.X.X.X."),
    ]
    test_songs[:no_flow].pattern(:verse, verse_tracks)

    song_parser = SongParser.new
    FIXTURES.each do |fixture_name|
      test_songs[fixture_name], _ = song_parser.parse(base_path, File.read("test/fixtures/valid/#{fixture_name}.txt"))
    end

    test_songs[:from_code] = Song.new
    verse_tracks = [
      Track.new("bass.wav",      "X.......X......."),
      Track.new("snare.wav",     "....X.......X..."),
      Track.new("hh_closed.wav", "X.X.X.X.X.X.X.X."),
    ]
    test_songs[:from_code].pattern(:verse, verse_tracks)
    chorus_tracks = [
      Track.new("bass.wav",  "X......."),
      Track.new("snare.wav", "....X..X"),
      Track.new("ride.wav",  "X.....X."),
    ]
    test_songs[:from_code].pattern(:chorus, chorus_tracks)
    test_songs[:from_code].flow = [:verse, :chorus, :verse, :chorus, :chorus]

    test_songs
  end

  def test_initialize
    test_songs = generate_test_data

    assert_equal([], test_songs[:blank].flow)
    assert_equal([], test_songs[:no_flow].flow)
    assert_equal([:verse, :chorus, :verse, :chorus, :chorus], test_songs[:from_code].flow)
  end

  def test_tempo=
    song = Song.new

    song.tempo = 150
    assert_equal(150, song.tempo)

    song.tempo = 145.854
    assert_equal(145.854, song.tempo)

    [-1, -1.0, "abc", "150"].each do |invalid_tempo|
      assert_raises(Song::InvalidTempoError) { song.tempo = invalid_tempo }
    end
  end

  def test_pattern
    song = Song.new
    verse1 = song.pattern(:Verse)

    assert_equal(:Verse, verse1.name)
    assert_equal({:Verse => verse1}, song.patterns)

    verse2 = song.pattern(:Verse)
    assert_equal(:Verse, verse2.name)
    assert_equal({:Verse => verse2}, song.patterns)
    refute_equal(verse1, verse2)

    chorus = song.pattern(:Chorus)
    assert_equal(2, song.patterns.length)
    assert_equal({:Chorus => chorus, :Verse => verse2}, song.patterns)

    tracks = [
      Track.new("track1", "X...X..."),
      Track.new("track2", "X..."),
    ]
    tracks_provided = song.pattern(:Tracks_Provided, tracks)
    assert_equal(3, song.patterns.length)
    assert_equal({:Chorus => chorus, :Tracks_Provided => tracks_provided, :Verse => verse2}, song.patterns)
    assert_equal(["track1", "track2"], song.track_names)
    assert_equal(tracks_provided.tracks["track1"].rhythm, "X...X...")
    assert_equal(tracks_provided.tracks["track1"].name, "track1")
    assert_equal(tracks_provided.tracks["track2"].rhythm, "X.......")
    assert_equal(tracks_provided.tracks["track2"].name, "track2")
  end

  def test_total_tracks
    test_songs = generate_test_data

    assert_equal(0, test_songs[:blank].total_tracks)
    assert_equal(3, test_songs[:no_flow].total_tracks)
    assert_equal(3, test_songs[:from_code].total_tracks)
    assert_equal(1, test_songs[:repeats_not_specified].total_tracks)
    assert_equal(1, test_songs[:pattern_with_overflow].total_tracks)
    assert_equal(5, test_songs[:example_no_kit].total_tracks)
    assert_equal(5, test_songs[:example_with_kit].total_tracks)
  end

  def test_track_names
    test_songs = generate_test_data

    assert_equal([], test_songs[:blank].track_names)
    assert_equal(["bass.wav", "hh_closed.wav", "snare.wav"], test_songs[:no_flow].track_names)
    assert_equal(["bass.wav", "hh_closed.wav", "ride.wav", "snare.wav"], test_songs[:from_code].track_names)
    assert_equal(["test/sounds/bass_mono_8.wav"], test_songs[:repeats_not_specified].track_names)
    assert_equal(["test/sounds/snare_mono_8.wav"], test_songs[:pattern_with_overflow].track_names)
    assert_equal(["test/sounds/bass_mono_8.wav",
                  "test/sounds/hh_closed_mono_8.wav",
                  "test/sounds/hh_open_mono_8.wav",
                  "test/sounds/ride_mono_8.wav",
                  "test/sounds/snare_mono_8.wav"],
                  test_songs[:example_no_kit].track_names)
    assert_equal(["bass",
                  "hhclosed",
                  "hhopen",
                  "snare",
                  "test/sounds/hh_closed_mono_8.wav",
                  "test/sounds/ride_mono_8.wav"],
                  test_songs[:example_with_kit].track_names)
  end

  def test_copy_ignoring_patterns_and_flow
    test_songs = generate_test_data
    original_song = test_songs[:example_no_kit]
    cloned_song = original_song.copy_ignoring_patterns_and_flow

    refute_equal(cloned_song, original_song)
    assert_equal(cloned_song.tempo, original_song.tempo)
    assert_equal([], cloned_song.flow)
    assert_equal({}, cloned_song.patterns)
  end

  def test_split
    test_songs = generate_test_data
    split_songs = test_songs[:example_with_kit].split

    assert_equal(Hash, split_songs.class)
    assert_equal(6, split_songs.length)

    song_names = split_songs.keys.sort
    assert_equal(["bass",
                  "hhclosed",
                  "hhopen",
                  "snare",
                  "test/sounds/hh_closed_mono_8.wav",
                  "test/sounds/ride_mono_8.wav"],
                 song_names)

    song_names.each do |song_name|
      song = split_songs[song_name]
      assert_equal(99, song.tempo)
      assert_equal(3, song.patterns.length)
      assert_equal([:verse, :verse, :chorus, :chorus, :verse, :verse, :chorus, :chorus, :chorus, :chorus,
                    :bridge, :chorus, :chorus, :chorus, :chorus],
                   song.flow)

      song.patterns.each do |pattern_name, pattern|
        assert_equal(1, pattern.tracks.length)
        assert_equal([song_name], pattern.tracks.keys)
        assert_equal(song_name, pattern.tracks[song_name].name)
      end
    end
  end

  def test_remove_unused_patterns
    test_songs = generate_test_data

    assert_equal(1, test_songs[:no_flow].patterns.length)
    test_songs[:no_flow].remove_unused_patterns
    assert_equal({}, test_songs[:no_flow].patterns)

    assert_equal(3, test_songs[:example_no_kit].patterns.length)
    test_songs[:example_no_kit].remove_unused_patterns
    assert_equal(3, test_songs[:example_no_kit].patterns.length)
    assert_equal(Hash, test_songs[:example_no_kit].patterns.class)
  end
end
