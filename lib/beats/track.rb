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
    DISALLOWED_CHARACTERS = /[^X\.]/   # I.e., anything not an 'X' or a '.'

    def initialize(name, rhythm)
      @name = name
      self.rhythm = rhythm
    end

    def rhythm=(rhythm)
      @rhythm = rhythm.delete(BARLINE)
      @trigger_step_lengths = calculate_trigger_step_lengths
    end

    def step_count
      @rhythm.length
    end

    attr_reader :name, :rhythm, :trigger_step_lengths

    private

    def calculate_trigger_step_lengths
      if @rhythm.match(DISALLOWED_CHARACTERS)
        raise InvalidRhythmError, "Track #{@name} has an invalid rhythm: '#{rhythm}'. Can only contain '#{BEAT}', '#{REST}' or '#{BARLINE}'"
      end

      trigger_step_lengths = @rhythm.scan(/X?\.*/)[0..-2].map(&:length)
      trigger_step_lengths.unshift(0) unless @rhythm.start_with?(REST)

      trigger_step_lengths
    end
  end
end
