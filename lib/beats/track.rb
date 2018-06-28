module Beats
  # Domain object which models a kit sound playing a rhythm. For example,
  # a bass drum playing every quarter note for two measures.
  #
  # This object is like sheet music; the AudioEngine is responsible creating actual
  # audio data for a Track (with the help of a Kit).
  class Track
    class InvalidRhythmError < ArgumentError; end

    REST = "."
    BEAT = "X"
    BARLINE = "|"
    SPACE = " "
    DISALLOWED_CHARACTERS = /[^X\.| ]/   # I.e., anything not an 'X', '.', '|', or ' '

    def initialize(name, rhythm)
      unless name.is_a?(String)
        raise ArgumentError, "Track `name` argument must be a String"
      end

      unless rhythm.is_a?(String) && !rhythm.match(DISALLOWED_CHARACTERS)
        raise InvalidRhythmError, "Track '#{name}' has an invalid rhythm: '#{rhythm}'. Can only contain '#{BEAT}', '#{REST}', '#{BARLINE}', or ' '"
      end

      @name = name.dup.freeze
      @rhythm = rhythm.delete(BARLINE + SPACE).freeze

      @step_count = @rhythm.length
      @trigger_step_lengths = calculate_trigger_step_lengths.freeze
    end

    attr_reader :name, :rhythm, :step_count, :trigger_step_lengths

    private

    def calculate_trigger_step_lengths
      trigger_step_lengths = @rhythm.scan(/X?\.*/)[0..-2].map(&:length)
      trigger_step_lengths.unshift(0) unless @rhythm.start_with?(REST)

      trigger_step_lengths
    end
  end
end
