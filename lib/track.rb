class InvalidRhythmError < RuntimeError; end

class Track
  REST = "."
  BEAT = "X"
  BARLINE = "|"
  
  def initialize(name, wave_data, rhythm)
    # TODO: Add validation for input parameters
    
    @wave_data = wave_data
    @name = name
    @sample_data = nil
    @overflow = nil
    self.rhythm = rhythm
  end
  
  # TODO: What to have this invoked when setting like this?
  #   track.rhythm[x..y] = whatever
  def rhythm=(rhythm)
    @rhythm = rhythm.delete(BARLINE)
    beats = []
    
    beat_length = 0
    #rhythm.each_char{|ch|
    @rhythm.each_byte do |ch|
      ch = ch.chr
      if ch == BEAT
        beats << beat_length
        beat_length = 1
      elsif ch == REST
        beat_length += 1
      else
        raise InvalidRhythmError, "Track #{@name} has an invalid rhythm: '#{rhythm}'. Can only contain 'X' or '.'"
      end
    end
    
    if beat_length > 0
      beats << beat_length
    end
    if beats == []
      beats = [0]
    end
    @beats = beats
    
    # Remove any cached sample data
    @sample_data = nil
    @overflow = nil
  end
  
  def intro_sample_length(tick_sample_length)
    return @beats[0] * tick_sample_length.floor
  end
  
  def sample_length(tick_sample_length)
    total_ticks = @beats.inject(0) {|sum, n| sum + n}
    return (total_ticks * tick_sample_length).floor
  end
  
  def sample_length_with_overflow(tick_sample_length)
    temp_sample_length = sample_length(tick_sample_length)
    
    unless @beats == [0]
      beat_sample_length = @beats.last * tick_sample_length
      if(@wave_data.length > beat_sample_length)
        temp_sample_length += @wave_data.length - beat_sample_length.floor
      end
    end
    
    return temp_sample_length.floor
  end
  
  def tick_count
    return @rhythm.length
  end
  
  def sample_data(tick_sample_length)
    if @sample_data == nil
      combined_sample_data = AudioUtils.generate_rhythm(@beats, tick_sample_length, @wave_data)
      @sample_data = combined_sample_data[:primary]
      @overflow = combined_sample_data[:overflow]
    end
    
    return {:primary => @sample_data.dup, :overflow => @overflow}
  end
  
  attr_accessor :name, :wave_data
  attr_reader :rhythm
end
