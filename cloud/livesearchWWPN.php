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
if (isset($_GET['q']) && is_string($_GET['q'])) {
    require 'config.php';
    $string = filter_var($_GET['q'], FILTER_SANITIZE_STRING);
    $string = str_replace(":", "", $string);
    $query = "SELECT * FROM vios_fc_wwpn WHERE wwpn LIKE '%{$string}%'";
    $result = mysqli_query($db, $query);
    if (mysqli_num_rows($result) > 0) {
        print "<table class=\"table\" width=\"100%\">";
        echo "<thead>";
        echo "<tr>";
        echo "<th>MS Name</th>
                      <th>Vios Name</th>
                      <th>FC Adapter</th>
                      <th>WWPN</th>
                      </tr>
                      </thead>
                      <tbody>";
        $counter = 0;
        while ($row = mysqli_fetch_assoc($result)) {
            if ($counter % 2 == 0) {
                $class = "even";
            } else {
                $class = "odd";
            }
            echo "<tr class=\"$class\" onmouseover=\"this.style.color='red'\" onmouseout=\"this.style.color='#566787'\">";
            echo "<td>{$row['ms_name']}</td>";
            echo "<td>{$row['vios_name']}</td>";
            echo "<td>{$row['fc_adapter']}</td>";
            echo "<td>{$row['wwpn']}</td>";
            echo "</tr>";
            $counter++;
        }
        echo "</tbody>";
        echo "</table>";
    }

    $query2 = "SELECT * FROM lpar_fc WHERE wwpns LIKE '%{$string}%'";
    $result2 = mysqli_query($db, $query2);
    if (mysqli_num_rows($result2) > 0) {
        print "<table class=\"table\" width=\"100%\">";
        echo "<thead>";
        echo "<tr>";
        echo "<th>LPAR Name</th>
                      <th>Adapter type</th>
                      <th>State</th>
                      <th>Remote LPAR</th>
                      <th>Remote Slot</th>
                      <th>WWPNS</th>
                      </tr>
                      </thead>
                      <tbody>";
        $counter = 0;
        while ($row2 = mysqli_fetch_assoc($result2)) {
            if ($counter % 2 == 0) {
                $class = "even";
            } else {
                $class = "odd";
            }
            echo "<tr class=\"$class\" onmouseover=\"this.style.color='red'\" onmouseout=\"this.style.color='#566787'\">";
            echo "<td>{$row2['lpar_name']}</td>";
            echo "<td>{$row2['adapter_type']}</td>";
            echo "<td>{$row2['state']}</td>";
            echo "<td>{$row2['remote_lpar']}</td>";
            echo "<td>{$row2['remote_slot_num']}</td>";
            echo "<td>{$row2['wwpns']}</td>";
            echo "</tr>";
            $counter++;
        }
        echo "</tbody>";
        echo "</table>";
    }
}