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

The latest stable version of BEATS is 1.2.2, released on June 13, 2011. This is a minor release which includes two bug fixes:

* Bug fix: Compatibility issues with Windows. Thanks to Luis Lavena for mentioning the problem and how to fix it.
* Bug fix: Return the correct status code when BEATS terminates, to improve scriptability.


Installation
------------

To install the latest stable version (1.2.2) from [rubygems.org](http://rubygems.org/gems/beats), run the following from the command line:

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

Contact me (Joel Strait) by sending a GitHub message or opening a GitHub issue.


License
-------
BEATS is released under the MIT license.

