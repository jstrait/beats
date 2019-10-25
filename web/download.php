<? require_once("header.php");
   drawHeader(); ?>
  <div class="content-box">
    <h2>Installing Beats</h2>
    <p>Run the following from the command line:</p>
    <p><pre class="single-line"><code>gem install beats</code></pre></p>
    <p>This will download Beats from <a href="http://rubygems.org/gems/beats">rubygems.org</a> and add a <code>beats</code> command to your path.</p>
    <p>(Note that if you are installing using the default version of Ruby that comes with MacOS X, you might get a file permission error. If that happens, try <code>sudo gem install beats</code> instead. If you are using RVM or rbenv, plain <code>gem install beats</code> should work fine.)</p>
    <p>The current version of Beats is 2.1.1. If you have an older version, you can update with this:</p>
    <p><pre class="single-line"><code>gem update beats</code></pre></p>
    <p>Not sure what version you have? Run <code>beats -v</code>.</p>
  </div>
  <div class="content-box" id="drum-kits">
    <h2>Drum Sounds</h2>
    <p>Beats is not terribly useful unless you have drum sounds to use with it. You can use many wave files as drum sounds. Here are a few collections of sounds to help you get started:</p>
    <ul>
      <li id="drumkit-hammerhead" class="drumkit">
        <h3><a href="/hammerhead_drum_sounds.zip">Hammerhead</a></h3>
        <p>371 sounds extracted from various <a href="http://www.threechords.com/hammerhead/introduction.shtml">Hammerhead</a> sound banks using <a href="https://github.com/jstrait/clawhammer">Clawhammer</a>.</p>
        <ul class="sample-list">
          <li><label>acoustic_3_1.wav</label><audio src="/media/acoustic_3_1.wav" controls>Your browser can't play this audio file.</audio></li>
          <li><label>hh_909_clap.wav</label><audio src="/media/hh_909_clap.wav" controls>Your browser can't play this audio file.</audio></li>
          <li><label>jungle_3.wav</label><audio src="/media/jungle_3.wav" controls>Your browser can't play this audio file.</audio></li>
          <li><label>industrial_fx_4.wav</label><audio src="/media/industrial_fx_4.wav" controls>Your browser can't play this audio file.</audio></li>
        </ul>
      </li>
      <li id="drumkit-casio" class="drumkit">
        <h3><a href="/casio_sa20_drum_sounds.zip">Casio SA-20</a></h3>
        <p>20 <span style="text-decoration: line-through;">high quality</span> sounds sampled from a <a href="https://static.kupindoslike.com/Sintisajzer-CASIO-SA-20_slika_XL_69005915.jpg">Casio SA-20 keyboard</a> I got when I was 8 years old.</p>
        <ul class="sample-list">
          <li><label>bass.wav</label><audio src="/media/bass.wav" controls>Your browser can't play this audio file.</audio></li>
          <li><label>snare.wav</label><audio src="/media/snare.wav" controls>Your browser can't play this audio file.</audio></li>
          <li><label>hh_closed.wav</label><audio src="/media/hh_closed.wav" controls>Your browser can't play this audio file.</audio></li>
          <li><label>tom3.wav</label><audio src="/media/tom3.wav" controls>Your browser can't play this audio file.</audio></li>
        </ul>
      </li>
    </ul>
  </div>
  <div class="content-box">
    <h2>Source Code</h2>
    <p>It&#8217;s <a href="http://github.com/jstrait/beats">over at GitHub</a>.</p>
  </div>
  <div id="release-history" class="content-box">
    <h2>Release History</h2>
    <p>Visit <a href="https://github.com/jstrait/beats/releases">https://github.com/jstrait/beats/releases</a> to view info about past releases.</p>
  </div>
<? drawFooter(); ?>
