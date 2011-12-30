<? require_once("header.php");
   drawHeader(); ?>
  <div class="content-box">
    <h2 id="strategy-guide">BEATS Strategy Guide</h2>
    <p id="hot-tips">Hot tips, straight from the pros!</p>
    <p>BEATS runs from the command-line. The syntax:</p>
    <p><code><pre class="single-line">beats [options] INPUT [OUTPUT]</pre></code></p>
    <p><code>INPUT</code> is the YAML file for your song. <code>OUTPUT</code> is the <code>*.wav</code> file where BEATS will place the generated sound. If omitted, it will default to <code>INPUT</code> but with a <code>.wav</code> extension. (For example, the sound for <code>my_song.txt</code> would be saved to <code>my_song.wav</code>).</p>
    <p><code><pre class="single-line">beats example_song.txt beat.wav</pre></code></p>
    <p>BEATS supports the following command-line options, which can be used together or separately:</p>
    <p><code><pre>-s, --split
    Save each track to a separate Wave file,
    instead of combining them into one.

-p, --pattern PATTERN_NAME
    Only generate the pattern PATTERN_NAME,
    instead of the entire song.

--path BASE_PATH
    Look for song files with relative paths
    relative to BASE_PATH, instead of relative
    to the song file's path.

beats -s example_song.txt
beats -p Verse example_song.txt
beats --path ~/drum_sounds example_song.txt
</pre></code></p>
    <p>Finally, a note about Ruby 1.8.7 vs. 1.9.x. BEATS runs fine on both, but is more than 2x faster on 1.9.x. Therefore, it&#8217;s highly recommended that you use 1.9.x if possible.</p>
  </div>
  <div class="content-box">
    <h2>Creating Songs</h2>
    <p>Songs are notated using <a href="http://en.wikipedia.org/wiki/YAML">YAML</a>, so each song file is just a plain text file you can edit in TextEdit, VIM, or whatever. The file extension doesn&#8217;t matter.</p>
    <p>Each song is divided into one or more patterns. A pattern represents a section of the song, such as a verse, chorus, or bridge. Each pattern in turn has one or more tracks. Each track represents an individual sound, such as a bass drum, snare, or hi-hat.</p>
    <p>Songs should start with a header indicating the tempo, the structure of the song, and aliases for commonly used sounds. Here&#8217;s an example below. Since this is YAML, lines must be indented correctly. Also, each row in the Structure or Kit should be preceded by a dash.</p>
    <p><pre><code>Song:
  Tempo: 120
  Structure:
    - Verse:   x4
    - Chorus:  x2
    - Bridge:  x1
    - Verse:   x4
    - Chorus:  x2
  Kit:
    - bass:      sounds/808bass.wav
    - hh_closed: sounds/hihat_awesome.wav
    - hh_open:   sounds/hh_open.wav</code></pre></p>
    <p>The Kit section is optional, but the Structure is required.</p>
    <p>One or more patterns should follow the header. (If there are no patterns, there is nothing to play!) Each pattern definition starts with the pattern name, followed by the rhythm for each track on separate lines.</p>
    <p><pre><code>Verse:
  - bass:             X.......X.......
  - sounds/snare.wav: ....X.......X...
  - hh_closed:        X.X.X.X.X.X.X...
  - hh_open:          ..............X.
  - sounds/ride.wav:  X...............</code></pre></p>
    <p>Each track line starts with the sound file to use (8 and 16-bit Wave files are supported). You can either use a sound defined in the Kit section of the header, or alternately use a specific file name. (The example above mixes and matches). File paths can be relative or absolute; relative paths are relative from the path of the song file. Track lines must be indented properly and start with a dash (once again, due to this being YAML).</p>
    <p>The track rhythm follows the sound name. An <code>X</code> means that the sound should be triggered, and a <code>.</code> indicates a &#8220;rest&#8221; between triggers. Each <code>X</code> or <code>.</code> represents a 16th note. You only need to indicate the downbeat of each sound, since sounds will play their full duration (unless cut off by another trigger). For example, to play a quarter note rhythm, <code>X...X...X...X...</code> will do the trick.</p>
    <p>You can also use <code>|</code> as a bar line to mark measures or sections. These are totally optional, but can make patterns easier to read. BEATS ignores these, and you can put them wherever you want in the pattern.</p>
    <p>As a final note, patterns and the song header can come in any order. If you want to put the song header at the end of the file, you can. You can also mix up the order that patterns are defined.</p>
  </div>
<? drawFooter(); ?>
