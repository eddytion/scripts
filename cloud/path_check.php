<?php
require("header.php");
require 'config.php';
error_reporting(E_ALL);
ini_set('display_errors', 1);
?>

<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
<script type="text/javascript">
  google.charts.load("current", {packages:["corechart"]});
    google.charts.setOnLoadCallback(drawChart);
    function drawChart() {
        var data = google.visualization.arrayToDataTable([
            ['Event', 'Nr'],
            <?php
            $query_EventsByType = "SELECT count(*) as counter,status FROM `path_check` WHERE status !='Enabled' GROUP by status";
            $result_EventsByType = mysqli_query($db, $query_EventsByType);
            while($row_EventsByType = mysqli_fetch_assoc($result_EventsByType))
            {
                echo("['" . str_replace("'","",$row_EventsByType['status']) . "', " . $row_EventsByType['counter'] . "],");
            }
            ?>
        ]);

        var options = {
            title: 'Paths by Status',
            is3D: false,
            pieHole: 0.4,
            legend: {position: 'labeled'},
            colors: ['yellow', 'orange', 'red', '#f3b49f', '#f6c7b6']
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart_3d_PathsByStatus'));
        chart.draw(data, options);
    }
</script>

<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
<script type="text/javascript">
  google.charts.load("current", {packages:["corechart"]});
    google.charts.setOnLoadCallback(drawChart);
    function drawChart() {
        var data = google.visualization.arrayToDataTable([
            ['Event', 'Nr'],
            <?php
            $query_EventsByType = "SELECT count(*) as counter, substring(vios, 1, 2) as site FROM path_check WHERE status='Failed' GROUP by site";
            $result_EventsByType = mysqli_query($db, $query_EventsByType);
            while($row_EventsByType = mysqli_fetch_assoc($result_EventsByType))
            {
                echo("['" . str_replace("'","",$row_EventsByType['site']) . "', " . $row_EventsByType['counter'] . "],");
            }
            ?>
        ]);

        var options = {
            title: 'Failed paths by site',
            is3D: false,
            pieHole: 0.4,
            legend: {position: 'labeled'}
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart_3d_PathsBySite'));
        chart.draw(data, options);
    }
</script>

<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript">
      google.charts.load('current', {
        'packages':['geochart'],
        'mapsApiKey': 'AIzaSyB9g-Erp8AJIcrFtfVthqWsdzbqw83Doe8'
      });
      google.charts.setOnLoadCallback(drawRegionsMap);

      function drawRegionsMap() {
        var data = google.visualization.arrayToDataTable([
          ['Site', 'Not enabled paths'],
          <?php
          $query_map = "SELECT count(*) as counter, substring(vios, 1, 2) as site FROM path_check WHERE status='Failed' GROUP by site";
          $result_map = mysqli_query($db, $query_map);
          $gb_uk = 0;
          while($row_map = mysqli_fetch_assoc($result_map))
          {
              if(strtoupper($row_map['site']) == "UK" || strtoupper($row_map['site']) == "GB")
              {
                $gb_uk += $row_map['counter'];
              }
              else
              {
                  echo("['" . strtoupper($row_map['site']) . "', " . $row_map['counter'] . "],");
              }
              if($gb_uk > 0)
              {
                echo("['" . "GB" . "', " . $gb_uk . "],");
              }
          }
          ?>
        ]);

        var options = {colorAxis: {colors: ['yellow', 'orange', 'red']}, title: 'Paths with status not Enabled'};
        var chart = new google.visualization.GeoChart(document.getElementById('paths_maps'));
        
        function selectHandler() {
          var selectedItem = chart.getSelection()[0];
          if (selectedItem) {
            var site = data.getValue(selectedItem.row, 0);
            window.open('path_report_site.php?site=' + site, '_blank');
          }
        }
        
        google.visualization.events.addListener(chart, 'select', selectHandler);
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

<div class="row">
    <div class="col-md-12">
        <div id="paths_maps" style="width: auto; height: 700px; display: block; margin: 0 auto;"></div>
    </div>
</div>