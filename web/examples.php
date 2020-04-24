<? require_once("header.php");
   drawHeader(); ?>
  <div class="content-box">
    <h2>Example Songs</h2>
    <p>Each example includes the raw output from Beats, as well as an arrangement with other instruments done in GarageBand.</p>
  </div>
  <div class="content-box">
    <h2>Synth Groove</h2>
    <p>Drum kit: <a href="/download#drumkit-hammerhead">Hammerhead</a></p>
    <ul>
      <li class="flex">
        <label class="example-label">Raw Beats</label>
        <audio class="flex-fill" controls>
          <source src="/media/beats_drum_machine_synth_groove_raw.mp3" />
          <source src="/media/beats_drum_machine_synth_groove_raw.ogg" />
          Your browser can't play this audio file.
        </audio>
      </li>
      <li class="flex">
        <label class="example-label">Full Song</label>
        <audio class="flex-fill" controls>
          <source src="/media/beats_drum_machine_synth_groove.mp3" />
          <source src="/media/beats_drum_machine_synth_groove.ogg" />
          Your browser can't play this audio file.
        </audio>
      </li>
    </ul>
    <p>
      <pre><code>Song:
  Tempo: 105
  Flow:
    - Verse:   x4
    - Chorus:  x4
    - Verse:   x4
  Kit:
    - bass:        ultimate_dnb_2.wav
    - deep_bass:   house_1_1.wav
    - clap:        compurhythm_8000_3.wav
    - hihat:       compurhythm_78_4.wav
    - shaker:      human_beatbox_4.wav
    - tom:         coron_drum_synce_ds7_2.wav
    - bongo_high:  bongo_3.wav
    - bongo_low:   bongo_2.wav

Verse:
  - bass:        X.X.....X.X.....
  - deep_bass:   .....X.X........
  - clap:        ....X.......X...
  - hihat:       X.X..X.XX.X.X.X.
  - shaker:      ............XXXX
  - tom:         X...............

Chorus:
  - bass:        X.X..X.XX.X.....
  - clap:        ....X.......X...
  - hihat:       X.X..X.XX.X.X.X.
  - bongo_high:  X.X.XX....XX.XX.
  - bongo_low:   .X..............</code></pre>
    </p>

    Synth sounds provided by an old <a href="https://commons.wikimedia.org/wiki/File:Korg_poly800.jpg">Korg Poly-800</a>.
  </div>
<? drawFooter(); ?>
