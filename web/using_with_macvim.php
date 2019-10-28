<? require_once("header.php");
   drawHeader(); ?>
<div class="content-box">
  <h2>Using Interactively With MacVim</h2>

  <p>With Beats Drum Machine you can use your favorite text editor to create beats. However, a drawback compared to GUI drum machines is that you have to switch back and forth between your text editor and the command line to hear your beat as you&rsquo;re working on it.</p>

  <p>But! What if I told you that you can script <a href="https://macvim-dev.github.io/macvim/">MacVim</a> so that you can listen to your beat while you&rsquo;re working on it, without having to switch to the command line? For example, on my machine I have it set up so that if I type <code>&lt;SPACE&gt;s</code> it will play the song in the current buffer. If I type <code>&lt;SPACE&gt;p</code> it figures out what pattern the cursor is inside, and plays that pattern. This turns MacVim into an interactive drum machine.</p>

  <p>To enable this, add the code below to your <code>.vimrc</code> file. This adds two new custom Vim commands, <code>:Song</code> and <code>:Pattern</code>. It also adds shortcuts: <code>&lt;LEADER&gt;s</code> for <code>:Song</code>, and <code>&lt;LEADER&gt;p</code> for <code>:Pattern</code>. On my machine, <code>&lt;LEADER&gt;</code> is set to the space character so these translate to <code>&lt;SPACE&gt;s</code> and <code>&lt;SPACE&gt;p</code>.</p>

  <pre><code>command -nargs=0 Song silent exec "w | ! beats % && afplay %:r.wav"
command -nargs=? Pattern silent exec BuildPatternCommand("&lt;args&gt;")
map &lt;silent&gt; &lt;Leader&gt;s :Song&lt;CR&gt;
map &lt;silent&gt; &lt;Leade&gt;>p :Pattern&lt;CR&gt;

function BuildPatternCommand(...)
  let patternName = a:1
  if a:1 == ""
    let patternName = DetectCurrentPattern()
  endif

  return "w | ! beats -p " . patternName . " % && afplay %:r.wav"
endfunction

"Search backwards to find the previous line that starts with alphanumeric characters,
"which will indicate the name of the pattern the cursor is currently in.
function DetectCurrentPattern()
  let target_pattern  = '^\w\+'
  let target_line_num = search(target_pattern, 'bnW')

  if !target_line_num
    return ""
  else
    return matchstr(getline(target_line_num), target_pattern)
  endif
endfunction</code></pre>
</div>

<div class="content-box">
  <h2>Notes</h2>
  <p>Quit and restart MacVim for the changes in your <code>.vimrc</code> to take effect.</p>
  <p>To stop the song while it&rsquo;s playing, use <code>CTRL+C</code>.</p>
  <p>This should theoretically work with other versions of Vim besides MacVim, but I haven&rsquo;t tested it out. On Linux or Windows, you&rsquo;d need to replace <code>afplay</code> with an alternate command. A Google search indicates that play might be the command to use on Linux, but I haven&rsquo;t actually tested this out.
  <p>If the script is not working (i.e. you run a command and don&rsquo;t hear anything), try removing the silent declaration from the <code>:Song</code> and <code>:Pattern</code> commands. This will cause the output of the shell commands that are running to be displayed at the bottom of the MacVim window, which might reveal the particular error.</p>
  </ul>
</div>
<? drawFooter(); ?>
