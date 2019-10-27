$:.push File.expand_path("../lib", __FILE__)
require 'beats'

Gem::Specification.new do |s|
  s.name = "beats"
  s.version = Beats::VERSION
  s.author = "Joel Strait"
  s.email = "joel dot strait at Google's popular web mail service"
  s.homepage = "https://beatsdrummachine.com/"
  s.platform = Gem::Platform::RUBY
  s.executables = "beats"
  s.required_ruby_version = ">= 1.9.3"
  s.license = "MIT"

  s.add_runtime_dependency "wavefile", "= 0.8.1"

  s.summary = "A command-line drum machine"
  s.description = "A command-line drum machine. Takes a song notated in a YAML file as input, and outputs a *.wav sound file."
  s.post_install_message = "Thanks for installing Beats Drum Machine! For information on how to use Beats, or to download some drum sounds to use with Beats, visit https://beatsdrummachine.com"

  s.files = ["LICENSE", "README.markdown", "Rakefile"] + Dir["lib/**/*.rb"] + Dir["bin/*"] + Dir["test/**/*"]
  s.test_files = Dir["test/**/*"]
  s.require_path = "lib"
end
