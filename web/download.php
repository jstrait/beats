<? require_once("header.php");
   drawHeader(); ?>
  <div class="content-box">
    <h2>Installing Beats</h2>
    <p>Run the following from the command line:</p>
    <p><code><pre class="single-line">gem install beats</pre></code></p>
    <p>This will download Beats from <a href="http://rubygems.org/gems/beats">rubygems.org</a> and add a <code>beats</code> command to your path.</p>
    <p>(Note that if you are installing using the default version of Ruby that comes with MacOS X, you might get a file permission error. If that happens, try <code>sudo gem install beats</code> instead. If you are using RVM or rbenv, plain <code>gem install beats</code> should work fine.)</p>
    <p>The current version of Beats is 2.1.0. If you have an older version, you can update with this:</p>
    <p><code><pre class="single-line">gem update beats</pre></code></p>
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
        <p>20 <span style="text-decoration: line-through;">high quality</span> sounds sampled from a <a href="http://kepfeltoltes.hu/100407/Sa20_01_www.kepfeltoltes.hu_.jpg">Casio SA-20 keyboard</a> I got when I was 8 years old.</p>
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
    <h3 class="mt">2.1.0 &ndash; September 9, 2017</h3>
    <ul class="bulleted">
      <li>Multiple sound files can be used together as a "composite sound". Composite sounds can be defined in the Kit, or in an individual track.</li>
    </ul>
    <h3 class="mt">2.0.0 &ndash; September 4, 2017</h3>
    <ul class="bulleted">
      <li>Track rhythms can now have spaces in them. For example, <code>X... .... X... ....</code> is now a valid rhythm. Spaces are ignored, and don&rsquo;t affect the rhythm.</li>
      <li>Wave files using WAVEFORMATEXTENSIBLE format can now be used, due to upgrading the WaveFile gem dependency to v0.8.1 behind the scenes.</li>
      <li>Installing the gem is now simpler, since it no longer requires installing the legacy <code>syck</code> YAML parser via an extension.</li>
      <li>A &#8220;Fixnum is deprecated&#8221; message is no longer shown when using Ruby 2.4</li>
      <li>The minimum supported Ruby version is now 1.9.3, instead of 1.8.7</li>
      <li><em>Backwards incompatible:</em> Song files containing a <code>Structure</code> section are no longer supported. A <code>Flow</code> section should be used instead.</li>
      <li><em>Backwards incompatible:</em> Track rhythms can no longer start with a <code>|</code> character. For example, <code>|X...X...</code> is no longer a valid rhythm. However, bar lines are still allowed to appear elsewhere in the rhythm. For example, <code>X...X...|X...X...|</code> <em>is</em> a valid rhythm.</li>
    </ul>
    <h3 class="mt">1.3.0 &ndash; March 4, 2014</h3>
    <ul class="bulleted">
      <li>Songs can be swung (either by 8th note or 16th note), using the new <code>Swing</code> declaration in the song header.</li>
      <li>Support for fractional tempos, such as 100.5</li>
      <li>Bug fix: When you run the <code>beats</code> command with no arguments, it now displays the help screen, rather than an error message.</li>
    </ul>
    <h3 class="mt">1.2.5 &ndash; December 31, 2013</h3>
    <ul class="bulleted">
      <li>Tracks that start with a | no longer cause an error in Ruby 2.0 and above.</li>
      <li>Additional Wave file formats can now be used as samples, due to upgrading to WaveFile 0.6.0 behind the scenes: 24-bit PCM, 32-bit IEEE Float, 64-bit IEEE Float</li>
    </ul>
    <h3 class="mt">1.2.4 &ndash; December 22, 2012</h3>
    <ul class="bulleted">
      <li>Now fully supports MRI 1.9.3</li>
      <li>Now supports 32-bit PCM Wave files, due to upgrading to WaveFile 0.4.0. Previously, only 8-bit and 16-bit PCM files were supported.</li>
    </ul>
    <h3 class="mt">1.2.3 &ndash; December 31, 2011</h3>
    <ul class="bulleted">
      <li>Bug fix: You can now use <code>~</code> in sound file paths, and it will correctly expand to your home folder. (At least on UNIX OSes, I'm not sure if that works on Windows).</li>
      <li>The new <code>--path</code> option allows setting the base path from which relative sound file paths are searched for.</li>
    </ul>
    <h3 class="mt">1.2.2 &ndash; June 13, 2011</h3>
    <ul class="bulleted">
      <li>Bug fix: Compatibility issues with Windows. Thanks to Luis Lavena for mentioning the problem and how to fix it.</li>
      <li>Bug fix: Return the correct status code when Beats terminates, to improve scriptability.</li>
    </ul>
    <h3 class="mt">1.2.1 &ndash; March 6, 2011</h3>
    <ul class="bulleted">
      <li>You can use the <code>|</code> character to represent bar lines in a track rhythm. This is optional, but often makes longer rhythms easier to read.</li>
      <li>The "Structure" section of the song header is now called "Flow". (You can still use "Structure" for now, but you'll get a warning).</li>
      <li>A pattern can contain multiple tracks that use the same sound. Previously, Beats would pick one of those tracks as the 'winner', and the other tracks wouldn't be played.</li>
      <li>Bug fix: A better error message is displayed if a sound file is in an unsupported format (such as MP3), or is not even a sound file.</li>
    </ul>
    <h3 class="mt">1.2.0 &ndash; July 12, 2010</h3>
    <ul class="bulleted">
      <li>Major performance improvements. Up to 19x faster.</li>
    </ul>
    <h3 class="mt">1.1.0 &ndash; April 12, 2010</h3>
    <ul class="bulleted">
      <li>Performance improvement: about a 2x speedup. (When using the <code>-s</code> option, no speedup).</li>
      <li>Added support for a <code>Kit</code> section in song headers.</li>
      <li>Improved error messages displayed when song files have errors.</li>
    </ul>
    <h3 class="mt">1.0.0 &ndash; February 13, 2010</h3>
    <ul class="bulleted">
      <li>Initial version</li>
      <li>Support for using 8 or 16-bit, mono or stereo sounds.</li>
      <li>Support for the <code>-s</code> option, which saves each track to a separate file.</li>
      <li>Support for the <code>-p</code> option, which only generates a single pattern.</li>
    </ul>
  </div>
<? drawFooter(); ?>
