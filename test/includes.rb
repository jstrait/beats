# Standard Ruby libraries
require 'test/unit'
require 'yaml'
require 'rubygems'

# External gems
gem 'wavefile', "=0.4.0"
require 'wavefile'

# BEATS classes
require 'audioengine'
require 'audioutils'
require 'beats'
require 'wavefile/cachingwriter'
require 'kit'
require 'pattern'
require 'patternexpander'
require 'song'
require 'songparser'
require 'songoptimizer'
require 'track'
