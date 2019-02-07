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
          ['AU', 1],['BR', 24],['CA', 203],['CH', 29],['ES', 6],['NL', 34],['UK', 61],['US', 2],]);

        var options = {colorAxis: {colors: ['green', 'yellow', 'red']}};
        var chart = new google.visualization.GeoChart(document.getElementById('event_maps'));
        
        function selectHandler() {
          var selectedItem = chart.getSelection()[0];
          if (selectedItem) {
            var site = data.getValue(selectedItem.row, 0);
            window.open('hmc_report_site.php?site=' + site, '_blank');
          }
        }
        
        google.visualization.events.addListener(chart, 'select', selectHandler);
        chart.draw(data, options);
      }
    </script>
    <div class="row">
    <div class="col-md-12">
        <div id="event_maps" style="width: auto; height: 700px; display: block; margin: 0 auto;"></div>
    </div>
</div>