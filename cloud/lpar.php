<?php
require("header2.php");
if(isset($_GET['lpar']) && is_string($_GET['lpar']))
{
    $lpar = strip_tags(filter_var(trim($_GET['lpar']),FILTER_SANITIZE_STRING));
    $env = strip_tags(filter_var(trim($_GET['env']),FILTER_SANITIZE_STRING));
    
    echo "<link rel=\"stylesheet\" href=\"css/custom_table.css\">";
    //Get LPAR Memory details
    
    require("config.php");
    if(!$db)
    {
	die("Conn failed: " . mysqli_connect_error());
    }
    else
    {
       $sql="
       SELECT lpar_name,
       min_mem,
       desired_mem,
       max_mem,
       mem_mode
       FROM   mem_cpu_lpars
       WHERE lpar_name='$lpar'";
        $result = mysqli_query($db,$sql);
        if (mysqli_num_rows($result) > 0) 
	{
                echo "<h3><i class=\"fas fa-memory\"></i>&nbsp;LPAR Profile - Memory</h3>";
		echo "<table class=\"table table-hover\">";
		echo "<thead><tr>";
		echo "<th>Lpar Name</th>
		      <th>Min mem (GB)</th>
		      <th>Desired Mem (GB)</th>
		      <th>Max Mem (GB)</th>
		      <th>Memory Mode</th>";
                echo "</tr></thead>";
		while($row = mysqli_fetch_assoc($result)) 
		{
			echo "<tr>";
			echo "<td>" . $row["lpar_name"] . "</td><td>" . 
                             $row["min_mem"]/1024 . "</td><td>" . 
                             $row["desired_mem"]/1024 . "</td><td>" . 
                             $row["max_mem"]/1024 . "</td><td>" .
                             $row["mem_mode"] . "</td>";
			echo "</tr>";
		}
		echo "</table>";
	}
	else
	{
	    echo "<br>";
	}
	mysqli_close($db);
    }
        
    //Get LPAR CPU details
    
    require("config.php");
    if(!$db)
    {
	die("Conn failed: " . mysqli_connect_error());
    }
    else
    {
       $sql="
       SELECT lpar_name,
       proc_mode,
       min_proc_units,
       desired_proc_units,
       max_proc_units,
       min_procs,
       desired_procs,
       max_procs,
       sharing_mode,
       uncap_weight
       FROM mem_cpu_lpars
       WHERE  lpar_name='$lpar'";
        $result = mysqli_query($db,$sql);
        if (mysqli_num_rows($result) > 0) 
	{
                echo "<h3><i class=\"fas fa-microchip\"></i>&nbsp;LPAR Profile - CPU</h3>";
		echo "<table class=\"table table-hover\">";
		echo "<thead><tr>";
		echo "<th>Lpar Name</th>
		      <th>Processing mode</th>
		      <th>Min proc units</th>
		      <th>Desired proc units</th>
		      <th>Max proc units</th>
                      <th>Min virt proc</th>
		      <th>Desired virt proc</th>
		      <th>Max virt proc</th>
		      <th>Sharing mode</th>
                      <th>Weight</th>";
		echo "</tr></thead><tbody>";
		while($row = mysqli_fetch_assoc($result)) 
		{
			echo "<tr>";
			echo "<td>" . $row["lpar_name"] . "</td><td>" . 
                             $row["proc_mode"] . "</td><td>" . 
                             $row["min_proc_units"] . "</td><td>" . 
                             $row["desired_proc_units"] . "</td><td>" .
                             $row["max_proc_units"] . "</td><td>".
                             $row["min_procs"] . "</td><td>".
                             $row["desired_procs"] . "</td><td>".
                             $row["max_procs"] . "</td><td>".
                             $row["sharing_mode"] . "</td><td>".
                             $row["uncap_weight"] . "</td>";
			echo "</tr>";
		}
		echo "</tbody></table>";
	}
	else
	{
	    echo "<br>";
	}
	mysqli_close($db);
    }
    
    //Get LPAR ETH details
    
    require("config.php");
    if(!$db)
    {
	die("Conn failed: " . mysqli_connect_error());
    }
    else
    {
       $sql="
       SELECT *
       FROM   lpar_eth
       WHERE  lpar_name='$lpar'";
        $result = mysqli_query($db,$sql);
        if (mysqli_num_rows($result) > 0) 
	{
                echo "<h3><i class=\"fas fa-network-wired\"></i>&nbsp;LPAR Profile - ETH</h3>";
		echo "<table class=\"table table-hover\">";
		echo "<thead><tr>";
		echo "<th>Lpar Name</th>
                      <th>Slot Nr</th>
		      <th>Trunk [Y/N]</th>
		      <th>Port VLAN</th>
		      <th>V-Switch</th>
		      <th>MAC Address</th>";
		echo "</tr></thead>";
		while($row = mysqli_fetch_assoc($result)) 
		{
			echo "<tr>";
			echo "<td>" . $row["lpar_name"] . "</td><td>{$row['slot_num']}</td><td>"; 
                             if($row["is_trunk"] == 1) {echo "Y";} else { echo "N"; }
                             echo "</td><td>" . 
                             $row["port_vlan_id"] . "</td><td>" . 
                             $row["vswitch"] . "</td><td>" .
                             $row["mac_addr"] . "</td>";
			echo "</tr>";
		}
		echo "</table>";
	}
	else
	{
	    echo "<br>";
	}
	mysqli_close($db);
    }
    
    //Get LPAR FC details
    
    require("config.php");
    if(!$db)
    {
	die("Conn failed: " . mysqli_connect_error());
    }
    else
    {
       $sql="
        SELECT *
        FROM   lpar_fc
        WHERE  lpar_name='$lpar'";
        $result = mysqli_query($db,$sql);
        if (mysqli_num_rows($result) > 0) 
	{
                echo "<h3><i class=\"fas fa-hdd\"></i>&nbsp;LPAR Profile - FC</h3>";
		echo "<table class=\"table table-hover\">";
		echo "<thead><tr>";
		echo "<th>Lpar Name</th>
		      <th>Adapter Type</th>
		      <th>State</th>
		      <th>Remote Lpar</th>
		      <th>WWPNs</th>";
		echo "</tr></thead>";
		while($row = mysqli_fetch_assoc($result)) 
		{
			echo "<tr>";
			echo "<td>" . $row["lpar_name"] . "</td><td>" .
                             $row["adapter_type"] . "</td><td>" . 
                             $row["state"] . "</td><td>" . 
                             $row["remote_lpar"] . "</td><td>" .
                             $row["wwpns"] . "</td>";
			echo "</tr>";
		}
		echo "</table>";
	}
	else
	{
	    echo "<br>";
	}
	mysqli_close($db);
    }
    
    // GET SCSI LPAR Details
    
    require("config.php");
    if(!$db)
    {
	die("Conn failed: " . mysqli_connect_error());
    }
    else
    {
       $sql="
        SELECT *
        FROM   lpar_scsi
        WHERE  lpar_name='$lpar'";
        $result = mysqli_query($db,$sql);
        if (mysqli_num_rows($result) > 0) 
	{
                echo "<h3><i class=\"fas fa-hdd\"></i>&nbsp;LPAR Profile - vSCSI</h3>";
		echo "<table class=\"table table-hover\">";
		echo "<thead><tr>";
		echo "<th>Lpar Name</th>
		      <th>Adapter Type</th>
                      <th>Slot Nr</th>
		      <th>State</th>
		      <th>Remote Lpar</th>
		      <th>Remote Slot Nr</th>";
		echo "</tr></thead>";
		while($row = mysqli_fetch_assoc($result)) 
		{
			echo "<tr>";
			echo "<td>" . $row["lpar_name"] . "</td><td>" .
                             $row["adapter_type"] . "</td><td>" . 
                             $row["slot_num"]   . "</td><td>" . 
                             $row["state"] . "</td><td>" . 
                             $row["remote_lpar_name"] . "</td><td>" .
                             $row["remote_slot_num"] . "</td>";
			echo "</tr>";
		}
		echo "</table>";
	}
	else
	{
	    echo "<br>";
	}
	mysqli_close($db);
    }
    
    //GET VIOS WWPN
    
    if($env == "vioserver")
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
            FROM   vios_fc_wwpn
            WHERE  vios_name='$lpar'";
            $result = mysqli_query($db,$sql);
            if (mysqli_num_rows($result) > 0) 
            {
                    echo "<h3><i class=\"far fa-hdd\"></i>&nbsp;VIOS WWPNs</h3>";
                    echo "<table class=\"table table-hover\">";
                    echo "<thead><tr>";
                    echo "<th>MS Name</th>
                          <th>VIOS</th>
                          <th>FC Adapter</th>
                          <th>WWPN</th>";
                    echo "</tr></thead>";
                    while($row = mysqli_fetch_assoc($result)) 
                    {
                            echo "<tr>";
                            echo "<td>" . $row["ms_name"] . "</td><td>" .
                                 $row["vios_name"] . "</td><td>" . 
                                 $row["fc_adapter"]   . "</td><td>" . 
                                 $row["wwpn"] . "</td><td>";
                            echo "</tr>";
                    }
                    echo "</table>";
            }
            mysqli_close($db);
        }
    }
    
    //GET NPIV
    
    if($env == "vioserver")
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
            FROM   npiv
            WHERE  vios_name='$lpar'";
            $result = mysqli_query($db,$sql);
            if (mysqli_num_rows($result) > 0)
            {
                    echo "<h3><i class=\"far fa-hdd\"></i>&nbsp;VIOS NPIV</h3>";
                    echo "<table class=\"table table-hover\">";
                    echo "<thead><tr>";
                    echo "<th>MS Name</th>
                          <th>VIOS</th>
                          <th>Vfchost</th>
                          <th>Physical location</th>
                          <th>LPAR</th>
                          <th>Status</th>
                          <th>FC</th>
                          <th>FC loc code</th>
                          <th>VFC Client DRC</th>
                          ";
                    echo "</tr></thead>";
                    while($row = mysqli_fetch_assoc($result)) 
                    {
                            echo "<tr>";
                            echo "<td>" . $row["ms_name"] . "</td><td>" .
                                 $row["vios_name"] . "</td><td>" . 
                                 $row["vfchost"]   . "</td><td>" . 
                                 $row["physloc"] . "</td><td>" .
                                 $row["lpar_name"] . "</td><td>" .
                                 $row["status"] . "</td><td>" .
                                 $row["fc_name"] . "</td><td>" .
                                 $row["fc_loc_code"] . "</td><td>" .
                                 $row["vfc_client_drc"] . "</td><td>";
                            echo "</tr>";
                    }
                    echo "</table>";
            }
            mysqli_close($db);
        }
    }
}
else
{
    die("<h3>Bad Request</h3>");
}
