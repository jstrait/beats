class Beats
  BEATS_VERSION = "1.2.0a"
  SAMPLE_RATE = 44100
  OPTIMIZED_PATTERN_LENGTH = 4

  def initialize(input_file_name, output_file_name, options)
    @input_file_name =  input_file_name
    @output_file_name = output_file_name
    @options = options
  end

  def run()
    start_time = Time.now
    output_message = ""

    if(@input_file_name == nil)
      ARGV[0] = '-h'
      parse_options()
    end

    if(@output_file_name == nil)
      @output_file_name = File.basename(@input_file_name, File.extname(@input_file_name)) + ".wav"
    end

    begin
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

          extension = File.extname(@output_file_name)
          file_name = File.basename(@output_file_name, extension) + "-" + File.basename(track_name, extension) + extension
          duration = split_song.write_to_file(file_name)
        end
      else
        song = song_optimizer.optimize(song, OPTIMIZED_PATTERN_LENGTH)
        duration = song.write_to_file(@output_file_name)
      end

      output_message =  "#{duration[:minutes]}:#{duration[:seconds].to_s.rjust(2, '0')} of audio saved to #{@output_file_name} in #{Time.now - start_time} seconds."
    rescue Errno::ENOENT => detail
      output_message =  "\n"
      output_message += "Song file '#{@input_file_name}' not found.\n"
      output_message += "\n"
    rescue SongParseError => detail
      output_message = "\n"
      output_message += "Song file '#{@input_file_name}' has an error:\n"
      output_message += "  #{detail}\n"
      output_message += "\n"
    rescue StandardError => detail
      output_message =  "\n"
      output_message += "An error occured while generating sound for '#{@input_file_name}':\n"
      output_message += "  #{detail}\n"
      output_message += "\n"
    end
    
    return output_message
  end
end