<?php require("header.php"); ?>
<br>
<hr>
<style>
    body{
        margin: 0;
        align-content: center;
        float: none;
        overflow: auto;
    }
</style>
<script type="text/javascript">
      google.charts.load('current', {'packages':['corechart']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {

        var data = google.visualization.arrayToDataTable([
          ['Task', 'Hours per Day'],
          <?php
          require("config.php");
          $sql = "SELECT lparos,count(lparos) as counter from lpar_ms WHERE lparos NOT LIKE '%Unknown%' AND lparos NOT LIKE 'VIOS%' GROUP BY lparos";
          $result = mysqli_query($db, $sql);
          while($row = mysqli_fetch_array($result))
          {
              print "['{$row['lparos']}', {$row['counter']}], \n";
          }
          ?>
        ]);

        var options = {
          title: 'AIX Levels',
          is3D: true,
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart'));

        chart.draw(data, options);
      }
    </script>
    <script type="text/javascript">
      google.charts.load('current', {'packages':['corechart']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {

        var data = google.visualization.arrayToDataTable([
          ['Task', 'Hours per Day'],
          <?php
          require("config.php");
          $sql = "SELECT fw_level,count(fw_level) as counter from ms_fw GROUP BY fw_level";
          $result = mysqli_query($db, $sql);
          while($row = mysqli_fetch_array($result))
          {
              print "['{$row['fw_level']}', {$row['counter']}], \n";
          }
          ?>
        ]);

        var options = {
          title: 'FW Levels',
          is3D: true,
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart2'));

        chart.draw(data, options);
      }
    </script>
    
    <script type="text/javascript">
      google.charts.load('current', {'packages':['corechart']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {

        var data = google.visualization.arrayToDataTable([
          ['Task', 'Hours per Day'],
          <?php
          require("config.php");
          $sql = "SELECT lparos,count(lparos) as counter from lpar_ms WHERE lparos NOT LIKE '%Unknown%' AND lparos NOT LIKE 'AIX%' GROUP BY lparos";
          $result = mysqli_query($db, $sql);
          while($row = mysqli_fetch_array($result))
          {
              print "['{$row['lparos']}', {$row['counter']}], \n";
          }
          ?>
        ]);

        var options = {
          title: 'VIO Levels',
          is3D: true,
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart3'));

        chart.draw(data, options);
      }
    </script>
    
    <script type="text/javascript">
      google.charts.load('current', {'packages':['corechart']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {

        var data = google.visualization.arrayToDataTable([
          ['Task', 'Hours per Day'],
          <?php
          require("config.php");
          $sql = "SELECT model,count(model) as counter from hmc WHERE model != '' GROUP BY model ";
          $result = mysqli_query($db, $sql);
          while($row = mysqli_fetch_array($result))
          {
              print "['{$row['model']}', {$row['counter']}], \n";
          }
          ?>
        ]);

        var options = {
          title: 'HMC Models',
          is3D: true,
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart4'));

        chart.draw(data, options);
      }
    </script>
    
    <script type="text/javascript">
      google.charts.load('current', {'packages':['corechart']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {

        var data = google.visualization.arrayToDataTable([
          ['Task', 'Hours per Day'],
          <?php
          require("config.php");
          $sql = "SELECT (SELECT count(*) FROM lpar_fc) as count_fc, (SELECT count(*) from lpar_scsi) as count_scsi";
          $result = mysqli_query($db, $sql);
          $row = mysqli_fetch_array($result);
          print "['NPIV', {$row['count_fc']}], \n";
          print "['vSCSI', {$row['count_scsi']}] \n";
          ?>
        ]);

        var options = {
          title: 'vSCSI vs NPIV Adapters',
          is3D: true,
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart5'));

        chart.draw(data, options);
      }
    </script>
    
    <script type="text/javascript">
      google.charts.load('current', {'packages':['corechart']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {

        var data = google.visualization.arrayToDataTable([
          ['Task', 'Hours per Day'],
          <?php
          require("config.php");
          $sql = "SELECT msmodel,count(msmodel) as counter from lpar_ms GROUP by msmodel";
          $result = mysqli_query($db, $sql);
          while($row = mysqli_fetch_array($result))
          {
              print "['{$row['msmodel']}', {$row['counter']}], \n";
          }
          ?>
        ]);

        var options = {
          title: 'LPARs by Power Models',
          is3D: true,
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart6'));

        chart.draw(data, options);
      }
    </script>
  </head>
    <div class="row">
        <div class="col-md-4">
        <div id="piechart" style="width: 750px; height: 500px;"></div>
        </div>
        
        <div class="col-md-4">
        <div id="piechart2" style="width: 750px; height: 500px;"></div>
        </div>
        
        <div class="col-md-4">
        <div id="piechart3" style="width: 750px; height: 500px;"></div>
        </div>
    </div>
      
      <div class="row">
        <div class="col-md-4">
        <div id="piechart4" style="width: 750px; height: 500px;"></div>
        </div>
          
        <div class="col-md-4">
        <div id="piechart5" style="width: 750px; height: 500px;"></div>
        </div>
          
        <div class="col-md-4">
        <div id="piechart6" style="width: 750px; height: 500px;"></div>
        </div>
    </div>
  </body>