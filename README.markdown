Beats Drum Machine
------------------

Beats is a command-line drum machine written in pure Ruby. Feed it a song notated in YAML, and it will produce a precision-milled *.wav file of impeccable timing and feel. Here's an example song:

    Song:
      Tempo: 105
      Flow:
        - Verse:  x4
        - Chorus: x4
      Kit:
        - bass:     house_2_1.wav
        - snare:    roland_tr_909_2.wav
        - hihat:    house_2_5.wav
        - cowbell:  big_beat_5.wav
        - deep:     house_2_2.wav  
    
    Verse:
      - bass:     X..X...X..X.....
      - snare:    ....X.......X...
      - hihat:    ..X...X...X...X.
    
    Chorus:
      - bass:     X..X...X..X.....
      - snare:    ....X.......X...
      - hihat:    XXXXXXXXXXXXX...
      - cowbell:  ....XX.X..X.X...
      - deep:     .............X..

And [here's what it sounds like](http://beatsdrummachine.com/media/beat.mp3) after getting the Beats treatment. What a glorious groove!


Current Status
--------------

The latest stable version of Beats is 1.2.3, released on December 31, 2011. This is a minor release which includes two improvements:

* Bug fix: You can now use `~` in sound file paths, and it will correctly expand to your home folder. (At least on UNIX OSes, I'm not sure if that works on Windows).
* The new `--path` option allows setting the base path from which relative sound file paths are searched for.


Installation
------------

To install the latest stable version (1.2.3) from [rubygems.org](http://rubygems.org/gems/beats), run the following from the command line:

    gem install beats

Note that if you are installing using the default version of Ruby that comes with MacOS X, you might get a file permission error. If that happens, use `sudo gem install beats` instead. If you are using RVM, plain `gem install beats` should work fine.

Once installed, you can then run Beats from the command-line using the `beats` command.

Beats is not very useful unless you have some sounds to use with it. You can download some example sounds from [http://beatsdrummachine.com](http://beatsdrummachine.com/download#drum-kits).


Usage
-----

Beats runs from the command-line. Run `beats -h` to see the available options. For more detailed instructions, visit [https://github.com/jstrait/beats/wiki/Usage](https://github.com/jstrait/beats/wiki/Usage) on the [Beats Wiki](https://github.com/jstrait/beats/wiki).

The Beats wiki also has a [Getting Started](https://github.com/jstrait/beats/wiki/Getting-Started) tutorial which shows how to create an example beat from scratch.


Found a Bug? Have a Suggestion? Want to Contribute?
---------------------------------------------------

Contact me (Joel Strait) by sending a GitHub message or opening a GitHub issue.


License
-------
Beats is released under the MIT license.

