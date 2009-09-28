require 'optparse'
require 'yaml'
require 'lib/track'
require 'lib/pattern'
require 'lib/song'

start = Time.now

def build_sample_song()
  song = Song.new()
  
  verse = song.pattern :verse
  verse.track "bass.wav",   "X...X...X...XX..X...X...XX..X..."
  verse.track "snare.wav",  "..X...X...X...X.X...X...X...X..."
  verse.track "hihat.wav",  "X.X.X.X.X.X.X.X.X.X.X.X.X.X.X.X."
  verse.track "cymbal.wav", "X...............X..............X"

  chorus = song.pattern :chorus
  chorus.track "bass.wav",   "X...X...XXXXXXXXX...X...X...X..."
  chorus.track "snare.wav",  "...................X...X...X...X"
  chorus.track "hihat.wav",  "X.X.XXX.X.X.XXX.X.X.XXX.X.X.XXX."
  chorus.track "cymbal.wav", "........X.......X.......X......."
  chorus.track "sine.wav",   "....X...................X......."

  bridge = song.pattern :bridge
  bridge.track "hihat.wav",  "XX.XXX.XXX.XXXX.XX.XXX.XXX.XXXX."

  song.tempo = 98
  song.structure = [:verse, :chorus, :verse, :chorus, :bridge, :chorus, :chorus]
  return song
end

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

def save_wave_file(file_name, sample_data)
  output = WaveFile.new(:stereo, 44100, 16)
  
  conversion_start = Time.now
  output.sample_data = sample_data
  puts "Time to convert normalized samples #{file_name}: #{Time.now - conversion_start}"
  
  wave_write_start = Time.now
  output.save(file_name)
  puts "Time to write #{file_name}: #{Time.now - wave_write_start}"
end

options = parse_options
input_file = ARGV[0]
output_file = ARGV[1]

song_from_code = build_sample_song()
begin
  song_from_file = Song.new(YAML.load_file(input_file))
rescue => detail
  puts "Error in #{input_file}:"
  puts "    #{detail.message}"
  exit(1)
end

generate_samples_start = Time.now
normalized_samples = song_from_file.sample_data(options[:pattern], options[:split])
puts "Time to generate sample data: #{Time.now - generate_samples_start}"

if(options[:split])  
  normalized_samples.keys.each {|track_name|
    extension = File.extname(output_file)
    file_name = File.basename(output_file, extension) + "-" + track_name.to_s + extension
    
    save_wave_file(file_name, normalized_samples[track_name])
  }
else
  save_wave_file(output_file, normalized_samples)
end

puts "Run time: #{Time.now - start}"