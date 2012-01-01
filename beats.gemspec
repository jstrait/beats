Gem::Specification.new do |s| 
  s.name = "beats"
  s.version = "1.2.3"
  s.author = "Joel Strait"
  s.email = "joel dot strait at Google's popular web mail service"
  s.homepage = "http://beatsdrummachine.com/"
  s.platform = Gem::Platform::RUBY
  s.executables = "beats"
  s.add_dependency "wavefile", "= 0.3.0"
  s.summary = "A command-line drum machine. Feed it a song notated in YAML, and it will produce a precision-milled Wave file of impeccable timing and feel."
  s.description = "A command-line drum machine. Feed it a song notated in YAML, and it will produce a precision-milled Wave file of impeccable timing and feel."
  s.files = ["LICENSE", "README.markdown", "Rakefile"] + Dir["lib/**/*.rb"] + Dir["bin/*"] + Dir["test/**/*"]
  s.test_files = Dir["test/**/*"]
  s.require_path = "lib"
end
