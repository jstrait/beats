<? require_once("header.php");
   drawHeader(); ?>
  <div class="content-box">
    <h2>Example Songs</h2>
    <p>Each example includes the raw output from BEATS, as well as an arrangement with other instruments done in GarageBand.</p>
  </div>
  <div class="content-box">
    <h2>Space Guitar</h2>
    <p>Drum kit: <a href="/download#drumkit-hammerhead">Hammerhead</a></p>
    <label class="example-song">Raw BEATS</label><audio class="example-song"src="beat.mp3" controls></audio>
    <label class="example-song">Full Song</label><audio class="example-song" src="beat.mp3" controls></audio>
    <div>
      <a id="toggle-techno-guitar" href="#" onclick="toggleSource('toggle-techno-guitar', 'source-techno-guitar'); return false;">Show Source</a>
      <pre id="source-techno-guitar" style="display: none;"><code>Song:
  Tempo: 130
  Flow:
    - Verse:   x3
    - VerseA:  x1
    - Chorus:  x3
    - VerseA:  x1
  Kit:
    - bass:       "bass/House #2-1.wav"
    - sub_bass:   "bass/Roland TR-909-1.wav"
    - clap:       "clap/CompuRhythm 8000-3.wav"
    - snare:      "snare/Korg Rhythm 55-2.wav"
    - hh_closed:  "hihat/House #2-5.wav"
    - hh_open:    "hihat/House #2-6.wav"
    - ding:       "Anabolic-5.wav"

Verse:
  - bass:      |X...X...X...X...|X...X...X...X...|
  - clap:      |....X.......X...|....X.........X.|
  - hh_closed: |.XXXX.X.XX..XX..|.XXXX.X.XX..XX.X|
  - ding:      |X...............|................|

VerseA:
  - bass:      |X...X...X...X...|X...X...X...X...|
  - clap:      |....X.......X...|....X.........X.|
  - snare:     |................|..........X.XXXX|
  - hh_closed: |.XXXX.X.XX..XX..|.XXXX.X.XX..XX.X|
  - ding:      |X...............|................|

Chorus:
  - bass:      |X...X...X...X...|X...X...X...X...|
  - sub_bass:  |X.......X.......|X.......X......X|
  - clap:      |....X.......X...|....X.........X.|
  - snare:     |....X.......X.XX|....X.XX......X.|
  - hh_closed: |.XXXX.X.XX..XX..|.XXXX.X.XX..XX.X|
  - ding:      |X...............|................|</code></pre>
    </div>
  </div>
  <div class="content-box">
    <h2>Synth Groove</h2>
    <p>Drum kit: <a href="/download#drumkit-hammerhead">Hammerhead</a></p>
    <label class="example-song">Raw BEATS</label><audio class="example-song" src="beat.mp3" controls></audio>
    <label class="example-song">Full Song</label><audio class="example-song" src="beat.mp3" controls></audio>
    Synth sounds provided by an old <a href="http://commons.wikimedia.org/wiki/File:Korg_poly800.jpg">Korg Poly-800</a>.
  </div>
  <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/prototype/1.6.1/prototype.js"></script>
<script type="text/javascript">
function toggleSource(toggleId, elementId) {
  var toggler = $(toggleId);
  var element = $(elementId);  

  element.toggle();
  toggler.innerText = (element.visible()) ? "Hide Source" : "Show source"; 
}
</script>
<? drawFooter(); ?>
