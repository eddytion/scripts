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
        $sql="
        SELECT *
        FROM ms_fw
        WHERE ms_name=\"{$_GET['msname']}\" LIMIT 0,1";
        $result = mysqli_query($db,$sql);
        if (mysqli_num_rows($result) > 0) 
	{
		echo "<table class=\"table\">";
		echo "<tr>";
		echo "<th>MS Name</th>
		      <th>FW Level</th>";
		while($row = mysqli_fetch_assoc($result)) 
		{
			echo "<tr style=\"background-color:#CADEFA\">";
			echo "<td>" . $row["ms_name"] . "</td><td>" . 
                             $row["fw_level"] . "</td>";
			echo "</tr>";
                        echo "<tr>";
                        echo "<td colspan=\"2\">";
                        
                        $pieces_mtm = explode("-",$row['ms_name']);
                        $mtm = $pieces_mtm[1]."-".$pieces_mtm[2];   
                        
                        $pieces_fw = explode(":",$row['fw_level']);
                        if(strlen(trim($pieces_fw[1])) < 3)
                        {
                            $fw = substr($pieces_fw[0],2,5)."_"."0".$pieces_fw[1];
                        }
                        else
                        {
                            $fw = substr($pieces_fw[0],2,6)."_".$pieces_fw[1];
                        }
                        
                        echo "<iframe scrolling=\"no\" src=\"https://www14.software.ibm.com/webapp/set2/flrt/report?reportType=power&flrtData=&plat=power&p0.mtm={$mtm}&p0.fw={$fw}&p1.parnm=Partition+1&p1.os=aix&reportname=&btnGo=Submit#allPartitions\"></iframe>";
                        echo "</td>";
                        echo "</tr>";
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
