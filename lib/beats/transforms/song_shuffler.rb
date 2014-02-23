module Beats
  module Transforms
    class SongShuffler
      def self.transform(song)
        song.patterns.values.each do |pattern|
          pattern.tracks.values.each do |track|
            original_rhythm = track.rhythm

            track.rhythm = swing_16(track.rhythm)
          end
        end

        song.tempo = (song.tempo * 1.5).round

        song
      end

      private

      def self.swing_16(original_rhythm)
        original_rhythm.bytes.each_slice(2).inject("") do |new_rhythm, slice|
          new_rhythm << slice.first
          if slice.length > 1
            new_rhythm << '.' << slice.last
          end

          new_rhythm
        end
      end
    end
  end
end
