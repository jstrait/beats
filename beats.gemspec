Gem::Specification.new do |s| 
  s.name = "beats"
  s.version = "1.0.0"
  s.author = "Joel Strait"
  s.email = ""
  s.homepage = "http://beatsdrummachine.com/"
  s.platform = Gem::Platform::RUBY
  s.executables = "beats"
  s.summary = "A drum machine that uses text files, written in Ruby. Feed it a YAML file, and it will produce a Wave file."
  s.description = <<-EOF
BEATS
-----

BEATS is a drum machine written in pure Ruby. Feed it a song notated in YAML, and it will produce a precision-milled Wave file of impeccable timing and feel. Here's an example song:

    Song:
      Tempo: 120
      Structure:
        - Verse:   x2
        - Chorus:  x4
        - Verse:   x2
        - Chorus:  x4

    Verse:
      - bass.wav:       X...X...X...X...
      - snare.wav:      ..............X.
      - hh_closed.wav:  X.XXX.XXX.X.X.X.
      - agogo_high.wav: ..............XX

    Chorus:
      - bass.wav:       X...X...X...X...
      - snare.wav:      ....X.......X...
      - hh_closed.wav:  X.XXX.XXX.XX..X.
      - tom4.wav:       ...........X....
      - tom2.wav:       ..............X.

For installation and usage instructions, visit the BEATS website at [http://beatsdrummachine.com](http://beatsdrummachine.com).
EOF
  s.files = ["LICENSE", "README.markdown"] + Dir['lib/**/*.rb'] + Dir['bin/*'] + Dir['test/**/*']
  s.test_files = Dir['test/**/*']
  s.require_path = "lib"
  s.add_dependency("wavefile", "= 0.3.0")
end
