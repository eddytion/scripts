<?php
require("header.php");
error_reporting(E_ALL);
ini_set('display_errors', 1);
require 'config.php';
$hmc = filter_var($_GET['name'], FILTER_SANITIZE_STRING);
$hmc = mysqli_real_escape_string($db,$hmc);
echo "<div class=\"row justify-content-center align-items-center\">";
echo "<div class=\"col-md-2\">";
echo "<div class=\"card border-info mb-3\" style=\"max-width: 20rem;\">
                <div class=\"card-header\"><i class=\"fas fa-tv\"></i>&nbsp;{$hmc}</div>
                    <div class=\"card-body text-info\">
                    ";
$query_hmc_info = "select * from hmc where name='{$hmc}'";
$result_hmc_info = mysqli_query($db, $query_hmc_info);
if(mysqli_num_rows($result_hmc_info) > 0)
{
    while($row_hmc_info = mysqli_fetch_assoc($result_hmc_info))
    {
        echo "<p class=\"card-text\">";
        echo "<table class=\"table table-sm\">";
        echo "<tr>";
        echo "<td>Version: </td><td>" . $row_hmc_info['version'] . "</td>";
        echo "</tr><tr>";
        echo "<td>Serv Pack: </td><td>" . $row_hmc_info['servicepack'] . "</td>";
        echo "</tr><tr>";
        echo "<td>Model: </td><td>" . $row_hmc_info['model'] . "</td>";
        echo "</tr><tr>";
        echo "<td>Serial: </td><td>" . $row_hmc_info['serialnr'] . "</td>";
        echo "</tr><tr>";
        echo "<td>IP: </td><td>" . $row_hmc_info['ipaddr'] . "</td>";
        echo "</tr></table>";
        echo "</p>";
    }
}
echo "</div></div></div>";
?>
<script type="text/javascript">
  google.charts.load("current", {packages:["corechart"]});
    google.charts.setOnLoadCallback(drawChart);
    function drawChart() {
        var data = google.visualization.arrayToDataTable([
            ['HMC', 'NrOfEvents'],
            <?php
            $query_EventsByHMC = "SELECT count(*) as counter, failing_subsystem FROM asmi_events WHERE hmc='{$hmc}' GROUP BY failing_subsystem ";
            $result_EventsByHMC = mysqli_query($db, $query_EventsByHMC);
            while($row_EventsByHMC = mysqli_fetch_assoc($result_EventsByHMC))
            {
                echo("['" . str_replace("'","",$row_EventsByHMC['failing_subsystem']) . "', " . $row_EventsByHMC['counter'] . "],");
            }
            ?>
        ]);

        var options = {
            title: 'Events by failing subsystem',
            is3D: false,
            pieHole: 0.4,
            legend: {position: 'labeled'}
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart_3d_EventsByType'));
        chart.draw(data, options);
    }
</script>

<script type="text/javascript">
  google.charts.load("current", {packages:["corechart"]});
    google.charts.setOnLoadCallback(drawChart);
    function drawChart() {
        var data = google.visualization.arrayToDataTable([
            ['MS', 'NrOfEvents'],
            <?php
            $query_EventsByHMC = "SELECT count(*) as counter, msname FROM asmi_events WHERE hmc='{$hmc}' GROUP BY msname ";
            $result_EventsByHMC = mysqli_query($db, $query_EventsByHMC);
            while($row_EventsByHMC = mysqli_fetch_assoc($result_EventsByHMC))
            {
                echo("['" . str_replace("'","",$row_EventsByHMC['msname']) . "', " . $row_EventsByHMC['counter'] . "],");
            }
            ?>
        ]);

        var options = {
            title: 'Events by Managed System',
            is3D: false,
            pieHole: 0.4,
            legend: {position: 'labeled'}
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart_3d_EventsByMS'));
        chart.draw(data, options);
    }
</script>

    <div class="col-md-5">
        <div id="piechart_3d_EventsByType" style="width: 900px; height: 500px; display: block; margin: 0 auto;"></div>
    </div>
    <div class="col-md-5">
        <div id="piechart_3d_EventsByMS" style="width: 900px; height: 500px; display: block; margin: 0 auto;"></div>
    </div>
</div>
<?php
$query_hw_events = "SELECT * FROM asmi_events WHERE hmc='{$hmc}' ORDER BY timestamp DESC";
$result_hw_events = mysqli_query($db, $query_hw_events);
if (mysqli_num_rows($result_hw_events) > 0) {
    echo "<table class=\"table table-hover table-striped\" width=\"100%\">";
    echo "<thead>";
    echo "<tr>";
    echo "<th>MS Name</th>
                      <th>Log ID</th>
                      <th>TimeStamp</th>
                      <th>Failing Subsystem</th>
                      <th>Severity</th>
                      <th>SRC</th>
                      </thead></tr>
                      <tbody>";
    while ($row_hw_event = mysqli_fetch_assoc($result_hw_events)) {
        echo "<tr>";
        echo "<td>{$row_hw_event['msname']}</td>";
        echo "<td>{$row_hw_event['log_id']}</td>";
        echo "<td>{$row_hw_event['timestamp']}</td>";
        echo "<td>{$row_hw_event['failing_subsystem']}</td>";
        echo "<td>{$row_hw_event['severity']}</td>";
        echo "<td><i class=\"fas fa-search\"></i>&nbsp;<a href=\"https://www.ibm.com/support/home/search-results?q={$row_hw_event['src']}\" target=\"_blank\">{$row_hw_event['src']}</a></td>";
        echo "</tr>";
    }
    echo "</tbody></table>";
}