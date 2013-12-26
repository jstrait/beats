# Standard Ruby libraries
require 'test/unit'
require 'yaml'
require 'syck'
require 'rubygems'

# External gems
gem 'wavefile', "=0.6.0"
require 'wavefile'

# BEATS classes
require 'beats'
require 'wavefile/cachingwriter'
include Beats

YAML::ENGINE.yamler = 'syck' if defined?(YAML::ENGINE)
