<?php
require("header2.php");
if(isset($_GET['lpar']) && is_string($_GET['lpar']))
{
    require("config.php");
    if(!$db)
    {
	die("Conn failed: " . mysqli_connect_error());
    }
    else
    {
        $sql="
        SELECT *
        FROM   storage
        WHERE  lpar_name=\"{$_GET['lpar']}\" ORDER BY lun_serial ASC";
        $result = mysqli_query($db,$sql);
        if (mysqli_num_rows($result) > 0) 
	{
		echo "<table class=\"table\">";
		echo "<tr>";
		echo "<th>LPAR Name</th>
		      <th>Disk Size</th>
		      <th>Lun Name</th>
                      <th>Disk UID</th>
                      <th>I/O Group</th>";
		$counter=0;
		while($row = mysqli_fetch_assoc($result)) 
		{
		if($counter%2==0)
		{
		  $color="#CADEFA";
		}
		else
		{
		  $color="#FFFFFF";
		}
			echo "<tr style=\"background-color:$color\">";
			echo "<td>" . $row["lpar_name"] . "</td><td>" . 
                             ($row["disk_size"]/1024/1024/1024) . " GB</td><td>" . 
                             $row["lun_name"] . "</td><td>" . 
                                $row['lun_serial'] . "</td><td>" . 
                                $row['io_grp'] . "</td>";
			echo "</tr>";
 		$counter++;
		}
		echo "</table>";
	}
	else
	{
	    echo "0 results";
	}
	mysqli_close($db);
    }
}
else
{
    die("<h2>Bad Request</h2>");
}
