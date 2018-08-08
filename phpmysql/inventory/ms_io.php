<?php
require("header2.php");
if(isset($_GET['msname']) && is_string($_GET['msname']))
{
    require("config.php");
    if(!$db)
    {
	die("Conn failed: " . mysqli_connect_error());
    }
    else
    {
        $sql="SELECT *
              FROM   ms_io
              WHERE  ms_name =\"{$_GET['msname']}\" AND description !='Empty_slot' AND lpar_name !='null' ORDER BY lpar_name";
        $result = mysqli_query($db,$sql);
        if (mysqli_num_rows($result) > 0) 
	{
		echo "<table class=\"table table-hover\">";
		echo "<tr><thead>";
		echo "<th>MS Name</th>
		      <th>Unit Phys Loc</th>
		      <th>Phys Loc</th>
		      <th>Description</th>
		      <th>Assigned to</th>";
                echo "</thead><tbody>";
		while($row = mysqli_fetch_assoc($result)) 
		{
			echo "<tr>";
			echo "<td>" . $row["ms_name"] . "</td><td>" . 
                             $row["unit_phys_loc"] . "</td><td>" . 
                             $row["phys_loc"] . "</td><td>" . 
                             $row["description"] . "</td><td>" .
                             $row["lpar_name"] . "</td>";
			echo "</tr>";
		}
		echo "</tbody></table>";
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
