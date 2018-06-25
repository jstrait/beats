module Beats
  module Transforms
    class SongSwinger
      class InvalidSwingRateError < RuntimeError; end

      def self.transform(song, swing_rate)
        validate_swing_rate(swing_rate)

        song.patterns.each do |pattern_name, pattern|
          swung_tracks = pattern.tracks.map do |track_name, track|
            if swing_rate == 8
              Track.new(track.name, swing_8(track.rhythm))
            elsif swing_rate == 16
              Track.new(track.name, swing_16(track.rhythm))
            end
          end

          song.patterns[pattern_name] = Pattern.new(pattern_name, swung_tracks)
        end

        song.tempo *= 1.5

        song
      end

      private

      def self.validate_swing_rate(swing_rate)
        if swing_rate != 8 && swing_rate != 16
          raise InvalidSwingRateError, "Invalid swing rate: '#{swing_rate}'. Swing rate must be 8 or 16."
        end
      end

      def self.swing_8(original_rhythm)
        original_rhythm.chars.each_slice(4).inject("") do |new_rhythm, slice|
          if slice.length == 1
            new_rhythm << "#{slice[0]}."
          else
            new_rhythm << "#{slice[0]}.#{slice[1]}.#{slice[2]}#{slice[3]}"
          end

          new_rhythm
        end
      end

      def self.swing_16(original_rhythm)
        original_rhythm.chars.each_slice(2).inject("") do |new_rhythm, slice|
          new_rhythm << "#{slice[0]}.#{slice[1]}"
          new_rhythm
        end
      end
    end
  end
end
