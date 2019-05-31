<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css">
<?php
require 'config.php';
$http = $_SERVER['SERVER_PROTOCOL'];
if (isset($_POST["submit"])) {
    $hmc = filter_var($_POST['hmc'], FILTER_SANITIZE_STRING);
    $file_name = 'uploads/events_' . $hmc . '.csv';
    $file2write = fopen($file_name,"w") or die("Unable to open file for writing, filename: " . $file_name);
    if(base64_encode(base64_decode($_POST['content'])) === $_POST['content'])
    {
        $content = base64_decode($_POST['content']);
        fwrite($file2write, $content);
        fclose($file2write);
        $query_delete = "DELETE FROM cloud.hw_events WHERE hmc='$hmc'";
        $result_delete = mysqli_query($db, $query_delete);
        if(mysqli_affected_rows($db) > 0)
        {
            echo "\nOK: Existing data for $hmc has been removed\n";
        }
        else
        {
            echo "\nWARN: Existing data for $hmc has not been removed or no data exists\n";
        }
        $query_add = "LOAD DATA INFILE '/var/www/html/cloud/$file_name' IGNORE INTO TABLE cloud.hw_events FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\\n'";
        $result_add = mysqli_query($db, $query_add);
        if(mysqli_affected_rows($db) > 0)
        {
            echo "\nOK: Data for $hmc has been uploaded\n";
            header("$http 200");
        }
        else
        {
            echo "\nWARN: Error encountered while adding data for $hmc into database\n";
            header("$http 500");
        }
    }
    else
    {
        echo "\nInvalid data received. Data must be base64 encoded.\n";
        fclose($file2write);
        header("$http 405");
    }
} else {
    header("$http 405");
    die("<div class=\"alert alert-danger\" role=\"alert\">
            <strong>Error: </strong> Invalid request, do not access this page directly !
          </div>");
}
