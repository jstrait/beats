class Beats
  BEATS_VERSION = "1.2.1a"
  
  # Each pattern in the song will be split up into sub patterns that have at most this many steps.
  # In general, audio for several shorter patterns can be generated more quickly than for one long
  # pattern, and can also be cached more effectively.
  OPTIMIZED_PATTERN_LENGTH = 4

  def initialize(input_file_name, output_file_name, options)
    @input_file_name =  input_file_name
    @output_file_name = output_file_name
    @options = options
  end

  def run
    if @input_file_name == nil
      ARGV[0] = '-h'
      parse_options()
    end

    if @output_file_name == nil
      @output_file_name = File.basename(@input_file_name, File.extname(@input_file_name)) + ".wav"
    end

    song_parser = SongParser.new()
    song, kit = song_parser.parse(File.dirname(@input_file_name), File.read(@input_file_name))
    song_optimizer = SongOptimizer.new()

    # If the -p option is used, transform the song into one whose flow consists of
    # playing that single pattern once.
    unless @options[:pattern] == nil
      pattern_name = @options[:pattern].downcase.to_sym
      unless song.patterns.has_key?(pattern_name)
        raise StandardError, "The song does not include a pattern called #{@options[:pattern]}"
      end
      
      song.flow = [pattern_name]
      song.remove_unused_patterns()
    end

    duration = nil
    if @options[:split]
      split_songs = song.split()
      split_songs.each do |track_name, split_song|
        split_song = song_optimizer.optimize(split_song, OPTIMIZED_PATTERN_LENGTH)

        # TODO: Move building the output file name into its own method?
        extension = File.extname(@output_file_name)
        file_name = File.dirname(@output_file_name) + "/" +
                    File.basename(@output_file_name, extension) + "-" + File.basename(track_name, extension) +
                    extension
        duration = AudioEngine.new(split_song, kit).write_to_file(file_name)
      end
    else
      song = song_optimizer.optimize(song, OPTIMIZED_PATTERN_LENGTH)
      duration = AudioEngine.new(song, kit).write_to_file(@output_file_name)
    end

    return {:duration => duration}
  end
end
