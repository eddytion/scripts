<?php
require("header.php");
error_reporting(E_ALL);
ini_set('display_errors', 1);
require 'config_events.php';
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
        echo "<td>Serial: </td><td>" . $row_hmc_info['serial_nr'] . "</td>";
        echo "</tr><tr>";
        echo "<td>IP: </td><td>" . $row_hmc_info['ip_addr'] . "</td>";
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
            $query_EventsByHMC = "SELECT count(*) as counter, text FROM hw_events WHERE hmc='{$hmc}' GROUP BY text ";
            $result_EventsByHMC = mysqli_query($db, $query_EventsByHMC);
            while($row_EventsByHMC = mysqli_fetch_assoc($result_EventsByHMC))
            {
                echo("['" . str_replace("'","",$row_EventsByHMC['text']) . "', " . $row_EventsByHMC['counter'] . "],");
            }
            ?>
        ]);

        var options = {
            title: 'Events by Type',
            is3D: false,
            pieHole: 0.4,
            legend: {position: 'labeled'}
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart_3d_EventsByType'));
        chart.draw(data, options);
    }
</script>
    <div class="col-md-10">
        <div id="piechart_3d_EventsByType" style="width: 900px; height: 500px; display: block; margin: 0 auto;"></div>
    </div>
</div>
<?php
$query_hw_events = "SELECT * FROM hw_events WHERE hmc='{$hmc}' ORDER BY pmh_num DESC";
$result_hw_events = mysqli_query($db, $query_hw_events);
if (mysqli_num_rows($result_hw_events) > 0) {
    echo "<table class=\"table table-hover table-striped\" width=\"100%\">";
    echo "<thead>";
    echo "<tr>";
    echo "<th>Problem Nr</th>
                      <th>PMH</th>
                      <th>Refcode</th>
                      <th>Status</th>
                      <th>First Time Reported</th>
                      <th>System</th>
                      <th>Failing MTMS</th>
                      <th>Enclosure MTMS</th>
                      <th>Error Text</th>
                      </thead></tr>
                      <tbody>";
    while ($row_hw_event = mysqli_fetch_assoc($result_hw_events)) {
        echo "<tr>";
        echo "<td>{$row_hw_event['problem_num']}</td>";
        if($row_hw_event['pmh_num'] == "")
        {
            echo "<td>N/A</td>";
        }
        else
        {
            echo "<td class=\"text-danger\">{$row_hw_event['pmh_num']}</td>";
        }
        echo "<td><i class=\"fas fa-search\"></i>&nbsp;<a href=\"https://www.ibm.com/support/home/search-results?q={$row_hw_event['refcode']}\" target=\"_blank\">{$row_hw_event['refcode']}</a></td>";
        echo "<td>{$row_hw_event['status']}</td>";
        echo "<td>{$row_hw_event['first_time']}</td>";
        echo "<td>{$row_hw_event['sys_name']}</td>";
        echo "<td>{$row_hw_event['sys_mtms']}</td>";
        echo "<td>{$row_hw_event['enclosure_mtms']}</td>";
        echo "<td>{$row_hw_event['text']}</td>";
        echo "</tr>";
    }
    echo "</tbody></table>";
}