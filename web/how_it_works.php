<? require_once("header.php");
   drawHeader(); ?>
<div class="content-box">
  <h2>How It Works</h2>
  <p>Every Beats song starts out life as a YAML file, and if lucky, undergoes a metamorphosis into a beautiful Wave file. Let&rsquo;s look at what happens during this process.</p>
</div>
<div class="content-box">
  <h2>Getting Started</h2>
  <p>When you install Beats, it adds <code>bin\beats</code> to your path. This is the entry point. It collects the command line arguments, and then calls <code>Beats.run()</code> (located in <code>lib/beats.rb</code>), which is the real driver of the program. When <code>Beats.run()</code> returns, <code>bin/beats</code> displays an exit message, or alternately lists any errors that occured.</p>
  <p><code>Beats.run()</code> sheperds the transformation of the YAML file into a Wave file, by calling the appropriate code to parse the YAML file, normalize the song into a standard format, convert the song into an equivalent song which will be generated faster, generate the song&rsquo;s audio data, and save it to disk. For more info on each of these steps, read on below.</p>
</div>
<div class="content-box">
  <h2>Song Parsing</h2>
  <p>The <code>SongParser</code> object parses a raw YAML song file and converts it into domain objects. It contains a single public method, <code>parse()</code>. The input is a raw YAML string, and the output is a <code>Song</code> object and a <code>Kit</code> object.</p>
  <p>A <code>Song</code> object is a container for <code>Pattern</code> objects (which are in turn containers for <code>Track</code> objects). It also stores the song flow (i.e. the order that patterns should be played). The flow is internally represented as an array of symbols. For example, when this song is parsed:</p>
  <p><pre><code>Song:
  Flow:
    - Verse:   x2
    - Chorus:  x4
    - Bridge:  x1
    - Chorus:  x1</code></pre></p>
  <p>the resulting <code>Song</code> object will have this flow:</p>
  <p><pre class="single-line"><code>[:verse, :verse, :chorus, :chorus, :chorus, :chorus, :bridge, :chorus]</code></pre></p>
  <p>A <code>Kit</code> object provides access to the raw sample data for each sound used in the song.</p>
  <p>The nice thing about YAML is that it&rsquo;s easy for humans to read and write, and support for parsing it is built into Ruby. For example, reading a YAML file from disk and converting it into a Ruby hash can be accomplished with one line of code:</p>
  <p><pre class="single-line"><code>hash = YAML.load(File.read("my_yaml_file.txt"))</code></pre></p>
  <p>Despite this, <code>SongParser</code> is still 200 or so lines long. This code is responsible for validating the parsed YAML file, and converting the raw hash into the <code>Song</code> and <code>Kit</code> domain objects.</p>
</div>
<div class="content-box">
  <h2>Song Normalization</h2>
  <p>After the YAML file is parsed and converted into a <code>Song</code> and <code>Kit</code>, the <code>Song</code> object is normalized to a standard format. This is done to allow the audio engine to be simpler.</p>

<p>As far as the audio engine knows there is only one type of song in the universe: one in which all patterns in the flow are played, and one in which all tracks are mixed together and written to a single Wave file. If that&rsquo;s the case though, then how do we deal with the <code>-p</code> option, which only writes a single pattern to the Wave file? Or the <code>-s</code> option, which saves each track to a separate wave file? You guessed it: normalization.</p>

<p>For example, when the <code>-p</code> option is used, the <code>Song</code> returned from <code>SongParser</code> is modified so that the flow only contains a single performance of the specified pattern. All other patterns are removed from the flow, and in fact the song itself.</p>

<p>Original Song:</p>

<p><pre><code>Song:
  Flow:
    - Verse: x2
    - Chorus: x4
    - Verse: x2
    - Chorus: x4

Verse:
  - bass.wav:   X...X...X...X...
  - snare.wav:  ....X.......X...

Chorus:
  - bass.wav:   X.............X.
  - snare.wav:  ....X.........X.</code></pre></p>

<p>After Normalization For <code>-p</code> Verse Option:</p>

<p><pre><code>Song:
  Flow:
    - Verse: x1

Verse:
  - bass.wav:   X...X...X...X...
  - snare.wav:  ....X.......X...
 </code></pre></p>

<p>When the <code>-s</code> option is used, the <code>Song</code> is split into multiple <code>Song</code>s that contain a single track. If the <code>Song</code> has a total of 5 tracks spread out over a few patterns, it will be split into 5 different <code>Song</code> objects that each contain a single <code>Track</code>.</p>

<p>The benefit of song normalization is to move complexity out of the audio domain and into the Ruby domain, where it is easier to deal with. For example, the output of the audio engine is arrays of integers thousands or even millions of elements long. If a test fails, it can be hard to tell why one long list of integers doesn&rsquo;t match the expected long list of integers. Song normalization reduces the number of tests of this type that need to be written. Normalization also allows the audio engine to be optimized more easily, by making the implementation simpler. Since the audio engine is where almost all of the run time is located, this is a win.</p>

<p>In contrast, normalizing <code>Song</code> objects is generally straightforward, easy to understand, and easy to test. For example, it&rsquo;s usually simple to build a test that verfies hash A is transformed into hash B.</p>
</div>
<div class="content-box">
  <h2>Song Optimization</h2>
  <p>After the <code>Song</code> object is normalized, the normalized <code>Song</code>(s) are further transformed into equivalent <code>Song</code> objects whose audio data can be generated more quickly by the audio engine.</p>

