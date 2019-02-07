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
        <?php echo("<strong>Path status for {$string}</strong>"); ?>
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
        $query_EventsByType = "SELECT count(vios) as counter, vios FROM path_check WHERE status!='Enabled' AND (vios LIKE 'gb%' OR vios LIKE 'uk%') GROUP BY vios";
    } else {
        $query_EventsByType = "SELECT count(vios) as counter, vios FROM path_check WHERE status!='Enabled' AND vios LIKE '{$string}%' GROUP BY vios";
    }
    $result_EventsByType = mysqli_query($db, $query_EventsByType);
    while ($row_EventsByType = mysqli_fetch_assoc($result_EventsByType)) {
        echo("['" . str_replace("'", "", $row_EventsByType['vios']) . "', " . $row_EventsByType['counter'] . "],");
    }
    ?>
            ]);

            var options = {
                title: 'Path(s) not enabled by vios',
                is3D: false,
                pieHole: 0.4,
                legend: {position: 'labeled'}
            };

            var chart = new google.visualization.PieChart(document.getElementById('piechart_3d_PathsByStatus'));
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
        $query_EventsByHMC = "SELECT count(vios) as counter, status FROM path_check WHERE status!='Enabled' AND vios LIKE 'gb%' OR vios LIKE 'uk%' GROUP BY status";
    } else {
        $query_EventsByHMC = "SELECT count(vios) as counter, status FROM path_check WHERE status!='Enabled' AND vios LIKE '{$string}%' GROUP BY status";
    }
    $result_EventsByHMC = mysqli_query($db, $query_EventsByHMC);
    while ($row_EventsByHMC = mysqli_fetch_assoc($result_EventsByHMC)) {
        echo("['" . $row_EventsByHMC['status'] . "', " . $row_EventsByHMC['counter'] . "],");
    }
    ?>
            ]);

            var options = {
                title: 'Paths by status',
                is3D: false,
                pieHole: 0.4,
                legend: {position: 'labeled'}
            };

            var chart = new google.visualization.PieChart(document.getElementById('piechart_3d_PathsBySite'));
            chart.draw(data, options);
        }
    </script>
    <div class="row">
        <div class="col-md-6">
            <div id="piechart_3d_PathsByStatus" style="width: 900px; height: 500px; display: block; margin: 0 auto;"></div>
        </div>

        <div class="col-md-6">
            <div id="piechart_3d_PathsBySite" style="width: 900px; height: 500px; display: block; margin: 0 auto;"></div>
        </div>
    </div>
    <?php
    if ($string == "GB") {
        $query = "select * from path_check where status!='Enabled' AND (vios like 'gb%' OR vios LIKE 'uk%')";
    } else {
        $query = "select * from path_check where status!='Enabled' AND vios like '{$string}%'";
    }
    $result = mysqli_query($db, $query);
    if (mysqli_num_rows($result) > 0) {
        echo "<table class=\"table table-hover table-striped\" width=\"100%\">";
        echo "<thead>";
        echo "<tr>";
        echo "<th>VIOS</th>
                      <th>Status</th>
                      <th>Disk</th>
                      <th>Adapter</th>
                      <th>Parent</th>
                      </thead></tr>
                      <tbody>";
        while ($row_hw_event = mysqli_fetch_assoc($result)) {
            echo "<tr>";
            echo "<td><a href=\"lpar.php?lpar={$row_hw_event['vios']}&env=vioserver\" onclick=\"return popitup('lpar.php?lpar={$row_hw_event['vios']}&env=vioserver')\">{$row_hw_event['vios']}</a></td>";
            echo "<td>{$row_hw_event['status']}</td>";
            echo "<td>{$row_hw_event['disk']}</td>";
            echo "<td>{$row_hw_event['adapter']}</td>";
            echo "<td>{$row_hw_event['parent']}</td>";
            echo "</tr>";
        }
        echo "</tbody></table>";
    }
}