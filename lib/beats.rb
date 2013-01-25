class Beats
  BEATS_VERSION = "1.2.4"

  # Each pattern in the song will be split up into sub patterns that have at most this many steps.
  # In general, audio for several shorter patterns can be generated more quickly than for one long
  # pattern, and can also be cached more effectively.
  OPTIMIZED_PATTERN_LENGTH = 4

  def initialize(input_file_name, output_file_name, options)
    @input_file_name =  input_file_name

    if output_file_name.nil?
      output_file_name = File.basename(input_file_name, File.extname(input_file_name)) + ".wav"
    end
    @output_file_name = output_file_name

    @options = options
  end

  def run
    base_path = @options[:base_path] || File.dirname(@input_file_name)
    song, kit = SongParser.new().parse(base_path, File.read(@input_file_name))

    song = normalize_for_pattern_option(song)
    songs_to_generate = normalize_for_split_option(song)

    duration = nil
    song_optimizer = SongOptimizer.new()
    songs_to_generate.each do |output_file_name, song|
      song = song_optimizer.optimize(song, OPTIMIZED_PATTERN_LENGTH)
      duration = AudioEngine.new(song, kit).write_to_file(output_file_name)
    end

    return {:duration => duration}
  end

private

  # If the -p option is used, transform the song into one whose flow consists of
  # playing that single pattern once.
  def normalize_for_pattern_option(song)
    unless @options[:pattern].nil?
      pattern_name = @options[:pattern].downcase.to_sym

      unless song.patterns.has_key?(pattern_name)
        raise StandardError, "The song does not include a pattern called #{pattern_name}"
      end

      song.flow = [pattern_name]
      song.remove_unused_patterns()
    end

    return song
  end

  # Returns a hash of file name => song object for each song that should go through the audio engine
  def normalize_for_split_option(song)
    songs_to_generate = {}

    if @options[:split]
      split_songs = song.split()
      split_songs.each do |track_name, split_song|
        # TODO: Move building the output file name into its own method?
        extension = File.extname(@output_file_name)
        file_name = File.dirname(@output_file_name) + "/" +
                    File.basename(@output_file_name, extension) + "-" + File.basename(track_name, extension) +
                    extension

        songs_to_generate[file_name] = split_song
      end
    else
      songs_to_generate[@output_file_name] = song
    end

    return songs_to_generate
  end
end
