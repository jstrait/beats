module Beats
  module Transforms
    class SongShuffler
      def self.transform(song)
        song.patterns.values.each do |pattern|
          pattern.tracks.values.each do |track|
            original_rhythm = track.rhythm

            track.rhythm = original_rhythm.bytes.each_slice(2).inject("") do |str, slice|
              str << slice.first
              if slice.length > 1
                str << '.' << slice.last
              end

              str
            end
          end
        end
      
        song.tempo = (song.tempo * 1.5).round

        song
      end
    end
  end
end
