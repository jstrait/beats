<? require_once("header.php");
   drawHeader(); ?>
  <div class="content-box">
    <h1>Beats</h1>
    <p>is a command-line drum machine. Feed it a song notated in YAML, and it will produce a precision-milled <code>*.wav</code> file of impeccable timing and feel. Here is an example song:</p>
    <p><pre><code>Song:
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
  - deep:     .............X..</code></pre></p>
    <p>And here&rsquo;s what it sounds like after getting the Beats treatment:</p>
    <p><audio class="home-page" src="/media/beat.mp3" controls>Your browser can't play this audio file.</audio></p>
    <p>What a glorious groove!</p>
    <p class="last">So go forth and <a href="/download/">install Beats</a>, download some <a href="/download#drum-kits">drum sounds</a>, and <a href="/examples/">listen to some examples</a>. Then read up on <a href="/strategyguide/">how to use it</a>.</p>
  </div>
<? drawFooter(); ?>
