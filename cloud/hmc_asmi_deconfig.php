<?php
require("header.php");
require 'config.php';
error_reporting(E_ALL);
ini_set('display_errors', 1);
?>
<div class="container-fluid">
    <div class="row">
        <div class="col-md-4 col-md-offset-1">
            <div class="alert alert-info" role="alert">
                <?php
                $query_last_update = "SELECT date_insert FROM asmi_deconfig ORDER BY date_insert DESC LIMIT 0,1";
                $result_last_update = mysqli_query($db, $query_last_update);
                while($row_last_update = mysqli_fetch_assoc($result_last_update))
                {
                    print("<b>Last update</b>: {$row_last_update['date_insert']} EET");
                }
                ?>
            </div>
        </div>
  </div>
</div>
<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
<script type="text/javascript">
  google.charts.load("current", {packages:["corechart"]});
    google.charts.setOnLoadCallback(drawChart);
    function drawChart() {
        var data = google.visualization.arrayToDataTable([
            ['Event', 'Nr'],
            <?php
            $query_EventsByType = "SELECT count(unit_type) as counter, unit_type FROM `asmi_deconfig` GROUP BY unit_type";
            $result_EventsByType = mysqli_query($db, $query_EventsByType);
            while($row_EventsByType = mysqli_fetch_assoc($result_EventsByType))
            {
                echo("['" . str_replace("'","",$row_EventsByType['unit_type']) . "', " . $row_EventsByType['counter'] . "],");
            }
            ?>
        ]);

        var options = {
            title: 'Events by failing unit type',
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
            ['HMC', 'NrOfEvents'],
            <?php
            $query_EventsByHMC = "SELECT count(hmc) as counter, hmc FROM asmi_deconfig GROUP BY hmc";
            $result_EventsByHMC = mysqli_query($db, $query_EventsByHMC);
            while($row_EventsByHMC = mysqli_fetch_assoc($result_EventsByHMC))
            {
                echo("['" . $row_EventsByHMC['hmc'] . "', " . $row_EventsByHMC['counter'] . "],");
            }
            ?>
        ]);

        var options = {
            title: 'Events by HMC (click on a slice for details)',
            is3D: false,
            pieHole: 0.4,
            legend: {position: 'labeled'}
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart_3d_EventsByHMC'));
        
        function selectHandler() {
          var selectedItem = chart.getSelection()[0];
          if (selectedItem) {
            var hmc = data.getValue(selectedItem.row, 0);
            window.open('asmi_report_deconfig.php?name=' + hmc, '_blank');
          }
        }

        google.visualization.events.addListener(chart, 'select', selectHandler);   
        
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
          ['Site', 'Opened HMC Events'],
          <?php
          $query_map = "SELECT count(*) as counter, substring(hmc, 1, 2) as site FROM `asmi_deconfig` GROUP by site";
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

        var options = {colorAxis: {colors: ['green', 'yellow', 'red']}};
        var chart = new google.visualization.GeoChart(document.getElementById('event_maps'));
        
        function selectHandler() {
          var selectedItem = chart.getSelection()[0];
          if (selectedItem) {
            var site = data.getValue(selectedItem.row, 0);
            window.open('hmc_asmi_report_deconfig_site.php?site=' + site, '_blank');
          }
        }
        
        google.visualization.events.addListener(chart, 'select', selectHandler);
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

<div class="row">
    <div class="col-md-12">
        <div id="event_maps" style="width: auto; height: 700px; display: block; margin: 0 auto;"></div>
    </div>
</div>