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
   <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css">
         <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js"></script> 
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.7/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.min.js"></script>
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.8.2/css/all.css">
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
<script type="text/javascript">
<!--
function popitup(url) {
	newwindow=window.open(url,'name','height=800,width=1200,scrollbars=yes,toolbar=no,menubar=no,directories=no,titlebar=no');
	if (window.focus) {newwindow.focus();}
	return false;
}

// -->
</script>
</head>
<body>