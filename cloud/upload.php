<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css">
<?php
if (isset($_POST["submit"])) {
    $file_name = '/var/www/html/cloud/uploads/' . $_POST['file_name'];
    $file2write = fopen($file_name,"w") or die("Unable to open file for writing, filename: " . $file_name);
    $content = base64_decode($_POST['content']);
    fwrite($file2write, $content);
    fclose($file2write);
} else {
    $http = $_SERVER['SERVER_PROTOCOL'];
    header("$http 405");
    die("<div class=\"alert alert-danger\" role=\"alert\">
            <strong>Error: </strong> Invalid request, do not access this page directly !
          </div>");
}