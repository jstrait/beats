Gem::Specification.new do |s| 
  s.name = "beats"
  s.version = "1.0.0"
  s.author = "Joel Strait"
  s.email = ""
  s.homepage = "http://beatsdrummachine.com/"
  s.platform = Gem::Platform::RUBY
  s.executables = "beats"
  s.summary = "A drum machine that uses text files. Feed it a YAML file, and it will produce a Wave file."
  s.description = "A drum machine that uses text files. Feed it a YAML file, and it will produce a Wave file."
  s.files = ["LICENSE", "README.markdown"] + Dir['lib/**/*.rb'] + Dir['bin/*'] + Dir['test/**/*']
  s.test_files = Dir['test/**/*']
  s.require_path = "lib"
  s.add_dependency("wavefile", "= 0.3.0")
end
