<? require_once("header.php");
   drawHeader(); ?>
  <div class="content-box">
    <h2>Example Songs</h2>
    <p>Each example includes the raw output from BEATS, as well as an arrangement with other instruments done in GarageBand.</p>
  </div>
  <div class="content-box">
    <h2>Synth Groove</h2>
    <p>Drum kit: <a href="/download#drumkit-hammerhead">Hammerhead</a></p>
    <label class="example-song">Raw BEATS</label>
    <audio class="example-song" controls>
      <source src="/media/beats_drum_machine_synth_groove_raw.mp3" />
      <source src="/media/beats_drum_machine_synth_groove_raw.ogg" />
      Your browser can't play this audio file.
    </audio>
    <label class="example-song">Full Song</label>
    <audio class="example-song" controls>
      <source src="/media/beats_drum_machine_synth_groove.mp3" />
      <source src="/media/beats_drum_machine_synth_groove.ogg" />
      Your browser can't play this audio file.
    </audio>
    <div>
      <a id="toggle-synth-groove" class="toggle" href="#" onclick="toggleSource('toggle-synth-groove', 'source-synth-groove'); return false;">Show Source</a>
      <pre id="source-synth-groove" style="display: none;"><code>Song:
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
  - bass:        |X.X.....X.X.....|
  - deep_bass:   |.....X.X........|
  - clap:        |....X.......X...|
  - hihat:       |X.X..X.XX.X.X.X.|
  - shaker:      |............XXXX|
  - tom:         |X...............|

Chorus:
  - bass:        |X.X..X.XX.X.....|
  - clap:        |....X.......X...|
  - hihat:       |X.X..X.XX.X.X.X.|
  - bongo_high:  |X.X.XX....XX.XX.|
  - bongo_low:   |.X..............|</code></pre>
    </div>

    Synth sounds provided by an old <a href="http://commons.wikimedia.org/wiki/File:Korg_poly800.jpg">Korg Poly-800</a>.
  </div>
  <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/prototype/1.6.1/prototype.js"></script>
<script type="text/javascript">
function toggleSource(toggleId, elementId) {
  var toggler = $(toggleId);
  var element = $(elementId);  

  element.toggle();
  toggler.innerText = (element.visible()) ? "Hide Source" : "Show source";

  return false;
}
</script>
<? drawFooter(); ?>
