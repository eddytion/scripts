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
                $query_last_update = "SELECT date_insert FROM asmi_events ORDER BY date_insert DESC LIMIT 0,1";
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
            $query_EventsByType = "SELECT count(failing_subsystem) as counter, failing_subsystem FROM `asmi_events` GROUP BY failing_subsystem";
            $result_EventsByType = mysqli_query($db, $query_EventsByType);
            while($row_EventsByType = mysqli_fetch_assoc($result_EventsByType))
            {
                echo("['" . str_replace("'","",$row_EventsByType['failing_subsystem']) . "', " . $row_EventsByType['counter'] . "],");
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
            ['HMC', 'NrOfEvents'],
            <?php
            $query_EventsByHMC = "SELECT count(hmc) as counter, hmc FROM asmi_events GROUP BY hmc";
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
            window.open('asmi_report.php?name=' + hmc, '_blank');
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
          $query_map = "SELECT count(*) as counter, substring(hmc, 1, 2) as site FROM `asmi_events` GROUP by site";
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

        var options = {colorAxis: {colors: ['yellow', 'orange', 'red']}};
        var chart = new google.visualization.GeoChart(document.getElementById('event_maps'));
        
        function selectHandler() {
          var selectedItem = chart.getSelection()[0];
          if (selectedItem) {
            var site = data.getValue(selectedItem.row, 0);
            window.open('hmc_asmi_report_site.php?site=' + site, '_blank');
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

<div class="row">
    <?php
    
    $site_list = array();
    $defects = array();
    $hmc_list = array();
    
    $query = "SELECT * FROM sites";
    $result = mysqli_query($db, $query);
    while ($row = mysqli_fetch_assoc($result)) {
        $site_list[$row['id']] = $row['site_name'];
    }

    foreach ($site_list as $key => $value) {
        $query_hmc = "SELECT name FROM hmc WHERE site_id='{$key}'";
        $result_hmc = mysqli_query($db, $query_hmc);
        while ($row_hmc = mysqli_fetch_assoc($result_hmc)) {
            array_push($hmc_list, $row_hmc['name']);
        }

        foreach ($hmc_list as $value) {
            $query_hw_events = "SELECT * FROM asmi_events WHERE hmc='{$value}'";
            $result_hw_events = mysqli_query($db, $query_hw_events);
            while ($row_hw_events = mysqli_fetch_assoc($result_hw_events)) {
                if ($row_hw_events['hmc'] == $value) {
                    array_push($defects, $row_hw_events['hmc']);
                }
            }
        }
    }
    
    $sorted_errors = array_unique($defects);
    $sorted_ok = array_diff($hmc_list, $sorted_errors);
    foreach ($sorted_errors as $value)
    {
        echo "
            <div class=\"col-sm-2\">
                <div class=\"card border-danger mb-3\">
                  <div class=\"card-body text-danger\">
                    <h5 class=\"card-title\"><i class=\"fas fa-exclamation-triangle\"></i>&nbsp;<a href=\"https://{$value}\" class=\"text-info\" target=\"_blank\"><u>{$value}</u></a></h5>
                    <p class=\"card-text\">There are ASMI events for this HMC. Click on details to find more</p>
                    <a href=\"#hmcDetails\" data-toggle=\"modal\" data-hmcname=\"{$value}\" class=\"btn-link\">Details</a>
                        |
                    <a href=\"asmi_report.php?name={$value}\" target=\"_blank\" class=\"btn-link\">Report</a>
                  </div>
                </div>
            </div>
            ";
    }
    
    foreach ($sorted_ok as $value)
    {
        echo "
            <div class=\"col-sm-2\">
                <div class=\"card border-success mb-3\">
                  <div class=\"card-body text-success\">
                    <h5 class=\"card-title\"><i class=\"far fa-check-circle\"></i>&nbsp;<a href=\"https://{$value}\" class=\"text-success\" target=\"_blank\"><u>{$value}</u></a></h5>
                    <p class=\"card-text\">There are no ASMI events for this HMC.</p>
                  </div>
                </div>
            </div>
        ";
    }
?>
</div>
<style>
    .modal-lg {
        max-width: 70% !important;
    }
</style>
<!-- Modal -->
<div class="modal fade" id="hmcDetails" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-lg" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="exampleModalLabel">Details</h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <div class="modal-body" id="hmc_details">
        ...
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
      </div>
    </div>
  </div>
</div>

<!-- Modal asmi -->
<div class="modal fade" id="asmiDetails" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-lg" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="exampleModalLabel">ASMI Data</h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <div class="modal-body" id="asmi_details">
        ...
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
      </div>
    </div>
  </div>
</div>

<script>
$(document).ready(function(){ 
 $(".btn-link").on('click',function(){
    var hmc = $(this).attr('data-hmcname');

    $('.modal-body').html('loading data for ' + hmc);

       $.ajax({
        method: 'GET',
        url: 'asmi_data.php',
        data: {hmc: hmc},
        success: function(data) {
          $('#hmc_details').html(data);
          $('#hmcDetails').modal("show");
        },
        error:function(err){
          alert("error"+JSON.stringify(err));
          console.log(err.message);
        }
    });
 });
});
</script>