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
       SELECT ms_cpu.ms_name,
       ms_cpu.configurable_sys_proc_units,
       ms_cpu.curr_avail_sys_proc_units,
       ms_cpu.deconfig_sys_proc_units,
       ms_mem.configurable_sys_mem,
       ms_mem.curr_avail_sys_mem,
       ms_mem.deconfig_sys_mem,
       ms_mem.sys_firmware_mem,
       ms_mem.mem_region_size
       FROM   ms_cpu
       JOIN ms_mem
       ON ms_cpu.ms_name = ms_mem.ms_name
       WHERE  ms_cpu.ms_name = \"{$_GET['msname']}\"
       LIMIT 0,1";
        $result = mysqli_query($db,$sql);
        if (mysqli_num_rows($result) > 0) 
	{
		echo "<table class=\"table\">";
		echo "<thead><tr>";
		echo "<th>MS Name</th>
		      <th>Configurable sys procs</th>
		      <th>Available sys procs</th>
		      <th>Deconfig procs</th>
		      <th>Configurable sys mem (GB)</th>
                      <th>Available sys mem (GB)</th>
                      <th>Deconfig mem (GB)</th>
                      <th>Firmware mem (GB)</th>
                      <th>Mem region size (GB)</th>
                      </tr></thead><tbody>";
		$counter=0;
		while($row = mysqli_fetch_assoc($result)) 
		{
			echo "<tr>";
			echo "<td>" . $row["ms_name"] . "</td><td>" . 
                             $row["configurable_sys_proc_units"] . "</td><td>" . 
                             $row["curr_avail_sys_proc_units"] . "</td><td>" . 
                             $row["deconfig_sys_proc_units"] . "</td><td>" .
                             $row["configurable_sys_mem"]/1024 . "</td><td>" .
                             $row['curr_avail_sys_mem']/1024 . "</td><td>" .
                             $row['deconfig_sys_mem']/1024 . "</td><td>" .
                             $row['sys_firmware_mem']/1024 . "</td><td>" . 
                             $row['mem_region_size']/1024 . "</td>";
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
