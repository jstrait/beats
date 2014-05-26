<? require_once("header.php");
   drawHeader(); ?>
  <div class="content-box">
    <h2>Getting Started</h2>
    <p>Let&#8217;s make some beats! First thing, you gotta <a href="/download">download and install Beats</a>.</p>
    <p>Next, you&#8217;ll need some <code>*.wav</code> sound files. Download this set of <a href="/casio_sa20_drum_sounds.zip">sounds sampled from an ancient Casio keyboard</a>. Unzip that file to a folder.</p>
  </div>
  <div class="content-box">
    <h2>Hello World Beat</h2>
    <p>Create a new file in the same folder as the drum sounds you just downloaded. Call it something like <code>song.txt</code>. Open it in a text editor and type the following. (Make sure you indent the lines properly).</p>
    <p><pre><code>Song:
  Flow:
    - Verse

Verse:
  - bass.wav:  X...X...X...X...</code></pre></p>
    <p>This is about the most minimal song you can create. To turn it into a Wave file, run the following from the command line:</p>
    <p><pre><code>beats song.txt song.wav</code></pre></p>
    <p>If Beats ran successfully, it should print something like the following:</p>
    <p><pre><code>0:02 of audio written in 0.052459 seconds.</code></pre></p>
    <p>There should now be a file called <code>song.wav</code> in the current directory. Play it in whatever media player you like. It should sound like this:</p>
    <p><audio class="tutorial" src="/media/tutorial_1.wav" controls>Your browser can't play this audio file.</audio></p>
  </div>
  <div class="content-box">
  <h2>Changing the Tempo</h2>
  <p>By default, your song will play at 120 beats per minute. You can also specify your own tempo in the song header. This will play faster:</p>
  <p><pre><code>Song:
  Tempo: 200
  Flow:
    - Verse

Verse:
  - bass.wav:  X...X...X...X...

</code></pre></p>
  <p><audio class="tutorial" src="/media/tutorial_2_fast.wav" controls>Your browser can't play this audio file.</audio></p>
  <p>And this will play more slowly:</p>
  <p><pre><code>Song:
  Tempo: 60
  Flow:
    - Verse

Verse:
  - bass.wav:  X...X...X...X...

</code></pre></p>
  <p><audio class="tutorial" src="/media/tutorial_2_slow.wav" controls>Your browser can't play this audio file.</audio></p>
  </div>
  <div class="content-box">
  <h2>Adding More Tracks</h2>
  <p>That four-on-the-floor bass rhythm is nice, so let&#8217;s build on top of it. To add a snare drum and a hi-hat, just add two more lines to the <code>Verse</code> pattern:</p>
  <p><pre><code>Song:
  Tempo: 120
  Flow:
    - Verse

Verse:
  - bass.wav:       X...X...X...X...
  - snare.wav:      ....X.......X...
  - hh_closed.wav:  X.X.X.X.XX.XXXXX

</code></pre></p>
  <p><audio class="tutorial" src="/media/tutorial_3.wav" controls>Your browser can't play this audio file.</audio></p>
  </div>
  <div class="content-box">
  <h2>Repeating Patterns</h2>
  <p>You can repeat patterns in the flow. Add <code>x4</code> to repeat the <code>Verse</code> pattern four times.</p>
  <p><pre><code>Song:
  Tempo: 120
  Flow:
    - Verse:  x4

Verse:
  - bass.wav:       X...X...X...X...
  - snare.wav:      ....X.......X...
  - hh_closed.wav:  X.X.X.X.XX.XXXXX

</code></pre></p>
  <p><audio class="tutorial" src="/media/tutorial_4.wav" controls>Your browser can't play this audio file.</audio></p>
  </div>
  <div class="content-box">
  <h2>Adding a New Pattern</h2>
  <p>Now let&#8217;s add another pattern. Call it <code>Chorus</code>. Don&#8217;t forget to add it to the flow. Notice the optional bar line used to separate the two measures in the new pattern.</p>
  <p><pre><code>Song:
  Tempo: 120
  Flow:
    - Verse:  x4
    - Chorus: x4

Verse:
  - bass.wav:         X...X...X...X...
  - snare.wav:        ....X.......X...
  - hh_closed.wav:    X.X.X.X.XX.XXXXX

Chorus:
  - bass.wav:         XXXXXXXXXXXXX...|XXXXXXXXXXXXX...
  - snare.wav:        ....X.......X...|....X.......X...
  - hh_closed.wav:    XXXXXXXXXXXXX...|XXXXXXXXXXXXX...
  - conga_low.wav:    X.....X.X..X....|X.X....XX.X.....
  - conga_high.wav:   ....X....X......|................
  - cowbell_high.wav: ................|..............X.</code></pre></p>
  <p><audio class="tutorial" src="/media/tutorial_5.wav" controls>Your browser can't play this audio file.</audio></p>
  </div>
  <div class="content-box">
  <h2>Adding a Kit</h2>
  <p>In the last example some of the sounds (<code>bass.wav</code>, <code>snare.wav</code>, <code>hh_closed.wav</code>) were used in two different patterns. If you later wanted to switch out the snare sound with a different sample, you&#8217;d have to update the sound file in both patterns.</p>
  <p>A <code>kit</code> section lets you adds sounds to your song, and give them a custom label. If you later decide to switch out a sound, you only have to change it in one place. You can also use a different name than the sound file name.</p>
  <p>Notice how the patterns in this song use both sounds that are defined in the kit, as well as sounds that aren&#8217;t:</p>
  <p><pre><code>Song:
  Tempo: 120
  Kit:
    - bass:  bass.wav
    - snare: snare.wav
    - hihat: hh_closed.wav
  Flow:
    - Verse:  x4
    - Chorus: x4

