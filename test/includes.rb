# Standard Ruby libraries
require 'test/unit'
require 'yaml'
require 'rubygems'

# External gems
gem 'wavefile', "=0.4.0"
require 'wavefile'

# BEATS classes
require 'beats/audioengine'
require 'beats/audioutils'
require 'beats/beats'
require 'wavefile/cachingwriter'
require 'beats/kit'
require 'beats/pattern'
require 'beats/song'
require 'beats/songparser'
require 'beats/songoptimizer'
require 'beats/track'

YAML::ENGINE.yamler = 'syck' if defined?(YAML::ENGINE)
