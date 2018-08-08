<?php
require("header2.php");
if(isset($_GET['hmc']) && is_string($_GET['hmc']))
{
    require("config.php");
    if(!$db)
    {
	die("Conn failed: " . mysqli_connect_error());
    }
    else
    {
        $sql="SELECT *
              FROM   hmc
              WHERE  name =\"{$_GET['hmc']}\"";
        $result = mysqli_query($db,$sql);
        if (mysqli_num_rows($result) > 0) 
	{
		echo "<table class=\"table\">";
		echo "<tr>";
		echo "<th>HMC Name</th>
		      <th>Version</th>
		      <th>Model</th>
		      <th>Serial Nr</th>
		      <th>IP Address</th>";
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
			echo "<td>" . $row["name"] . "</td><td>" . 
                             $row["version"] . " SP " . $row['servicepack'] . "</td><td>" . 
                             $row["model"] . "</td><td>" . 
                             $row["serialnr"] . "</td><td>" .
                             $row["ipaddr"] . "</td>";
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
