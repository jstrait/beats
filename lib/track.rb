class InvalidRhythmError < RuntimeError; end

class Track
  REST = "."
  BEAT = "X"
  BARLINE = "|"
  
  def initialize(name, rhythm)
    # TODO: Add validation for input parameters
    @name = name
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
    
  def tick_count
    return @rhythm.length
  end
   
  attr_accessor :name, :beats
  attr_reader :rhythm
end
