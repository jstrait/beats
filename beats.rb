require 'optparse'
require 'yaml'
require 'wavefile'
require 'lib/song.rb'
require 'lib/kit.rb'
require 'lib/pattern.rb'
require 'lib/track.rb'

def parse_options
  options = {:split => false, :pattern => ""}

  optparse = OptionParser.new do |opts|
    opts.on( '-h', '--help', 'Display this screen' ) do
      puts opts
      exit
    end

    opts.on('-s', '--split', "Save an individual wave file for each track") do
      options[:split] = true
    end

    opts.on('-p', '--pattern NAME', "Output a single pattern instead of the whole song" ) do|p|
      options[:pattern] = p
    end
  end
  optparse.parse!
  
  return options
end

def save_wave_file(file_name, num_channels, bits_per_sample, sample_data)
  output = WaveFile.new(num_channels, 44100, bits_per_sample)
  output.sample_data = sample_data  
  output.save(file_name)
end

start = Time.now

options = parse_options
input_file = ARGV[0]
output_file = ARGV[1]

begin
  parse_start_time = Time.now
  song_from_file = Song.new(YAML.load_file(input_file))
  kit = song_from_file.kit
  puts "Song parse time: #{Time.now - parse_start_time}"

  generate_samples_start = Time.now
  sample_data = song_from_file.sample_data(options[:pattern], options[:split])
  puts "Time to generate sample data: #{Time.now - generate_samples_start}"

  wave_write_start = Time.now
  if(options[:split])
    sample_data.keys.each {|track_name|
      extension = File.extname(output_file)
      file_name = File.basename(output_file, extension) + "-" + File.basename(track_name.to_s, extension) + extension
    
      save_wave_file(file_name, kit.num_channels, kit.bits_per_sample, sample_data[track_name])
    }
  else
    save_wave_file(output_file, kit.num_channels, kit.bits_per_sample, sample_data)
  end
  puts "Time to write wave file(s): #{Time.now - wave_write_start}"
rescue SongParseError => detail
  puts ""
  puts "Song file #{input_file} has an error:"
  puts "  #{detail}"
  puts ""
end

#puts "Total run time: #{Time.now - start}"
