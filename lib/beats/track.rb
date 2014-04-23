module Beats
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
      @name = name
      self.rhythm = rhythm
    end

    # TODO: What to have this invoked when setting like this?
    #   track.rhythm[x..y] = whatever
    def rhythm=(rhythm)
      @rhythm = rhythm.delete(BARLINE)
      @trigger_step_lengths = calculate_trigger_step_lengths
    end

    def step_count
      @rhythm.length
    end

    attr_accessor :name
    attr_reader :rhythm, :trigger_step_lengths

    private

    def calculate_trigger_step_lengths
      trigger_step_lengths = []

      trigger_step_length = 0
      @rhythm.each_char do |ch|
        if ch == BEAT
          trigger_step_lengths << trigger_step_length
          trigger_step_length = 1
        elsif ch == REST
          trigger_step_length += 1
        else
          raise InvalidRhythmError, "Track #{@name} has an invalid rhythm: '#{rhythm}'. Can only contain '#{BEAT}', '#{REST}' or '#{BARLINE}'"
        end
      end

      if trigger_step_length > 0
        trigger_step_lengths << trigger_step_length
      end
      if trigger_step_lengths == []
        trigger_step_lengths = [0]
      end

      trigger_step_lengths
    end
  end
end
