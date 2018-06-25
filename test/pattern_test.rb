require 'includes'

class PatternTest < Minitest::Test
  SAMPLE_RATE = 44100
  SECONDS_IN_MINUTE = 60.0

  def generate_test_data
    test_patterns = {}

    pattern = Pattern.new :blank
    test_patterns[:blank] = pattern

    verse_tracks = [
      Track.new("bass.wav",      "X...X...X...XX..X...X...XX..X..."),
      Track.new("snare.wav",     "..X...X...X...X.X...X...X...X..."),
      Track.new("hh_closed.wav", "X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.X."),
      Track.new("hh_open.wav",   "X...............X..............X"),
    ]
    pattern = Pattern.new(:verse, verse_tracks)
    test_patterns[:verse] = pattern

    staircase_tracks = [
      Track.new("bass.wav",      "X..."),
      Track.new("snare.wav",     "X.."),
      Track.new("hh_closed.wav", "X."),
    ]
    pattern = Pattern.new(:staircase, staircase_tracks)
    test_patterns[:staircase] = pattern

    test_patterns
  end

  def test_initialize
    test_patterns = generate_test_data

    pattern = test_patterns[:blank]
    assert_equal(pattern.name, :blank)
    assert_equal(pattern.tracks.length, 0)

    pattern = test_patterns[:verse]
    assert_equal(pattern.name, :verse)
    assert_equal(pattern.tracks.length, 4)

    pattern = test_patterns[:staircase]
    assert_equal(pattern.name, :staircase)
    assert_equal(pattern.tracks.length, 3)

    tracks = [
      Track.new(:track1, "X...X..."),
      Track.new(:track2, "X..."),
    ]
    pattern = Pattern.new(:tracks_provided_in_constructor, tracks)
    assert_equal(pattern.name, :tracks_provided_in_constructor)
    assert_equal(pattern.tracks.length, 2)
    assert_pattern_tracks(pattern, {:track1 => {name: :track1, rhythm: "X...X..."},
                                    :track2  => {name: :track2,  rhythm: "X......."}})

    tracks = [
      Track.new("my_sound", "X...X..."),
      Track.new("my_other_sound", "X..."),
      Track.new("my_sound", ".X.........."),
      Track.new("my_sound2", "..X........."),
      Track.new("my_sound", ".."),
    ]
    pattern = Pattern.new("whatevs", tracks)

    assert_pattern_tracks(pattern, {"my_sound"       => {name: "my_sound",       rhythm: "X...X......."},
                                    "my_other_sound" => {name: "my_other_sound", rhythm: "X..........."},
                                    "my_sound2"      => {name: "my_sound",       rhythm: ".X.........."},
                                    "my_sound22"     => {name: "my_sound2",      rhythm: "..X........."},
                                    "my_sound3"      => {name: "my_sound",       rhythm: "............"},})
  end

  def test_track_array_is_frozen
    tracks = [
      Track.new("my_sound1", "X...X..."),
      Track.new("my_sound2", "X.X.X.X."),
      Track.new("my_sound3", "XXXXXXXX"),
    ]
    pattern = Pattern.new("whatevs", tracks)

    assert_raises(RuntimeError) { pattern.tracks["my_sound4"] = Track.new("my_sound4", "X...X...") }
  end

  def test_track_unique_name_already_taken
    tracks = [
      Track.new("my_sound2", "X...X..."),
      Track.new("my_sound",  "X.X.X.X."),
      Track.new("my_sound",  "XXXXXXXX"),
    ]
    pattern = Pattern.new("whatevs", tracks)

    assert_pattern_tracks(pattern, {"my_sound2" => {name: "my_sound2", rhythm: "X...X..."},
                                    "my_sound"  => {name: "my_sound",  rhythm: "X.X.X.X."},
                                    # The first attempt at a unique name would be "my_sound2", but that is already taken
                                    "my_sound3" => {name: "my_sound",  rhythm: "XXXXXXXX"}})
  end

  def test_step_count
    test_patterns = generate_test_data

    assert_equal(0,  test_patterns[:blank].step_count)
    assert_equal(32, test_patterns[:verse].step_count)
    assert_equal(4,  test_patterns[:staircase].step_count)
  end

  def test_same_tracks_as?
    left_tracks = [
      Track.new("bass",      "X...X..."),
      Track.new("snare",     "..X...X."),
      Track.new("hh_closed", "X.X.X.X."),
    ]
    left_pattern = Pattern.new("left", left_tracks)

    right_tracks = [
      Track.new("bass",      "X...X..."),
      Track.new("snare",     "..X...X."),
      Track.new("hh_closed", "X.X.X.X."),
    ]
    right_pattern = Pattern.new("right", right_tracks)
    assert(left_pattern.same_tracks_as?(right_pattern))
    assert(right_pattern.same_tracks_as?(left_pattern))

    # Now switch up the order. Left and right should still be equal.
    right_tracks = [
      Track.new("snare",     "..X...X."),
      Track.new("hh_closed", "X.X.X.X."),
      Track.new("bass",      "X...X..."),
    ]
    right_pattern = Pattern.new("right", right_tracks)
    assert(left_pattern.same_tracks_as?(right_pattern))
    assert(right_pattern.same_tracks_as?(left_pattern))

    # Now compare the pattern with same rhythms but different track names. Should not be equal.
    different_names_tracks = [
      Track.new("tom",     "X...X..."),
      Track.new("cymbal",  "..X...X."),
      Track.new("hh_open", "X.X.X.X."),
    ]
    different_names_pattern = Pattern.new("different_names", different_names_tracks)
    assert_equal(false, left_pattern.same_tracks_as?(different_names_pattern))
    assert_equal(false, different_names_pattern.same_tracks_as?(left_pattern))

    # Now compare the pattern with same track names but different rhythms. Should not be equal.
    different_beats_tracks = [
      Track.new("bass",      "X...X..."),
      Track.new("snare",     "..X...X."),
      Track.new("hh_closed", "X.XXX.X."),
    ]
    different_beats_pattern = Pattern.new("different_beats", different_beats_tracks)
    assert_equal(false, left_pattern.same_tracks_as?(different_beats_pattern))
    assert_equal(false, different_beats_pattern.same_tracks_as?(left_pattern))

    # Now compare a pattern with the same tracks, but with one extra one as well. Should not be equal.
    something_extra_tracks = [
      Track.new("bass",      "X...X..."),
      Track.new("snare",     "..X...X."),
      Track.new("hh_closed", "X.X.X.X."),
      Track.new("extra",     "X..X..X."),
    ]
    something_extra = Pattern.new("something_extra", something_extra_tracks)
    assert_equal(false, left_pattern.same_tracks_as?(something_extra))
    assert_equal(false, something_extra.same_tracks_as?(left_pattern))
  end

  private

  def assert_pattern_tracks(pattern, expected_pattern_structure)
    assert_equal(expected_pattern_structure.keys, pattern.tracks.keys)

    expected_pattern_structure.each do |pattern_key, expected_track|
      assert_equal(expected_track[:name],   pattern.tracks[pattern_key].name)
      assert_equal(expected_track[:rhythm], pattern.tracks[pattern_key].rhythm)
    end
  end
end
