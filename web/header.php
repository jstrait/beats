<?
function drawHeader() {
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <title>Beats Drum Machine</title>
  <meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
  <meta name="description" content="A command-line drum machine written in Ruby." />
  <link rel="stylesheet" type="text/css" media="all" href="/beats.css" />
  <link rel="icon" type="image/png" href="/favicon.png">
</head>
<body>
  <div class="menubar">
    <ul>
      <li><a href="/">Home</a></li>
      <li><a href="/download/">Download</a></li>
      <li><a href="/examples/">Examples</a></li>
      <li><a href="/strategyguide/">Strategy Guide</a></li>
    </ul>
  </div>
<? }

function drawFooter() {
?>
  <div id="about" class="content-box">
    <p>Copyright &copy; 2010-17 <a href="http://www.joelstrait.com/">Joel Strait</a></p>
  </div>
  <script type="text/javascript">
  function toggleSource(toggleId, elementId) {
    var toggler = document.getElementById(toggleId);
    var element = document.getElementById(elementId);

    element.classList.toggle("display-none");
    toggler.innerText = (element.classList.contains("display-none")) ? "Show Source" : "Hide source";

    return false;
  };
  </script>
</body>
</html>
<? } ?>
