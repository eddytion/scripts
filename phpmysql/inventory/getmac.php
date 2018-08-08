<?php
if(isset($_GET['lpar']) && is_string($_GET['lpar']))
{
require("config.php");
$lpar = mysqli_real_escape_string($db,$_GET['lpar']);

$query = "SELECT mac_addr FROM `lpar_eth` WHERE port_vlan_id='10' AND lpar_name='{$lpar}' LIMIT 0,1";
$result = mysqli_query($db, $query);
if(mysqli_num_rows($result) == 1)
{
    while($row = mysqli_fetch_array($result))
    {
        $mac = strtolower($row['mac_addr']);
        $mac_format = implode(":",  str_split($mac,2));
        print "$mac_format";
    }
}
elseif (mysqli_num_rows($result) > 1) 
{
    print "ERROR";
}
else
{
    print "NULL";
}
mysqli_close($db);
}
else
{
    print "Bad request";
}