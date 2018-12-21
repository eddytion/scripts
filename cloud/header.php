<?php
if (substr_count($_SERVER['HTTP_ACCEPT_ENCODING'], 'gzip'))
{
    ob_start("ob_gzhandler");
}
else 
{
    ob_start();
}
date_default_timezone_set('Europe/Bucharest');
ini_set('session.cookie_httponly', 1);
ini_set('session.use_only_cookies', 1);
ini_set('session.cookie_secure', 1);

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <title>Cloud Systems</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css">
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.0/umd/popper.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.1.3/js/bootstrap.min.js"></script>
    <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.4.1/css/all.css" crossorigin="anonymous">
    <link rel="stylesheet" href="css/custom_table.css">
    <link rel="shortcut icon" type="image/x-icon" href="img/favicon.ico" />
    <!--[if lt IE 9]>
        <script src="js/html5shiv.js"></script>
    <![endif]-->
    <meta name="robots" content="noindex, nofollow" />
    <script type="text/javascript" src="js/jquery-1.7.1.js"></script>
    <script type="text/javascript" src="js/clipboardjs/dist/clipboard.min.js"></script>
    <script type="text/javascript" src="js/tablesort/jquery.tablesorter.min.js"></script>
<script>
function goBack() {
    window.history.back();
}
</script>
<!-- LPAR Search -->
<script>
function showResult(str) {
  if (str.length < 3) {
    document.getElementById("livesearch").innerHTML="";
    document.getElementById("livesearch").style.border="0px";
    return;
  }
  if (window.XMLHttpRequest) {
    // code for IE7+, Firefox, Chrome, Opera, Safari
    xmlhttp=new XMLHttpRequest();
  } else {  // code for IE6, IE5
    xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
  }
  xmlhttp.onreadystatechange=function() {
    if (this.readyState==4 && this.status==200) {
      document.getElementById("livesearch").innerHTML=this.responseText;
      document.getElementById("livesearch").style.border="1px solid #A5ACB2";
    }
  }
  xmlhttp.open("GET","livesearch.php?q="+str,true);
  xmlhttp.send();
}
</script>

<!-- MAC Addr Search -->

<script>
function showMAC(str) {
  if (str.length < 3) {
    document.getElementById("livesearchMAC").innerHTML="";
    document.getElementById("livesearchMAC").style.border="0px";
    return;
  }
  if (window.XMLHttpRequest) {
    // code for IE7+, Firefox, Chrome, Opera, Safari
    xmlhttp=new XMLHttpRequest();
  } else {  // code for IE6, IE5
    xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
  }
  xmlhttp.onreadystatechange=function() {
    if (this.readyState==4 && this.status==200) {
      document.getElementById("livesearchMAC").innerHTML=this.responseText;
      document.getElementById("livesearchMAC").style.border="1px solid #A5ACB2";
    }
  }
  xmlhttp.open("GET","livesearchMAC.php?q="+str,true);
  xmlhttp.send();
}
</script>

<!-- WWPN Search -->

<script>
function showWWPN(str) {
  if (str.length < 3) {
    document.getElementById("livesearchWWPN").innerHTML="";
    document.getElementById("livesearchWWPN").style.border="0px";
    return;
  }
  if (window.XMLHttpRequest) {
    // code for IE7+, Firefox, Chrome, Opera, Safari
    xmlhttp=new XMLHttpRequest();
  } else {  // code for IE6, IE5
    xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
  }
  xmlhttp.onreadystatechange=function() {
    if (this.readyState==4 && this.status==200) {
      document.getElementById("livesearchWWPN").innerHTML=this.responseText;
      document.getElementById("livesearchWWPN").style.border="1px solid #A5ACB2";
    }
  }
  xmlhttp.open("GET","livesearchWWPN.php?q="+str,true);
  xmlhttp.send();
}
</script>

<!-- HMC SN Search -->

<script>
function showHMCSN(str) {
  if (str.length < 3) {
    document.getElementById("livesearchHMCSN").innerHTML="";
    document.getElementById("livesearchHMCSN").style.border="0px";
    return;
  }
  if (window.XMLHttpRequest) {
    // code for IE7+, Firefox, Chrome, Opera, Safari
    xmlhttp=new XMLHttpRequest();
  } else {  // code for IE6, IE5
    xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
  }
  xmlhttp.onreadystatechange=function() {
    if (this.readyState==4 && this.status==200) {
      document.getElementById("livesearchHMCSN").innerHTML=this.responseText;
      document.getElementById("livesearchHMCSN").style.border="1px solid #A5ACB2";
    }
  }
  xmlhttp.open("GET","livesearchHMCSN.php?q="+str,true);
  xmlhttp.send();
}
</script>

<script type="text/javascript">
function popitup(url) {
	newwindow=window.open(url,'name','height=800,width=1200,scrollbars=yes,toolbar=no,menubar=no,directories=no,titlebar=no');
	if (window.focus) {newwindow.focus();}
	return false;
}
</script>
    <style>
        body
        {
            padding-top: 100px;
            font-family: 'Varela Round', sans-serif;
        }
    </style>
</head>
<body>
<nav class="navbar navbar-expand-sm bg-dark navbar-dark fixed-top">
    <a class="navbar-brand" href="#"><img src="img/unnamed.png" height="50" width="50"></a>
  <ul class="navbar-nav">
    <li class="nav-item active">
      <a class="nav-link" href="index.php">Systems</a>
    </li>
    <li class="nav-item active">
      <a class="nav-link" href="reports.php">Reports</a>
    </li>
    <li class="nav-item active">
      <a class="nav-link" href="vmware.php">VMWare</a>
    </li>
    <li class="nav-item active">
      <a class="nav-link" href="buildsheet.php">BuildSheet</a>
    </li>
    <li class="nav-item active">
      <a class="nav-link" href="hmc_hw_events.php">HMC HW Events</a>
    </li>
    
  <form class="form-inline">
    <div class="input-group">
      <div class="input-group-prepend">
        <span class="input-group-text"><i class="fas fa-desktop"></i></span>
      </div>
      <input type="text" class="form-control" placeholder="VM Search" id="search" onkeyup="showResult(this.value)">
    </div>    
  </form>
    &nbsp;
    <form class="form-inline">
    <div class="input-group">
      <div class="input-group-prepend">
        <span class="input-group-text"><i class="fas fa-network-wired"></i></span>
      </div>
      <input type="text" class="form-control" placeholder="MAC Address Search" id="searchMAC" onkeyup="showMAC(this.value)">
    </div>    
  </form>
    &nbsp;
  <form class="form-inline">
    <div class="input-group">
      <div class="input-group-prepend">
        <span class="input-group-text"><i class="fas fa-hdd"></i></span>
      </div>
      <input type="text" class="form-control" placeholder="WWPN Search" id="searchWWPN" onkeyup="showWWPN(this.value)">
    </div>    
  </form>
    &nbsp;
  <form class="form-inline">
    <div class="input-group">
      <div class="input-group-prepend">
        <span class="input-group-text"><i class="fas fa-laptop-code"></i></span>
      </div>
      <input type="text" class="form-control" placeholder="HMC SN Search" id="searchHMCSN" onkeyup="showHMCSN(this.value)">
    </div>    
  </form>
    
  </ul>
</nav>
<div id="livesearch">
        
</div>
<div id="livesearchMAC">
        
</div>
<div id="livesearchWWPN">
        
</div>
<div id ="livesearchHMCSN">
    
</div>