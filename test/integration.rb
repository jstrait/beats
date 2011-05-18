$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class SongParserTest < Test::Unit::TestCase
  TRACK_NAMES =  ["bass", "snare", "hh_closed", "hh_closed2", "agogo", "tom4", "tom2"]
  OUTPUT_FOLDER = "test/integration_output"
  
  def test_bad_song_errors
    invalid_fixtures = ["bad_tempo.txt",
                        "bad_repeat_count.txt",
                        "bad_flow.txt",
                        "no_header.txt",
                        "no_flow.txt",
                        "sound_in_kit_not_found.txt",
                        "sound_in_track_not_found.txt"]
        
    invalid_fixtures.each do |fixture_name|
      assert_raise(SongParseError) do
        beats = Beats.new("test/fixtures/invalid/#{fixture_name}", "doesn't matter", {:split => false, :pattern => nil})
        beats.run()
      end
    end
  end
  
  
  # TODO: Add tests for the -p option
  # TODO: Add test verify that song generated with and without SongOptimizer are identical.
  
  def test_generate_combined
    # Make sure no output from previous tests is still around
    clean_output_folder()
    
    run_combined_test("mono",   8)
    run_combined_test("mono",   16)
    run_combined_test("stereo", 8)
    run_combined_test("stereo", 16)
  end
  
  def run_combined_test(num_channels, bits_per_sample)
    # Make sure no output from previous tests is still around
    assert_equal([".", ".."], Dir.new(OUTPUT_FOLDER).entries)
    
    song_fixture         = "test/fixtures/valid/example_#{num_channels}_#{bits_per_sample}.txt"
    actual_output_file   = "#{OUTPUT_FOLDER}/example_combined_#{num_channels}_#{bits_per_sample}.wav"
    expected_output_file = "test/fixtures/expected_output/example_combined_#{num_channels}_#{bits_per_sample}.wav"
    
    beats = Beats.new(song_fixture, actual_output_file, {:split => false, :pattern => nil})
    beats.run()
    assert(File.exists?(actual_output_file), "Expected file '#{actual_output_file}' to exist, but it doesn't.")
    assert_equal(File.read(expected_output_file), File.read(actual_output_file))
    
    # Clean up after ourselves
    File.delete(actual_output_file)
  end
  
  def test_generate_split
    # Make sure no output from previous tests is still around
    clean_output_folder()
    
    run_split_test("mono",    8)
    run_split_test("mono",   16)
    run_split_test("stereo",  8)
    run_split_test("stereo", 16)
  end
  
  def run_split_test(num_channels, bits_per_sample)
    # Make sure no output from previous tests is still around
    assert_equal([".", ".."], Dir.new(OUTPUT_FOLDER).entries)
    
    song_fixture         = "test/fixtures/valid/example_#{num_channels}_#{bits_per_sample}.txt"
    actual_output_prefix   = "#{OUTPUT_FOLDER}/example_split_#{num_channels}_#{bits_per_sample}"
    expected_output_prefix = "test/fixtures/expected_output/example_split_#{num_channels}_#{bits_per_sample}"
    
    beats = Beats.new(song_fixture, actual_output_prefix + ".wav", {:split => true, :pattern => nil})
    beats.run()
    TRACK_NAMES.each do |track_name|
      if(track_name.start_with?("tom"))
        track_name += "_#{num_channels}_#{bits_per_sample}"
      end
      actual_output_file = "#{actual_output_prefix}-#{track_name}.wav"
      expected_output_file = "#{expected_output_prefix}-#{track_name}.wav"
      assert(File.exists?(actual_output_file), "Expected file '#{actual_output_file}' to exist, but it doesn't.")
      assert_equal(File.read(expected_output_file), File.read(actual_output_file))
      
      # Clean up after ourselves
      File.delete(actual_output_file)
    end
  end
  
  def clean_output_folder()
    # Make the folder if it doesn't already exist
    unless File.directory? OUTPUT_FOLDER	
      Dir.mkdir(OUTPUT_FOLDER)
    end
    
    dir = Dir.new(OUTPUT_FOLDER)
    file_names = dir.entries
    file_names.each do |file_name|
      if(file_name != "." && file_name != "..")
        File.delete("#{OUTPUT_FOLDER}/#{file_name}")
      end
    end
  end
end
