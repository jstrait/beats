$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class SongParserTest < Test::Unit::TestCase
  DEFAULT_OPTIONS = {:split => false, :pattern => nil}
  OUTPUT_FOLDER = "test/integration_output"
  
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
    
    song_fixture         ="test/fixtures/valid/example_#{num_channels}_#{bits_per_sample}.txt"
    actual_output_file   = "test/integration_output/example_combined_#{num_channels}_#{bits_per_sample}.wav"
    expected_output_file = "test/fixtures/expected_output/example_combined_#{num_channels}_#{bits_per_sample}.wav"
    
    beats = Beats.new(song_fixture,
                      actual_output_file,
                      {:split => false, :pattern => nil})
    beats.run()
    assert(File.exists?(actual_output_file))
    assert_equal(File.read(actual_output_file), File.read(expected_output_file))
    
    # Clean up after ourselves
    File.delete(actual_output_file)
  end
  
  def clean_output_folder()
    dir = Dir.new(OUTPUT_FOLDER)
    file_names = dir.entries
    file_names.each do |file_name|
      if(file_name != "." && file_name != "..")
        File.delete("#{OUTPUT_FOLDER}/#{file_name}")
      end
    end
  end
end