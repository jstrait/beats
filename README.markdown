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

For more, check out [beatsdrummachine.com](http://beatsdrummachine.com)


Installation
------------

To install the latest stable version (2.0.0) from [rubygems.org](http://rubygems.org/gems/beats), run the following from the command line:

    gem install beats

Note that if you are installing using the default version of Ruby that comes with MacOS X, you might get a file permission error. If that happens, use `sudo gem install beats` instead. If you are using RVM, plain `gem install beats` should work fine.

Once installed, you can then run Beats from the command-line using the `beats` command.

Beats is not very useful unless you have some sounds to use with it. You can download some example sounds from [http://beatsdrummachine.com](http://beatsdrummachine.com/download#drum-kits).


Usage
-----

Beats runs from the command-line. Run `beats -h` to see the available options. For more detailed instructions, visit [https://github.com/jstrait/beats/wiki/Usage](https://github.com/jstrait/beats/wiki/Usage) on the [Beats Wiki](https://github.com/jstrait/beats/wiki).

Check out [this tutorial at beatsdrummachine.com](http://beatsdrummachine.com/tutorial/) to see an example of how to create a beat from sratch.


What's New
----------

The latest stable version of Beats is 2.0.0, released on _________. It is primarily a modernization release, and contains some relatively small backwards incompatible changes.

* Track rhythms can now have spaces in them. For example, `X... .... X... ....` is now a valid rhythm.
* Installing the gem is now simpler, since it no longer requires installing `syck` via an extension.
* Wave files using `WAVEFORMATEXTENSIBLE` format can now be used, due to upgrading the WaveFile gem to v0.8.1 behind the scenes.
* A "Fixnum is deprecated" message is no longer shown when using Ruby 2.4
* Backwards incompatible changes:
  * Song files containing a `Structure` section are no longer supported. a `Flow` section should be used instead. Support for the `Structure` section has been deprecated since v1.2.1, released in 2011.
  * Track rhythms can no longer start with a `|` character. For example, `|X...X...` is no longer a valid rhythm. However, bar lines are still allowed to appear elsewherein the rhythm. For example, `X...X...|X...X...|` _is_ a valid rhythm. The reason for this change is that a rhythm starting with `|` is parsed as a YAML scalar block now that Beats is using the Psych YAML library behind the scenes. The fact that Syck didn't treat rhythms starting with a `|` as a YAML scalar block appears to have been a bug in Syck.
* The minimum supported Ruby version is now 1.9.3, instead of 1.8.7


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

