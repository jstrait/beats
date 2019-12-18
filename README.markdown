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

To install the latest stable version (2.1.2) from [rubygems.org](https://rubygems.org/gems/beats), run the following from the command line:

    gem install beats

Note: if you're installing using the default version of Ruby that comes with macOS, you might get a file permission error. If that happens, use `sudo gem install beats` instead. If you're using a version manager such as rbenv, chruby, or RVM, plain `gem install beats` should work fine.

Once installed, you can then run Beats from the command-line using the `beats` command.

Beats is not very useful unless you have some sounds to use with it. You can download some example sounds from [https://beatsdrummachine.com](https://beatsdrummachine.com/download#drum-kits).


Usage
-----

Beats runs from the command-line. Run `beats -h` to see the available options. For more detailed instructions, visit <https://beatsdrummachine.com/usage/>.

Check out [this tutorial at beatsdrummachine.com](https://beatsdrummachine.com/tutorial/) to see an example of how to create a beat from scratch.


What's New in v2.1.2
--------------------

The latest version of Beats is 2.1.2, released on December 18, 2019. It contains these changes:

* Several confusing/unhelpful errors shown due to an error in an input file have been improved. For example, if a pattern has the invalid name "4", the error message will now be `Pattern name '4' is not valid. It must be a value that will be parsed from YAML as a String.`, instead of `undefined method 'downcase' for 4:Integer`.

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

Contact me (Joel Strait) by opening a GitHub issue.


License
-------
Beats Drum Machine is released under the MIT license.