Verse:
  - bass:             X...X...X...X...
  - snare:            ....X.......X...
  - hihat:            X.X.X.X.XX.XXXXX

Chorus:
  - bass:             XXXXXXXXXXXXX...|XXXXXXXXXXXXX...
  - snare:            ....X.......X...|....X.......X...
  - hihat:            XXXXXXXXXXXXX...|XXXXXXXXXXXXX...
  - conga_low.wav:    X.....X.X..X....|X.X....XX.X.....
  - conga_high.wav:   ....X....X......|................
  - cowbell_high.wav: ................|..............X.</code></pre></p>
  <p><audio class="tutorial" src="/media/tutorial_5.wav" controls>Your browser can't play this audio file.</audio></p>
  </div>
  <div class="content-box">
  <h2>Swing Beats</h2>
  <p>These days you&#8217;re nobody if your beats don&#8217;t swing. Fortunately Beats lets you either swing 8th notes (i.e. every two <code>X</code>s or <code>.</code>s) or 16th notes (i.e. every X or <code>.</code>).</p>
  <p>To do this, just add a <code>Swing</code> to the song header. The value can either be 8 or 16. The song below shows an example.</p>
  <p><pre><code>Song:
  Tempo: 120
  Kit:
    - bass:  bass.wav
    - snare: snare.wav
    - hihat: hh_closed.wav
  Flow:
    - Verse:  x4
    - Chorus: x4
  Swing: 8

Verse:
  - bass:             X...X...X...X...
  - snare:            ....X.......X...
  - hihat:            X.X.X.X.XX.XXXXX

Chorus:
  - bass:             XXXXXXXXXXXXX...|XXXXXXXXXXXXX...
  - snare:            ....X.......X...|....X.......X...
  - hihat:            XXXXXXXXXXXXX...|XXXXXXXXXXXXX...
  - conga_low.wav:    X.....X.X..X....|X.X....XX.X.....
  - conga_high.wav:   ....X....X......|................
  - cowbell_high.wav: ................|..............X.

</code></pre></p>
  <p>Here is the song above with swung 8th notes: <audio class="tutorial" src="/media/tutorial_7_swing8.wav" controls>Your browser can't play this audio file.</audio></p>
  <p>And with swung 16th notes: <audio class="tutorial" src="/media/tutorial_7_swing16.wav" controls>Your browser can't play this audio file.</audio></p>
  </div>
    <div class="content-box">
  <h2>Writing Each Track To a Separate Wave File</h2>
  <p>If you want to use your beat in music editing software such as Logic, GarageBand, etc., you'll probably want to save each track as a separate Wave file. This way you can independently adjust the volume of each track, add effects to individual sounds, etc.</p>
  <p>To do this, just add the <code>-s</code> option when running Beats. For example:</p>
  <p><pre><code>beats -s song.txt song.wav</code></pre></p>
  <p>If you add this option when running Beats for the following song:</p>
  <p><pre><code>Song:
  Tempo: 120
  Kit:
    - bass:  bass.wav
    - snare: snare.wav
    - hihat: hh_closed.wav
  Flow:
    - Verse:  x4
    - Chorus: x4

Verse:
  - bass:             X...X...X...X...
  - snare:            ....X.......X...
  - hihat:            X.X.X.X.XX.XXXXX

Chorus:
  - bass:             XXXXXXXXXXXXX...|XXXXXXXXXXXXX...
  - snare:            ....X.......X...|....X.......X...
  - hihat:            XXXXXXXXXXXXX...|XXXXXXXXXXXXX...
  - conga_low.wav:    X.....X.X..X....|X.X....XX.X.....
  - conga_high.wav:   ....X....X......|................
  - cowbell_high.wav: ................|..............X.

</code></pre></p>
  <p>Beats will create the Wave files below. Note how the bass tracks (for example) for the verse and chorus patterns are combined into one wave file.</p>
  <p class="last"><label>song-bass.wav</label><audio class="tutorial" src="/media/tutorial_8-bass.wav" controls>Your browser can't play this audio file.</audio></p>
  <p class="last"><label>song-snare.wav</label><audio class="tutorial" src="/media/tutorial_8-snare.wav" controls>Your browser can't play this audio file.</audio></p>
  <p class="last"><label>song-hh_closed.wav</label><audio class="tutorial" src="/media/tutorial_8-hh_closed.wav" controls>Your browser can't play this audio file.</audio></p>
  <p class="last"><label>song-conga_low.wav</label><audio class="tutorial" src="/media/tutorial_8-conga_low.wav" controls>Your browser can't play this audio file.</audio></p>
  <p class="last"><label>song-conga_high.wav</label><audio class="tutorial" src="/media/tutorial_8-conga_high.wav" controls>Your browser can't play this audio file.</audio></p>
  <p class="last"><label>song-cowbell_high.wav</label><audio class="tutorial" src="/media/tutorial_8-cowbell_high.wav" controls>Your browser can't play this audio file.</audio></p>
  </div>
  </div>
<? drawFooter(); ?>
