require 'yaml'

gem "wavefile", "=0.8.1"
require 'wavefile'
require 'wavefile/cachingwriter'

require 'beats/audioengine'
require 'beats/audioutils'
require 'beats/beatsrunner'
require 'beats/kit'
require 'beats/kit_builder'
require 'beats/pattern'
require 'beats/song'
require 'beats/songparser'
require 'beats/songoptimizer'
require 'beats/track'
require 'beats/transforms/song_swinger'

module Beats
  VERSION = "2.1.0"
end
