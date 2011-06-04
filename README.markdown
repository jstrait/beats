BEATS Drum Machine
------------------

BEATS is a command-line drum machine written in pure Ruby. Feed it a song notated in YAML, and it will produce a precision-milled *.wav file of impeccable timing and feel. Here's an example song:

    Song:
      Tempo: 120
      Flow:
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

The latest stable version of BEATS is 1.2.1, released on March 6, 2011. This is a minor release which includes the following improvements:

* You can use the | character to represent bar lines in a track rhythm. This is optional, but often makes longer rhythms easier to read.
* The "Structure" section of the song header is now called "Flow". (You can still use "Structure" for now, but you'll get a warning).
* A pattern can contain multiple tracks that use the same sound. Previously, BEATS would pick one of those tracks as the 'winner', and the other tracks wouldn't be played.
* Bug fix: A better error message is displayed if a sound file is in an unsupported format (such as MP3), or is not even a sound file.

Work is currently under way on 1.2.2, which will be another small update. It is planned to be released in early June. The planned changes for this version are:

* Bug fix: Compatibility issues with Windows
* Bug fix: Return the correct status code when BEATS terminates, to improve scriptability.


Installation
------------

To install the latest stable version (1.2.1) from [rubygems.org](http://rubygems.org/gems/beats), run the following from the command line:

    gem install beats

Note that if you are installing using the default version of Ruby that comes with MacOS X, you might get a file permission error. If that happens, use `sudo gem install beats` instead. If you are using RVM, plain `gem install beats` should work fine.

Once installed, you can then run BEATS from the command-line using the `beats` command.

BEATS is not very useful unless you have some sounds to use with it. You can download some example sounds from [http://beatsdrummachine.com](http://beatsdrummachine.com/download#drum-kits).


Usage
-----

BEATS runs from the command-line. Run `beats -h` to see the available options. For more detailed instructions, visit [https://github.com/jstrait/beats/wiki/Usage](https://github.com/jstrait/beats/wiki/Usage) on the [BEATS Wiki](https://github.com/jstrait/beats/wiki).

The BEATS wiki also has a [Getting Started](https://github.com/jstrait/beats/wiki/Getting-Started) tutorial which shows how to create an example beat from scratch.


Found a Bug? Have a Suggestion? Want to Contribute?
---------------------------------------------------

Contact me (Joel Strait) by sending a GitHub message.


License
-------
BEATS is released under the MIT license.

