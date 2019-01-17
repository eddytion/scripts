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
    $query = "SELECT * FROM hmc WHERE serialnr LIKE '%{$string}%' OR name LIKE '%{$string}%'";
    $result = mysqli_query($db, $query);
    if(mysqli_num_rows($result) > 0)
    {
        echo "<table class=\"table\" width=\"100%\">";
                echo "<thead>";
                echo "<tr>";
                echo "<th>HMC</th>
                      <th>Version</th>
                      <th>Service Pack</th>
                      <th>Model</th>
                      <th>Serial Nr</th>
                      <th>IP Addr</th>
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
                        echo "<td><a href=\"hmc.php?hmc={$row['name']}\" onclick=\"return popitup('hmc.php?hmc={$row['name']}')\">{$row['name']}</td>";
                        echo "<td>{$row['version']}</td>";
                        echo "<td>{$row['servicepack']}</td>";
                        echo "<td>{$row['model']}</td>";
                        echo "<td>{$row['serialnr']}</td>";
                        echo "<td>{$row['ipaddr']}</td>";
                        echo "</tr>";
                $counter++;
                }
                echo "</tbody>";
                echo "</table>";
    }
}