class InvalidRhythmError < RuntimeError; end


# Domain object which models a kit sound playing a rhythm. For example,
# a bass drum playing every quarter note for two measures.
#
# This object is like sheet music; the AudioEngine is responsible creating actual
# audio data for a Track (with the help of a Kit).
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
        raise InvalidRhythmError, "Track #{@name} has an invalid rhythm: '#{rhythm}'. Can only contain '#{BEAT}', '#{REST}' or '#{BARLINE}'"
      end
    end
    
    if beat_length > 0
      beats << beat_length
    end
    if beats == []
      beats = [0]
    end
    @beats = beats
  end
  
  def step_count
    return @rhythm.length
  end
   
  attr_accessor :name
  attr_reader :rhythm, :beats
end
