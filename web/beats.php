<? require_once("header.php");
   drawHeader(); ?>
  <div class="content-box">
    <h1>BEATS</h1>
    <p>is a command-line drum machine. Feed it a song notated in YAML, and it will produce a precision-milled Wave file of impeccable timing and feel. Here is an example song:</p>
    <p><pre><code>Song:
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
    - tom_high:   sounds/tom4.wav
    - tom_low:    sounds/tom2.wav


Verse:
  - bass:       X...X...X...X...
  - snare:      ..............X.
  - hh_closed:  X.XXX.XXX.X.X.X.
  - agogo:      ..............XX

Chorus:
  - bass:       X...X...X...X...
  - snare:      ....X.......X...
  - hh_closed:  X.XXX.XXX.XX..X.
  - tom_high:   ...........X....
  - tom_low:    ..............X.</pre></code></p>
    <p>And <a href="/media/beat.mp3">here is what it sounds like</a> after getting the BEATS treatment. What a glorious groove!</p>
    <p class="last">So go forth and <a href="/download/">install BEATS</a>, download some <a href="/download#drum-kits">drum sounds</a>, and <a href="/examples/">listen to some examples</a>. Then read up on <a href="/strategyguide/">how to use it</a>.</p>
  </div>
<? drawFooter(); ?>
