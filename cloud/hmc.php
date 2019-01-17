<?php
require("header2.php");
if(isset($_GET['hmc']) && is_string($_GET['hmc']))
{
    $hmc = filter_var($_GET['hmc'], FILTER_SANITIZE_STRING);
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
		echo "<thead><tr>";
		echo "<th>HMC Name</th>
		      <th>Version</th>
		      <th>Model</th>
		      <th>Serial Nr</th>
		      <th>IP Address</th>
                      </tr></thead><tbody>";
		while($row = mysqli_fetch_assoc($result)) 
		{
			echo "<tr>";
			echo "<td>" . $row["name"] . "</td><td>" . 
                             $row["version"] . " SP " . $row['servicepack'] . "</td><td>" . 
                             $row["model"] . "</td><td>" . 
                             $row["serialnr"] . "</td><td>" .
                             $row["ipaddr"] . "</td>";
			echo "</tr>";
		}
		echo "</tbody></table>";
	}
	else
	{
	    echo "0 results";
	}
    }
    echo "<hr><br>";
    echo "<div class=\"row\">";
    echo "<div class=\"col-sm-6\">";
    echo "<div class=\"card\">
                <div class=\"card-header\"><i class=\"fas fa-user\"></i>&nbsp;Customer Info for {$hmc}</div>
                    <div class=\"card-body text-info\">
                    ";
    $query_hmc_info = "select * from hmc where name='{$hmc}'";
    $result_hmc_info = mysqli_query($db, $query_hmc_info);
    if (mysqli_num_rows($result_hmc_info) > 0) {
        while ($row_hmc_info = mysqli_fetch_assoc($result_hmc_info)) {
            echo "<p class=\"card-text\">";
            echo "<table class=\"table table-sm\">";
            echo "<tr>";
            echo "<td>Company: </td><td>" . $row_hmc_info['admin_company_name'] . "</td>";
            echo "</tr><tr>";
            echo "<td>Contact Person: </td><td>" . $row_hmc_info['admin_name'] . "</td>";
            echo "</tr><tr>";
            echo "<td>Contact e-mail: </td><td>" . $row_hmc_info['admin_email'] . "</td>";
            echo "</tr><tr>";
            echo "<td>Contact phone: </td><td>" . $row_hmc_info['admin_phone'] . "</td>";
            echo "</tr><tr>";
            echo "<td>Customer Number: </td><td>" . $row_hmc_info['acct_customer_num'] . "</td>";
            echo "</tr></table>";
            echo "</p>";
        }
    }
    echo "</div></div></div>";
    
    echo "<div class=\"col-sm-6\">";
    echo "<div class=\"card\">
                <div class=\"card-header\"><i class=\"fas fa-map-marked-alt\"></i>&nbsp;HMC Location details for {$hmc}</div>
                    <div class=\"card-body text-info\">
                    ";
    $query_hmc_info = "select * from hmc where name='{$hmc}'";
    mysqli_set_charset($db, 'utf8');
    $result_hmc_info = mysqli_query($db, $query_hmc_info);
    if (mysqli_num_rows($result_hmc_info) > 0) {
        while ($row_hmc_info = mysqli_fetch_assoc($result_hmc_info)) {
            echo "<p class=\"card-text\">";
            echo "<table class=\"table table-sm\">";
            echo "<tr>";
            echo "<td>Datacenter: </td><td>" . $row_hmc_info['admin_addr'] . "</td>";
            echo "</tr><tr>";
            echo "<td>Address: </td><td>" . $row_hmc_info['admin_addr2'] . "</td>";
            echo "</tr><tr>";
            echo "<td>City: </td><td>" . $row_hmc_info['admin_city'] . "</td>";
            echo "</tr><tr>";
            echo "<td>Country & State: </td><td>" . $row_hmc_info['admin_country'] . " - " . $row_hmc_info['admin_state'] . "</td>";
            echo "</tr><tr>";
            echo "<td>Post code: </td><td>" . $row_hmc_info['admin_postal_code'] . "</td>";
            echo "</tr></table>";
            echo "</p>";
        }
    }
    echo "</div></div></div>";
}