<?php
require("header.php");
require 'config.php';
error_reporting(E_ALL);
ini_set('display_errors', 1);
if (isset($_GET['site']) && is_string($_GET['site'])) {
    $string = filter_var($_GET['site'], FILTER_SANITIZE_STRING);
    $string = mysqli_real_escape_string($db, $string);
    ?>
    <div class="alert alert-dark" role="alert">
        <?php echo("<strong>ASMI Events for {$string}</strong>"); ?>
    </div>
    <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript">
        google.charts.load("current", {packages: ["corechart"]});
        google.charts.setOnLoadCallback(drawChart);
        function drawChart() {
            var data = google.visualization.arrayToDataTable([
                ['Event', 'Nr'],
    <?php
    if ($string == "GB") {
        $query_EventsByType = "SELECT count(failing_subsystem) as counter, failing_subsystem FROM `asmi_events` WHERE hmc LIKE 'gb%' OR hmc LIKE 'uk%' GROUP BY failing_subsystem";
    } else {
        $query_EventsByType = "SELECT count(failing_subsystem) as counter, failing_subsystem FROM `asmi_events` WHERE hmc LIKE '{$string}%' GROUP BY failing_subsystem";
    }
    $result_EventsByType = mysqli_query($db, $query_EventsByType);
    while ($row_EventsByType = mysqli_fetch_assoc($result_EventsByType)) {
        echo("['" . str_replace("'", "", $row_EventsByType['failing_subsystem']) . "', " . $row_EventsByType['counter'] . "],");
    }
    ?>
            ]);

            var options = {
                title: 'ASMI Events by type',
                is3D: false,
                pieHole: 0.4,
                legend: {position: 'labeled'}
            };

            var chart = new google.visualization.PieChart(document.getElementById('piechart_3d_EventsByType'));
            chart.draw(data, options);
        }
    </script>

    <script type="text/javascript">
        google.charts.load("current", {packages: ["corechart"]});
        google.charts.setOnLoadCallback(drawChart);
        function drawChart() {
            var data = google.visualization.arrayToDataTable([
                ['HMC', 'NrOfEvents'],
    <?php
    if ($string == "GB") {
        $query_EventsByHMC = "SELECT count(hmc) as counter, msname FROM asmi_events WHERE hmc LIKE 'gb%' OR hmc LIKE 'uk%' GROUP BY msname";
    } else {
        $query_EventsByHMC = "SELECT count(hmc) as counter, msname FROM asmi_events WHERE hmc LIKE '{$string}%' GROUP BY msname";
    }
    $result_EventsByHMC = mysqli_query($db, $query_EventsByHMC);
    while ($row_EventsByHMC = mysqli_fetch_assoc($result_EventsByHMC)) {
        echo("['" . $row_EventsByHMC['msname'] . "', " . $row_EventsByHMC['counter'] . "],");
    }
    ?>
            ]);

            var options = {
                title: 'ASMI Events by Managed System',
                is3D: false,
                pieHole: 0.4,
                legend: {position: 'labeled'}
            };

            var chart = new google.visualization.PieChart(document.getElementById('piechart_3d_EventsByHMC'));
            chart.draw(data, options);
        }
    </script>
    <div class="row">
        <div class="col-md-6">
            <div id="piechart_3d_EventsByType" style="width: 900px; height: 500px; display: block; margin: 0 auto;"></div>
        </div>

        <div class="col-md-6">
            <div id="piechart_3d_EventsByHMC" style="width: 900px; height: 500px; display: block; margin: 0 auto;"></div>
        </div>
    </div>
    <?php
    if ($string == "GB") {
        $query = "select * from asmi_events where hmc like 'gb%' OR hmc LIKE 'uk%' ORDER BY timestamp DESC";
    } else {
        $query = "select * from asmi_events where hmc like '{$string}%' ORDER BY timestamp DESC";
    }
    $result = mysqli_query($db, $query);
    if (mysqli_num_rows($result) > 0) {
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
        while ($row_hw_event = mysqli_fetch_assoc($result)) {
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
}