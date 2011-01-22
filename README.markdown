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

And [here's what it sounds like](http://beatsdrummachine.com/beat.mp3) after getting the BEATS treatment. What a glorious groove!


Current Status
--------------

The latest stable version of BEATS is 1.2.0, released on July 12, 2010. It brings significant performance and architectural improvements. It also contains a few bug fixes. For more info, see [http://www.joelstrait.com/blog/2010/7/12/beats_1.2.0_released](http://www.joelstrait.com/blog/2010/7/12/beats_1.2.0_released).

Development for 1.2.1 is underway on the trunk. This is a minor release which will add a few small features:

* You can use the | character to represent bar lines in a track rhythm. This is optional, but often makes longer rhythms easier to read.
* The "Structure" section of the song header is now called "Flow".
* A pattern can contain multiple tracks that use the same sound. Previously, BEATS would pick one of those tracks as the 'winner', and the other tracks wouldn't be played.


Installation
------------

To install the latest stable version (1.2.0), run the following from the command line:

    sudo gem install beats

You can then run BEATS from the command-line using the `beats` command.

BEATS is not very useful unless you have some sounds to use with it. You can download some example sounds from [http://beatsdrummachine.com](http://beatsdrummachine.com).


Usage
-----

BEATS runs from the command-line. Run `beats -h` to see the available options. For more detailed instructions, visit [https://github.com/jstrait/beats/wiki/Usage](https://github.com/jstrait/beats/wiki/Usage). 
