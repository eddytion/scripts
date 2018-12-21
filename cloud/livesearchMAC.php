<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css">
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.0/umd/popper.min.js"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.1.3/js/bootstrap.min.js"></script>
<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
<link rel="stylesheet" href="css/custom_table.css">
<br>
<br>
<br>
<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
if(isset($_GET['q']) && is_string($_GET['q']))
{
    require 'config.php';
    $string = filter_var($_GET['q'],FILTER_SANITIZE_STRING);
    $string = str_replace(":","", $string);
    $query = "select * from lpar_eth where mac_addr like '%{$string}%' OR lpar_name like '%{$string}%'";
    $result = mysqli_query($db, $query);
    if(mysqli_num_rows($result) > 0)
    {
        print "<table class=\"table\" width=\"100%\">";
                echo "<thead>";
                echo "<tr>";
                echo "<th>LPAR Name</th>
                      <th>Slot Nr</th>
                      <th>Trunk</th>
                      <th>Port Vlan ID</th>
                      <th>V-Switch</th>
                      <th>MAC Addr</th>
                      </tr>
                      </thead>
                      <tbody>";
                $counter=0;
                while($row = mysqli_fetch_assoc($result)) 
                {
                if($counter%2==0)
                {
                  $class="even";
                }
                else
                {
                  $class="odd";
                }
                        echo "<tr class=\"$class\" onmouseover=\"this.style.color='red'\" onmouseout=\"this.style.color='#566787'\">";
                        echo "<td>{$row['lpar_name']}</td>";
                        echo "<td>{$row['slot_num']}</td>";
                        echo "<td>{$row['is_trunk']}</td>";
                        echo "<td>{$row['port_vlan_id']}</td>";
                        echo "<td>{$row['vswitch']}</td>";
                        echo "<td>{$row['mac_addr']}</td>";
                        echo "</tr>";
                $counter++;
                }
                echo "</tbody>";
                echo "</table>";
    }
    
    $query = "SELECT DISTINCT ms_name,lpar_name,phys_loc,mac_addr FROM phys_mac WHERE mac_addr LIKE '%{$string}%'";
    $result = mysqli_query($db, $query);
    if(mysqli_num_rows($result) > 0)
    {
        print "<table class=\"table\" width=\"100%\">";
                echo "<thead>";
                echo "<tr>";
                echo "<th>MS Name</th>
                      <th>LPAR</th>
                      <th>Phys Loc</th>
                      <th>MAC Addr</th>
                      </tr>
                      </thead>
                      <tbody>";
                $counter=0;
                while($row = mysqli_fetch_assoc($result)) 
                {
                if($counter%2==0)
                {
                  $class="even";
                }
                else
                {
                  $class="odd";
                }
                        echo "<tr class=\"$class\" onmouseover=\"this.style.color='red'\" onmouseout=\"this.style.color='#566787'\">";
                        echo "<td>{$row['ms_name']}</td>";
                        echo "<td>{$row['lpar_name']}</td>";
                        echo "<td>{$row['phys_loc']}</td>";
                        echo "<td>{$row['mac_addr']}</td>";
                        echo "</tr>";
                $counter++;
                }
                echo "</tbody>";
                echo "</table>";
    }
}