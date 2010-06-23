class Beats
  BEATS_VERSION = "1.2.0a"
  SAMPLE_RATE = 44100
  OPTIMIZED_PATTERN_LENGTH = 4

  def initialize(input_file_name, output_file_name, options)
    @input_file_name =  input_file_name
    @output_file_name = output_file_name
    @options = options
  end

  def run
    if(@input_file_name == nil)
      ARGV[0] = '-h'
      parse_options()
    end

    if(@output_file_name == nil)
      @output_file_name = File.basename(@input_file_name, File.extname(@input_file_name)) + ".wav"
    end

    song_parser = SongParser.new()
    song = song_parser.parse(File.dirname(@input_file_name), YAML.load_file(@input_file_name))
    song_optimizer = SongOptimizer.new()

    if(@options[:pattern] != nil)
      pattern_name = @options[:pattern].downcase.to_sym
      if(!song.patterns.member?(pattern_name))
        raise StandardError, "The song does not include a pattern called #{@options[:pattern]}"
      end
      
      song.structure = [pattern_name]
      song.remove_unused_patterns()
    end

    duration = nil
    if(@options[:split])
      song_splitter = SongSplitter.new()
      split_songs = song_splitter.split(song)
      split_songs.each do |track_name, split_song|
        split_song = song_optimizer.optimize(split_song, OPTIMIZED_PATTERN_LENGTH)

        # TODO: Move building the output file name into its own method?
        extension = File.extname(@output_file_name)
        file_name = File.dirname(@output_file_name) + "/" +
                    File.basename(@output_file_name, extension) + "-" + File.basename(track_name, extension) +
                    extension
        duration = split_song.write_to_file(file_name)
      end
    else
      song = song_optimizer.optimize(song, OPTIMIZED_PATTERN_LENGTH)
      duration = song.write_to_file(@output_file_name)
    end

    return {:duration => duration}
  end
end