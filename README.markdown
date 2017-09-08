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

The latest version of Beats is 2.1.0, released on ______.

This version adds support for "composite sounds". That is, sounds that are made from combining two or more sounds together. It is a more succinct way of writing songs where more than one track plays the same rhythm.

Composite sounds can now be defined in the Kit:

    Kit:
      - bass:         bass.wav                    # A traditional non-composite sound
      - combo_snare:  [clap.wav, 808_snare.wav]   # A composite sound

The `combo_snare` sound above is a composite sound made by combining `clap.wav` and `808_snare.wav` together. It can then be used in a pattern:

    Verse:
      - bass:         X.......X.......
      - combo_snare:  ....X.......X...

This is equivalent to the following song:

    Kit:
      - bass:   bass.wav
      - clap:   clap.wav
      - snare:  808_snare.wav

    Verse:
      - bass:   X.......X.......
      - clap:   ....X.......X...
      - snare:  ....X.......X...

When using the `-s` command-line option to write each track to it's own *.wav file, each sub-sound in a composite sound will be written to its own file. For example, this song:

    Kit:
      - combo_snare:  [clap.wav, 808_snare.wav]

    Verse:
      - combo_snare:  X...X...X...X...

Will be written to two different files, `combo_snare-clap.wav` and `combo_snare-808_snare.wav`, when using the `-s` option.

Finally, composite sounds can be used within track definitions themselves. Kit sounds and non-Kit sounds can be used together in a composite Track sound:

    Kit:
      - bass:         bass.wav
      - combo_snare:  [clap.wav, 808_snare.wav]

    Verse:
      - [bass, combo_snare, other_sound.wav]:   X...X...X...X...

This is a equivalent to:

    Kit:
      - bass:   bass.wav
      - clap:   clap.wav
      - snare:  808_snare.wav

    Verse:
      - bass:             X...X...X...X...
      - clap:             X...X...X...X...
      - snare:            X...X...X...X...
      - other_sound.wav:  X...X...X...X...



What's Slightly Less New
------------------------

The previous version of Beats is 2.0.0, released on September 4, 2017. It is primarily a modernization release, and contains some relatively small backwards incompatible changes.

* Track rhythms can now have spaces in them. For example, `X... .... X... ....` is now a valid rhythm. Spaces are ignored, and don't affect the rhythm. For example, `X...    X...` is treated as the same rhythm as `X...X...`
* Wave files using `WAVEFORMATEXTENSIBLE` format can now be used, due to upgrading the WaveFile gem dependency to v0.8.1 behind the scenes.
* Installing the gem is now simpler, since it no longer requires installing the legacy `syck` YAML parser via an extension.
* A `Fixnum is deprecated` message is no longer shown when using Ruby 2.4
* **Backwards incompatible changes**:
  * Song files containing a `Structure` section are no longer supported. A `Flow` section should be used instead. Support for the `Structure` section has been deprecated since v1.2.1 (released in 2011).
  * Track rhythms can no longer start with a `|` character. For example, `|X...X...` is no longer a valid rhythm. However, bar lines are still allowed to appear elsewhere in the rhythm. For example, `X...X...|X...X...|` _is_ a valid rhythm. The reason for this change is that a rhythm starting with `|` is parsed as a YAML scalar block now that Beats is using the Psych YAML library behind the scenes. The fact that the old Syck YAML library didn't treat rhythms starting with a `|` as a YAML scalar block appears to have been a bug in Syck?
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

