require 'includes'

class IntegrationTest < Minitest::Test
  TRACK_NAMES =  ["bass", "snare", "hh_closed", "hh_closed2", "agogo", "tom4", "tom2"]
  OUTPUT_FOLDER = "test/integration_output"

  def setup
    # Make sure no output from previous tests is still around
    clean_output_folder
  end

  def test_bad_song_errors
    invalid_fixtures = ["bad_tempo.txt",
                        "flow_invalid_repeat_count_suffix.txt",
                        "flow_non_existent_pattern.txt",
                        "no_header.txt",
                        "no_flow.txt",
                        "sound_in_kit_not_found.txt",
                        "sound_in_track_not_found.txt"]

    invalid_fixtures.each do |fixture_name|
      assert_raises(SongParser::ParseError) do
        beats = BeatsRunner.new("test/fixtures/invalid/#{fixture_name}", "doesn't matter", {:split => false})
        beats.run
      end
    end
  end


  # TODO: Add tests for the -p option
  # TODO: Add test verify that song generated with and without SongOptimizer are identical.

  def test_base_path
    run_combined_test("mono", 16, "_base_path", "test/sounds")
    run_split_test("mono", 16, "_base_path", "test/sounds")
  end

  def test_generate_combined
    run_combined_test("mono",   8)
    run_combined_test("mono",   16)
    run_combined_test("stereo", 8)
    run_combined_test("stereo", 16)
  end

  def run_combined_test(num_channels, bits_per_sample, suffix="", base_path=nil)
    # Make sure no output from previous tests is still around
    assert_directory_is_empty OUTPUT_FOLDER

    song_fixture         = "test/fixtures/valid/example_#{num_channels}_#{bits_per_sample}#{suffix}.txt"
    actual_output_file   = "#{OUTPUT_FOLDER}/example_combined_#{num_channels}_#{bits_per_sample}#{suffix}.wav"
    expected_output_file = "test/fixtures/expected_output/example_combined_#{num_channels}_#{bits_per_sample}.wav"

    options = {:split => false}
    unless base_path == nil
      options[:base_path] = base_path
    end

    beats = BeatsRunner.new(song_fixture, actual_output_file, options)
    beats.run
    assert(File.exist?(actual_output_file), "Expected file '#{actual_output_file}' to exist, but it doesn't.")

    # Reading the files this way instead of a plain File.read() for Windows compatibility with binary files
    expected_output_file_contents = File.open(expected_output_file, "rb") {|f| f.read() }
    actual_output_file_contents = File.open(actual_output_file, "rb") {|f| f.read() }
    assert_equal(expected_output_file_contents, actual_output_file_contents)

    # Clean up after ourselves
    File.delete(actual_output_file)
  end

  def test_generate_split
    run_split_test("mono",    8)
    run_split_test("mono",   16)
    run_split_test("stereo",  8)
    run_split_test("stereo", 16)
  end

  def run_split_test(num_channels, bits_per_sample, suffix="", base_path=nil)
    # Make sure no output from previous tests is still around
    assert_directory_is_empty OUTPUT_FOLDER

    song_fixture         = "test/fixtures/valid/example_#{num_channels}_#{bits_per_sample}#{suffix}.txt"
    actual_output_prefix   = "#{OUTPUT_FOLDER}/example_split_#{num_channels}_#{bits_per_sample}#{suffix}"
    expected_output_prefix = "test/fixtures/expected_output/example_split_#{num_channels}_#{bits_per_sample}"

    options = {:split => true}
    unless base_path == nil
      options[:base_path] = base_path
    end

    beats = BeatsRunner.new(song_fixture, actual_output_prefix + ".wav", options)
    beats.run
    TRACK_NAMES.each do |track_name|
      if(track_name.start_with?("tom"))
        track_name += "_#{num_channels}_#{bits_per_sample}"
      end
      actual_output_file = "#{actual_output_prefix}-#{track_name}.wav"
      expected_output_file = "#{expected_output_prefix}-#{track_name}.wav"
      assert(File.exist?(actual_output_file), "Expected file '#{actual_output_file}' to exist, but it doesn't.")

      # Reading the files this way instead of a plain File.read() for Windows compatibility with binary files
      expected_output_file_contents = File.open(expected_output_file, "rb") {|f| f.read }
      actual_output_file_contents = File.open(actual_output_file, "rb") {|f| f.read }
      assert_equal(expected_output_file_contents, actual_output_file_contents)

      # Clean up after ourselves
      File.delete(actual_output_file)
    end
  end

  def assert_directory_is_empty dir
    assert_equal([".", ".."].sort, Dir.new(dir).entries.sort)
  end

  def clean_output_folder()
    # Make the folder if it doesn't already exist
    Dir.mkdir(OUTPUT_FOLDER) unless File.exist?(OUTPUT_FOLDER)

    dir = Dir.new(OUTPUT_FOLDER)
    file_names = dir.entries
    file_names.each do |file_name|
      if(file_name != "." && file_name != "..")
        File.delete("#{OUTPUT_FOLDER}/#{file_name}")
      end
    end
  end
end
