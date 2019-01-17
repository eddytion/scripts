<?php require("header.php"); ?>
<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
<script type="text/javascript">
  google.charts.load("current", {packages:["corechart"]});
    google.charts.setOnLoadCallback(drawChart);
    function drawChart() {
        var data = google.visualization.arrayToDataTable([
            ['Event', 'Nr'],
            <?php
            require 'config.php';
            $query_EventsByType = "SELECT count(guestfullname) as counter, guestfullname FROM vmware GROUP BY guestfullname";
            $result_EventsByType = mysqli_query($db, $query_EventsByType);
            while($row_EventsByType = mysqli_fetch_assoc($result_EventsByType))
            {
                echo("['" . str_replace("'","",$row_EventsByType['guestfullname']) . "', " . $row_EventsByType['counter'] . "],");
            }
            ?>
        ]);

        var options = {
            title: 'Guest OS by name',
            is3D: false,
            pieHole: 0.4,
            legend: {position: 'labeled'}
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart_3d_EventsByType'));
        chart.draw(data, options);
    }
</script>
<input type="text" id="searchvmw" onkeyup="vmSearch()" placeholder="Search for vms.." title="Type in a name">
<div id="piechart_3d_EventsByType" style="width: auto; height: 600px; display: block; margin: 0 auto;">

</div>
<div class="tables">
<br>
<br>

<?php
require("config.php");
if(!$db)
{
        die("Conn failed: " . mysqli_connect_error());
}
else
{
        $sql = "SELECT * FROM vmware";
        $result = mysqli_query($db,$sql);
        if (mysqli_num_rows($result) > 0) 
        {
                echo "<table class=\"table table-hover table-striped\" id=\"tblDataVMw\" width=\"100%\">";
                echo "<thead>";
                echo "<tr>";
                echo "<th>VM Name</th>
                      <th>UUID</th>
                      <th>CPU</th>
                      <th>Memory (MB)</th>
                      <th>State</th>
                      <th>OS Name</th>
                      <th>Config Version</th>
                      <th>IP Address</th>
                      </tr>
                      </thead>
                      <tbody>";
                while($row = mysqli_fetch_assoc($result))
                {
                    echo "<tr>";
                    echo "<td>{$row['vmname']}</td>";
                    echo "<td>{$row['uuid']}</td>";
                    echo "<td>{$row['numcpu']}</td>";
                    echo "<td>{$row['memory']}</td>";
                    echo "<td>{$row['gueststate']}</td>";
                    echo "<td>{$row['guestfullname']}</td>";
                    echo "<td>{$row['configversion']}</td>";
                    echo "<td>{$row['ipaddress']}</td>";
                    echo "</tr>";
                }
                echo "</tbody></table></div>";
        }
}
?>
<br>
<script>
function vmSearch() {
  // Declare variables
  var input, filter, table, tr, td, i, txtValue;
  input = document.getElementById("searchvmw");
  filter = input.value.toUpperCase();
  table = document.getElementById("tblDataVMw");
  tr = table.getElementsByTagName("tr");

  // Loop through all table rows, and hide those who don't match the search query
  for (i = 0; i < tr.length; i++) {
    td = tr[i].getElementsByTagName("td")[0];
    if (td) {
      txtValue = td.textContent || td.innerText;
      if (txtValue.toUpperCase().indexOf(filter) > -1) {
        tr[i].style.display = "";
      } else {
        tr[i].style.display = "none";
      }
    }
  }
}
</script>
