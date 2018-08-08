<?php
   define('DB_SERVER', 'localhost');
   define('DB_USERNAME', 'xxxxxxxxx');
   define('DB_PASSWORD', 'xxxxxxxxxx');
   define('DB_DATABASE', 'inventory');
   $db = mysqli_connect(DB_SERVER,DB_USERNAME,DB_PASSWORD,DB_DATABASE);
   if(mysqli_connect_errno())
   {
       print "<script>alert(\" Some error occured --> " . mysqli_connect_error() . "\")</script>";
   }
?>
