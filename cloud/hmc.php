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
    print "<hr><br>";
    print "<div class=\"row\">";
    print "<div class=\"col-sm-6\">";
    print "<div class=\"card\">
                <div class=\"card-header\"><i class=\"fas fa-user\"></i>&nbsp;Customer Info for {$hmc}</div>
                    <div class=\"card-body text-info\">
                    ";
    $query_hmc_info = "select * from hmc where name='{$hmc}'";
    $result_hmc_info = mysqli_query($db, $query_hmc_info);
    if (mysqli_num_rows($result_hmc_info) > 0) {
        while ($row_hmc_info = mysqli_fetch_assoc($result_hmc_info)) {
            print "<p class=\"card-text\">";
            print "<table class=\"table table-sm\">";
            print "<tr>";
            print "<td>Company: </td><td>" . $row_hmc_info['admin_company_name'] . "</td>";
            print "</tr><tr>";
            print "<td>Contact Person: </td><td>" . $row_hmc_info['admin_name'] . "</td>";
            print "</tr><tr>";
            print "<td>Contact e-mail: </td><td>" . $row_hmc_info['admin_email'] . "</td>";
            print "</tr><tr>";
            print "<td>Contact phone: </td><td>" . $row_hmc_info['admin_phone'] . "</td>";
            print "</tr><tr>";
            print "<td>Customer Number: </td><td>" . $row_hmc_info['acct_customer_num'] . "</td>";
            print "</tr></table>";
            print "</p>";
        }
    }
    print "</div></div></div>";
    
    print "<div class=\"col-sm-6\">";
    print "<div class=\"card\">
                <div class=\"card-header\"><i class=\"fas fa-map-marked-alt\"></i>&nbsp;HMC Location details for {$hmc}</div>
                    <div class=\"card-body text-info\">
                    ";
    $query_hmc_info = "select * from hmc where name='{$hmc}'";
    mysqli_set_charset($db, 'utf8');
    $result_hmc_info = mysqli_query($db, $query_hmc_info);
    if (mysqli_num_rows($result_hmc_info) > 0) {
        while ($row_hmc_info = mysqli_fetch_assoc($result_hmc_info)) {
            print "<p class=\"card-text\">";
            print "<table class=\"table table-sm\">";
            print "<tr>";
            print "<td>Datacenter: </td><td>" . $row_hmc_info['admin_addr'] . "</td>";
            print "</tr><tr>";
            print "<td>Address: </td><td>" . $row_hmc_info['admin_addr2'] . "</td>";
            print "</tr><tr>";
            print "<td>City: </td><td>" . $row_hmc_info['admin_city'] . "</td>";
            print "</tr><tr>";
            print "<td>Country & State: </td><td>" . $row_hmc_info['admin_country'] . " - " . $row_hmc_info['admin_state'] . "</td>";
            print "</tr><tr>";
            print "<td>Post code: </td><td>" . $row_hmc_info['admin_postal_code'] . "</td>";
            print "</tr></table>";
            print "</p>";
        }
    }
    print "</div></div></div>";
}