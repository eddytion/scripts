<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require 'config.php';
$hmc = $_GET['hmc'];
$hmc = mysqli_real_escape_string($db,$hmc);

$query_asmi_events = "SELECT * FROM asmi_events WHERE hmc='{$hmc}'";
$result_asmi_events = mysqli_query($db, $query_asmi_events);
if (mysqli_num_rows($result_asmi_events) > 0) {
    echo "<table class=\"table table-hover table-striped\" width=\"100%\">";
    echo "<thead>";
    echo "<tr>";
    echo "<th>HMC</th>
                      <th>MS Name</th>
                      <th>Log ID</th>
                      <th>Time</th>
                      <th>Failing Subsystem</th>
                      <th>Severity</th>
                      <th>SRC</th>
                      </thead></tr>
                      <tbody>";
    while ($row_asmi_event = mysqli_fetch_assoc($result_asmi_events)) {
        echo "<tr>";
        echo "<td>{$row_asmi_event['hmc']}</td>";
        echo "<td>{$row_asmi_event['msname']}</td>";
        echo "<td>{$row_asmi_event['log_id']}</td>";
        echo "<td>{$row_asmi_event['timestamp']}</td>";
        echo "<td>{$row_asmi_event['failing_subsystem']}</td>";
        echo "<td>{$row_asmi_event['severity']}</td>";
        echo "<td><a href=\"https://www.ibm.com/support/home/search-results?q={$row_asmi_event['src']}\"  target=\"_blank\">{$row_asmi_event['src']}</a></td>";
        echo "</tr>";
    }
    echo "</tbody></table>";
}
else
{
    echo "<p>No data available for {$hmc}</p>";
}