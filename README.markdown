BEATS Drum Machine
------------------

BEATS is a command-line drum machine written in pure Ruby. Feed it a song notated in YAML, and it will produce a precision-milled *.wav file of impeccable timing and feel. Here's an example song:

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

And [here is what it sounds like](http://beatsdrummachine.com/beat.mp3) after getting the BEATS treatment. What a glorious groove!

Current Status
--------------

The latest stable version of BEATS is 1.1.0. Development is currently underway for version 1.2.0, and the code on the trunk is the latest progress. 1.2.0 will bring significant performance and architectural improvements. It will also contain a few bug fixes.


Installation
------------

To install the latest stable version (1.1.0), run the following from the command line:

    sudo gem install beats

You can then run BEATS from the command-line using the `beats` command.

BEATS is not very useful unless you have some sounds to use with it. You can download some example sounds from [http://beatsdrummachine.com](http://beatsdrummachine.com).


Usage
-----

BEATS runs from the command-line. Run `beats -h` to see the available options. For more detailed instructions, see the strategy guide at [http://beatsdrummachine.com](http://beatsdrummachine.com)