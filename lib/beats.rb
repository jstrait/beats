require "yaml"

gem "wavefile", "=0.8.1"
require "wavefile"
require "wavefile/caching_writer"

require "beats/audio_engine"
require "beats/audio_utils"
require "beats/beats_runner"
require "beats/kit"
require "beats/kit_builder"
require "beats/pattern"
require "beats/song"
require "beats/song_parser"
require "beats/song_optimizer"
require "beats/track"
require "beats/transforms/song_swinger"

module Beats
  VERSION = "2.1.1"
end
