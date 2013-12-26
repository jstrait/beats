$:.push File.expand_path("../lib", __FILE__)
require 'beats'

Gem::Specification.new do |s| 
  s.name = "beats"
  s.version = Beats::VERSION 
  s.author = "Joel Strait"
  s.email = "joel dot strait at Google's popular web mail service"
  s.homepage = "http://beatsdrummachine.com/"
  s.platform = Gem::Platform::RUBY
  s.executables = "beats"

  s.add_dependency "wavefile", "= 0.6.0"
  if RUBY_VERSION[0].to_i >= 2
    s.add_dependency "syck"
  end

  s.summary = "A command-line drum machine. Feed it a song notated in YAML, and it will produce a precision-milled Wave file of impeccable timing and feel."
  s.description = "A command-line drum machine. Feed it a song notated in YAML, and it will produce a precision-milled Wave file of impeccable timing and feel."
  s.files = ["LICENSE", "README.markdown", "Rakefile"] + Dir["lib/**/*.rb"] + Dir["bin/*"] + Dir["test/**/*"]
  s.test_files = Dir["test/**/*"]
  s.require_path = "lib"
end
