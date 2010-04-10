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
      Kit:
        - bass:       sounds/bass.wav
		- snare:      sounds/snare.wav
		- hh_closed:  sounds/hh_closed.wav
		- agogo:      sounds/agogo_high.wav

    Verse:
      - bass:             X...X...X...X...
      - snare:            ..............X.
      - hh_closed:        X.XXX.XXX.X.X.X.
      - agogo:            ..............XX

    Chorus:
      - bass:             X...X...X...X...
      - snare:            ....X.......X...
      - hh_closed:        X.XXX.XXX.XX..X.
	  - sounds/tom4.wav:  ...........X....
	  - sounds/tom2.wav:  ..............X.

For installation and usage instructions, visit the BEATS website at [http://beatsdrummachine.com](http://beatsdrummachine.com).
