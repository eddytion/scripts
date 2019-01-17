<?php
require("header.php");
require("config_dashboard.php");
?>

<style>
    body{
        margin: 0;
        align-content: center;
        float: none;
        overflow: auto;
    }
</style>

<!-- VIOS LPM -->

<script type="text/javascript">
      google.charts.load('current', {'packages':['corechart']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {

        var data = google.visualization.arrayToDataTable([
            ['VIOS', 'LPM'],
<?php
$sql = "SELECT count(*) as counter, status FROM lpm GROUP by status";
$result = mysqli_query($db, $sql);
while ($row = mysqli_fetch_array($result)) {
    echo "['{$row['status']}', {$row['counter']}], \n";
}
?>
        ]);

        var options = {
            title: 'vioslpm0',
            is3D: false,
            pieHole: 0.4,
            legend: {position: 'labeled'}
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart'));

        chart.draw(data, options);
    }
</script>

<!-- max xfer size -->

<script type="text/javascript">
      google.charts.load('current', {'packages':['corechart']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {

        var data = google.visualization.arrayToDataTable([
            ['VIOS', 'LPM'],
<?php
$sql = "SELECT count(*) as counter, max_xfer_size FROM `fcs` GROUP BY max_xfer_size ";
$result = mysqli_query($db, $sql);
while ($row = mysqli_fetch_array($result)) {
    echo "['{$row['max_xfer_size']}', {$row['counter']}], \n";
}
?>
        ]);

        var options = {
            title: 'max_xfer_size',
            is3D: false,
            pieHole: 0.4,
            legend: {position: 'labeled'}
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart2'));

        chart.draw(data, options);
    }
</script>

<!-- num cmd elems -->

<script type="text/javascript">
      google.charts.load('current', {'packages':['corechart']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {

        var data = google.visualization.arrayToDataTable([
            ['VIOS', 'LPM'],
<?php
$sql = "SELECT count(*) as counter, num_cmd_elems FROM `fcs` GROUP BY num_cmd_elems ";
$result = mysqli_query($db, $sql);
while ($row = mysqli_fetch_array($result)) {
    echo "['{$row['num_cmd_elems']}', {$row['counter']}], \n";
}
?>
        ]);

        var options = {
            title: 'num_cmd_elems',
            is3D: false,
            pieHole: 0.4,
            legend: {position: 'labeled'}
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart3'));

        chart.draw(data, options);
    }
</script>

<!-- fc_err_recov -->

<script type="text/javascript">
      google.charts.load('current', {'packages':['corechart']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {

        var data = google.visualization.arrayToDataTable([
            ['VIOS', 'LPM'],
<?php
$sql = "SELECT count(*) as counter, fc_err_recov FROM `fscsi` GROUP BY fc_err_recov";
$result = mysqli_query($db, $sql);
while ($row = mysqli_fetch_array($result)) {
    echo "['{$row['fc_err_recov']}', {$row['counter']}], \n";
}
?>
        ]);

        var options = {
            title: 'fc_err_recov',
            is3D: false,
            pieHole: 0.4,
            legend: {position: 'labeled'}
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart4'));

        chart.draw(data, options);
    }
</script>

<!-- dyntrk -->

<script type="text/javascript">
      google.charts.load('current', {'packages':['corechart']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {

        var data = google.visualization.arrayToDataTable([
            ['VIOS', 'LPM'],
<?php
$sql = "SELECT count(*) as counter, dyntrk FROM `fscsi` GROUP BY dyntrk";
$result = mysqli_query($db, $sql);
while ($row = mysqli_fetch_array($result)) {
    echo "['{$row['dyntrk']}', {$row['counter']}], \n";
}
?>
        ]);

        var options = {
            title: 'dyntrk',
            is3D: false,
            pieHole: 0.4,
            legend: {position: 'labeled'}
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart5'));

        chart.draw(data, options);
    }
</script>

</head>
<div class="row">
    <div class="col-md-4">
        <div id="piechart" style="width: 700px; height: 500px;"></div>
    </div>

    <div class="col-md-4">
        <div id="piechart2" style="width: 700px; height: 500px;"></div>
    </div>

    <div class="col-md-4">
        <div id="piechart3" style="width: 700px; height: 500px;"></div>
    </div>
</div>

<div class="row">
    <div class="col-md-4">
        <div id="piechart4" style="width: 700px; height: 500px;"></div>
    </div>

    <div class="col-md-4">
        <div id="piechart5" style="width: 700px; height: 500px;"></div>
    </div>

    <div class="col-md-4">
        <div id="piechart6" style="width: 700px; height: 500px;"></div>
    </div>
</div>

<div class="row">
    <div class="col-md-4">
        <div id="piechart7" style="width: 700px; height: 500px;"></div>
    </div>

    <div class="col-md-4">
        <div id="piechart8" style="width: 700px; height: 500px;"></div>
    </div>

    <div class="col-md-4">
        <div id="piechart9" style="width: 700px; height: 500px;"></div>
    </div>
</div>
</body>