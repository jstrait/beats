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

And [here's what it sounds like](https://beatsdrummachine.com/media/beat.mp3) after getting the Beats treatment. What a glorious groove!

For more, check out [beatsdrummachine.com](https://beatsdrummachine.com)


Installation
------------

To install the latest stable version (2.1.1) from [rubygems.org](https://rubygems.org/gems/beats), run the following from the command line:

    gem install beats

Note: if you're installing using the default version of Ruby that comes with macOS, you might get a file permission error. If that happens, use `sudo gem install beats` instead. If you're using a version manager such as rbenv, chruby, or RVM, plain `gem install beats` should work fine.

Once installed, you can then run Beats from the command-line using the `beats` command.

Beats is not very useful unless you have some sounds to use with it. You can download some example sounds from [https://beatsdrummachine.com](https://beatsdrummachine.com/download#drum-kits).


Usage
-----

Beats runs from the command-line. Run `beats -h` to see the available options. For more detailed instructions, visit [https://github.com/jstrait/beats/wiki/Usage](https://github.com/jstrait/beats/wiki/Usage) on the [Beats Wiki](https://github.com/jstrait/beats/wiki).

Check out [this tutorial at beatsdrummachine.com](https://beatsdrummachine.com/tutorial/) to see an example of how to create a beat from sratch.


What's New in v2.1.1
--------------------

The latest version of Beats is 2.1.1, released on TBD.

* **Bug fix**: The relevant pattern name will now be capitalized correctly in certain error messages - previously they were always shown lowercase. For example, if you have a pattern named "Verse", then certain error messages will now use this capitalization instead of "verse". This hopefully makes the error messages easier to understand.
* **Bug fix**: Songs can now use *.wav files with more than 2 channels. Previously, using a sound with more than 2 channels would cause a fatal `Invalid sample data array in AudioUtils.normalize()` error.
* **Bug fix**: If a sound is defined multiple times in a Kit, the final definition should be used as the winner. However, this did not occur if the earlier definition was for a composite sound. That has now be fixed.

For info about previous releases, visit https://github.com/jstrait/beats/releases.


Local Development
-----------------

First, install the required dependencies:

    bundle install

To run Beats locally, use `bundle exec` and run `bin/beats`, to avoid using any installed gem executable. For example:

    bundle exec bin/beats -v

To run the tests:

    bundle exec rake test



Found a Bug? Have a Suggestion? Want to Contribute?
---------------------------------------------------

Contact me (Joel Strait) by sending a GitHub message or opening a GitHub issue.


License
-------
Beats Drum Machine is released under the MIT license.

