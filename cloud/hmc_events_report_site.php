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
        <?php echo("<strong>Events for {$string}</strong>"); ?>
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
        $query_EventsByType = "SELECT count(text) as counter, text FROM `hw_events` WHERE hmc LIKE 'gb%' OR hmc LIKE 'uk%' GROUP BY text";
    } else {
        $query_EventsByType = "SELECT count(text) as counter, text FROM `hw_events` WHERE hmc LIKE '{$string}%' GROUP BY text";
    }
    $result_EventsByType = mysqli_query($db, $query_EventsByType);
    while ($row_EventsByType = mysqli_fetch_assoc($result_EventsByType)) {
        echo("['" . str_replace("'", "", $row_EventsByType['text']) . "', " . $row_EventsByType['counter'] . "],");
    }
    ?>
            ]);

            var options = {
                title: 'Events by type',
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
        $query_EventsByHMC = "SELECT count(hmc) as counter, hmc FROM hw_events WHERE hmc LIKE 'gb%' OR hmc LIKE 'uk%' GROUP BY hmc";
    } else {
        $query_EventsByHMC = "SELECT count(hmc) as counter, hmc FROM hw_events WHERE hmc LIKE '{$string}%' GROUP BY hmc";
    }
    $result_EventsByHMC = mysqli_query($db, $query_EventsByHMC);
    while ($row_EventsByHMC = mysqli_fetch_assoc($result_EventsByHMC)) {
        echo("['" . $row_EventsByHMC['hmc'] . "', " . $row_EventsByHMC['counter'] . "],");
    }
    ?>
            ]);

            var options = {
                title: 'Events by HMC',
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
        $query = "select * from hw_events where hmc like 'gb%' OR hmc LIKE 'uk%' ORDER BY pmh_num DESC";
    } else {
        $query = "select * from hw_events where hmc like '{$string}%' ORDER BY pmh_num DESC";
    }
    $result = mysqli_query($db, $query);
    if (mysqli_num_rows($result) > 0) {
        echo "<table class=\"table table-hover table-striped\" width=\"100%\">";
        echo "<thead>";
        echo "<tr>";
        if (isset($_GET['panel']) && $_GET['panel'] == "on") {
            echo "<th>Problem Nr</th>
                      <th>PMH</th>
                      <th>Refcode</th>
                      <th>Status</th>
                      <th>First Time Reported</th>
                      <th>System</th>
                      <th>Failing MTMS</th>
                      <th>Enclosure MTMS</th>
                      <th>Error Text</th>
                      <th>Close Event</th>
                      </thead></tr>
                      <tbody>";
        } else {
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
        }
        while ($row_hw_event = mysqli_fetch_assoc($result)) {
            echo "<tr>";
            echo "<td>{$row_hw_event['problem_num']}</td>";
            if ($row_hw_event['pmh_num'] == "") {
                echo "<td>N/A</td>";
            } else {
                echo "<td class=\"text-danger\">{$row_hw_event['pmh_num']}</td>";
            }
            echo "<td><a href=\"https://www.ibm.com/support/home/search-results?q={$row_hw_event['refcode']}\"  target=\"_blank\"><i class=\"fas fa-search\"></i>&nbsp;{$row_hw_event['refcode']}</a></td>";
            echo "<td>{$row_hw_event['status']}</td>";
            echo "<td>{$row_hw_event['first_time']}</td>";
            echo "<td>{$row_hw_event['sys_name']}</td>";
            echo "<td>{$row_hw_event['sys_mtms']}</td>";
            echo "<td>{$row_hw_event['enclosure_mtms']}</td>";
            echo "<td>{$row_hw_event['text']}</td>";
            if (isset($_GET['panel']) && $_GET['panel'] == "on") {
                echo "<td><a href=\"chsvcevent.php?hmc={$row_hw_event['hmc']}&event_id={$row_hw_event['problem_num']}\" onclick=\"return popitup('chsvcevent.php?hmc={$row_hw_event['hmc']}&event_id={$row_hw_event['problem_num']}')\" class=\"btn btn-primary\"><font color=\"#fff\">chsvcevent -o close -p " . $row_hw_event['problem_num'] . " -h " . $row_hw_event['hmc'] . "</font></a></td>";
            }
            echo "</tr>";
        }
        echo "</tbody></table>";
    }
}