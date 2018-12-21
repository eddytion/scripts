<?php
header('Content-Type: application/json');
require '../config.php';
$query = "select * from lpar_ms";
$result = mysqli_query($db, $query);
$rows = array();
while($r = mysqli_fetch_assoc($result))
{
    $rows[] = $r;
}
print(json_encode($rows, JSON_PRETTY_PRINT));
