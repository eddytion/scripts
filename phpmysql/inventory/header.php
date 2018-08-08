<?php
//header system details
if (substr_count($_SERVER['HTTP_ACCEPT_ENCODING'], 'gzip'))
{
    ob_start("ob_gzhandler");
}
else 
{
    ob_start();
}

if(file_exists("../maintenance/maintenance.mod"))
{
    header("Location: ../maintenance/index.php");
}
//error_reporting(E_ALL);
//ini_set('display_errors', 1);

date_default_timezone_set('Europe/Berlin');

// **PREVENTING SESSION HIJACKING**
// Prevents javascript XSS attacks aimed to steal the session ID
ini_set('session.cookie_httponly', 1);

// **PREVENTING SESSION FIXATION**
// Session ID cannot be passed through URLs
ini_set('session.use_only_cookies', 1);

// Uses a secure connection (HTTPS) if possible
ini_set('session.cookie_secure', 1);

?>
<!DOCTYPE html>
<html lang="en">
<head>
  <title>Cloud Systems</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.1.0/css/bootstrap.min.css">
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.0/umd/popper.min.js"></script>
  <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.1.0/js/bootstrap.min.js"></script>
  <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
  <link rel="shortcut icon" type="image/x-icon" href="img/favicon.ico" />
	<!--[if lt IE 9]>
		<script src="js/html5shiv.js"></script>
	<![endif]-->
	<meta name="robots" content="noindex, nofollow" />
        <script type="text/javascript" src="js/jquery-1.7.1.js"></script>
        <script type="text/javascript" src="js/clipboardjs/dist/clipboard.min.js"></script>
        <script type="text/javascript" src="js/tablesort/jquery.tablesorter.min.js"></script>
</head>
	<style type="text/css">	
	body {
                background-size: 100%;
	     }
        .even {
            background-color: #F0F0F6;
             }
        .odd {
            background-color: #fff;
             }
        </style>
<script>
function goBack() {
    window.history.back();
}
</script>
</head>
<body>
<script type="text/javascript">
<!--
function popitup(url) {
	newwindow=window.open(url,'name','height=800,width=1200,scrollbars=yes,toolbar=no,menubar=no,directories=no,titlebar=no');
	if (window.focus) {newwindow.focus();}
	return false;
}

// -->
</script>
<nav class="navbar navbar-expand-sm bg-dark navbar-dark fixed-top">
<a class="navbar-brand" href="#"><img src="img/favicon.ico" height="50" width="50"></a>
  <ul class="navbar-nav">
    <li class="nav-item active">
      <a class="nav-link" href="index.php">Systems</a>
    </li>
    <li class="nav-item active">
      <a class="nav-link" href="reports.php">Reports</a>
    </li>
  <form class="form-inline">
    <div class="input-group">
      <div class="input-group-prepend">
        <span class="input-group-text">@</span>
      </div>
      <input type="text" class="form-control" placeholder="LPAR Name" id="search">
    </div>    
  </form>
  </ul>
</nav>