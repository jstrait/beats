<? require_once("header.php");
   drawHeader(); ?>
  <div class="content-box">
    <h2>Installing BEATS</h2>
    <p>Run the following from the command line:</p>
    <p><code><pre class="single-line">sudo gem install beats</pre></code></p>
    <p>This will download BEATS from <a href="http://rubygems.org/gems/beats">rubygems.org</a> and add a <code>beats</code> command to your path.</p>
    <p>The current version of BEATS is 1.2.0. If you have an older version, you can update with this:</p>
    <p><code><pre class="single-line">sudo gem update beats</pre></code></p>
    <p>Not sure what version you have? Run <code>beats -v</code>.</p>
  </div>
  <div class="content-box" id="drum-kits">
    <h2>Drum Sounds</h2>
    <p>BEATS is not terribly useful unless you have drum sounds to use with it. You can use many 8 and 16-bit wave files as drum sounds. Here are a few collections of sounds to help you get started:</p>
    <ul>
      <li id="drumkit-yamaha">
        <h3><a href="#">Yamaha</a></h3>
        <p>__ drum kits of varying styles sampled from a Yamaha PSR-520 keyboard.</p>
      </li>
      <li id="drumkit-casio">
        <h3><a href="/casio_sa20_drum_sounds.zip">Casio SA-20</a></h3>
        <p>20 <span style="text-decoration: line-through;">high quality</span> sounds sampled from a <a href="http://images.gittigidiyor.com/1882/Casio-SA-20-Tone-Bank-Elektronik-Klavye__18821134_0.jpg">Casio SA-20 keyboard</a> I got when I was 8 years old.</p>
        <ul>
          <li><label>bass.wav:</label><audio src="/media/bass.wav" controls></audio></li>
          <li><label>snare.wav:</label><audio src="/media/snare.wav" controls></audio></li>
          <li><label>hh_closed.wav:</label><audio src="/media/hh_closed.wav" controls></audio></li>
          <li><label>tom3.wav:</label><audio src="/media/tom3.wav" controls></audio></li>
        </ul>
      </li>
      <li id="drumkit-hammerhead">
        <h3><a href="#">Hammerhead</a></h3>
        <p>__ sounds liberated from various <a href="#">Hammerhead</a> drum machine sound banks using <a href="#">Clawhammer</a>.</p>
      </li>
    </ul>
  </div>
  <div class="content-box">
    <h2>Source Code</h2>
    <p>It&#8217;s <a href="http://github.com/jstrait/beats">over at GitHub</a>.</p>
  </div>
<? drawFooter(); ?>