<p>As of version 1.3.0, optimization consists of two steps:</p>

<ol>
  <li>Breaking patterns into smaller pieces</li>
  <li>Replacing two different patterns that are equivalent with a single canonical pattern</li>
</ol>

<p>Performance tests show that (for example) generating audio for 4 patterns 4 steps long is faster that generating a single 16-step pattern. Generally, dealing with shorter arrays of sample data appears to be faster than really long arrays.</p>

<p>Replacing two patterns that have the same tracks with a single pattern allow for better caching by the audio engine. The audio engine will only ever generate the audio data for a pattern once, and will rely on a cached version each subsequent time it is played. If you have two patterns that are identical, the audio engine can end up generating audio data from scratch more often than is necessary.</p>

<p>Humans are probably not too likely to define identical patterns in a song. However, breaking patterns into smaller pieces can often allow pattern consolidation to "detect" duplicated rhythms inside (or across) patterns. So, these two optimizations actually work in concert. The nice thing about this is that caching algorithm is really dumb and simple to implement, but is effective.</p>

<p>The <code>SongOptimizer</code> class is used to perform optimization. It contains a single public method, <code>optimize()</code>, which takes a <code>Song</code> object and returns a <code>Song</code> object that is optimized.</p>
</div>
<div class="content-box">
  <h2>Audio Generation</h2>
  <p class="note">Before reading this section, it might be helpful to read up on the <a href="http://www.joelstrait.com/blog/2009/10/12/a_digital_audio_primer">basics on digital audio</a>, if you aren&rsquo;t already familiar.</p>

<p>All right! We&rsquo;ve now parsed our YAML file into <code>Song</code> and <code>Kit</code> domain objects, converted the <code>Song</code> into a canonical format, and optimized it. Now we&rsquo;re ready to actually generate some audio data.</p>

<p>At a high level, generating the song consists of iterating through the flow, generating the sample data for each pattern (or pulling it from cache), and then writing it to disk. The two main classes involved in this are <code>AudioEngine</code> and <code>AudioUtils</code>. <code>AudioEngine</code> is the main driver for generating audio data for each pattern, and writing it to disk. <code>AudioUtils</code>, as the name suggests, contains some general utility methods for working with audio data.</p>

<p>Audio generation begins at the track level. First, an array is created with enough samples for each step in the track at the specified tempo. Each sample is initialized to 0. Then, the sample data for the track&rsquo;s sound is "painted" onto the array at the appropriate places. The method that does all this is <code>AudioEngine.generate_track_sample_data()</code>.</p>

<p>Generating the sample data for a pattern consists of generating the sample data for each of it&rsquo;s tracks, and then mixing them into a single sample array. This is done using <code>AudioUtils.composite()</code>, which sums the corresponding samples from each array together. Each sample in the resulting array is then divided by a certain amount to prevent clipping.</p>

<p>Once each pattern is generated it can be written to disk. The <code>BeatsWaveFile</code> and <code>WaveFile</code> classes handle the details of creating the output wave file and writing lists of <code>FixNum</code> samples to the file in the correct format.</p>
</div>
<div class="content-box">
  <h2>Handling Overflow</h2>
  <p>One complication that arises is that the last sound triggered in a track can extend past the track&rsquo;s end (and therefore also its parent pattern&rsquo;s end). If this is not accounted for, then sounds will suddenly cut off once the track or the parent pattern ends. This can especially be a problem after song optimization, since this introduces additional sub-patterns. During playback sounds will continually cut off at seemingly random times.</p>

<p>To facilitate dealing with overflow, <code>AudioEngine.generate_track_sample_data()</code> actually returns two sample arrays: one containing the samples that occur during the normal track playback, and another containing samples that overflow into the next pattern.</p>

<p>When pattern audio is generated, overflow needs to be accounted for at the beginning and end of the pattern. <code>AudioEngine.generate_pattern_sample_data()</code> requires a hash of the overflow from each track in the preceding pattern in the flow, so that it can be inserted at the beginning of each track in the current pattern. This prevents sounds from cutting off each time a new pattern starts. The pattern must also return a hash of its outgoing overflow in addition to the composited primary sample data, so that the next pattern in the flow can use it.</p>
</div>
<div class="content-box">
  <h2>Performance Improvements Through Caching</h2>
  <p>Patterns are often played more than once in a song. After a pattern is generated the first time, it is cached so it doesn&rsquo;t have to be generated again.</p>

<p>There are actually two levels of pattern caching. The first level caches the result of compositing a pattern&rsquo;s track together. The second level caches the results of composited sample data converted into native Wave file format.</p>

<p>The reason for these two different caches has to do with overflow. The problem is that when caching composited sample data you have to store it in a format that will allow arbitrary incoming overflow to be applied at the beginning. Once sample data is converted into Wave file format, you can&rsquo;t do this. Cached data in wave file format is actually tied to specific incoming overflow. So if a pattern is occurs in a song 5 times with different incoming overflow each time, there will be a single copy in the 1st cache (with no overflow applied), and 5 copies in the wave 2nd cache (each with different overflow applied).</p>

<p>Track sample data is not cached, since performance tests show this only gives a very small performance improvement. Generating an individual track is relatively fast; it is compositing tracks together which is slow. This makes sense because painting sample data onto an array can be done with a single Ruby statement (and thus the bulk of the work and iteration is done at the C level inside the Ruby VM), whereas compositing sample data must be done at the Ruby level one sample at a time.</p>
</div>
<? drawFooter(); ?>
