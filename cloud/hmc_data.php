<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require 'config_events.php';
$hmc = $_GET['hmc'];
$hmc = mysqli_real_escape_string($db,$hmc);

$query_hw_events = "SELECT * FROM hw_events WHERE hmc='{$hmc}'";
$result_hw_events = mysqli_query($db, $query_hw_events);
if (mysqli_num_rows($result_hw_events) > 0) {
    echo "<table class=\"table table-hover table-striped\" width=\"100%\">";
    echo "<thead>";
    echo "<tr>";
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
    while ($row_hw_event = mysqli_fetch_assoc($result_hw_events)) {
        print "<tr>";
        print "<td>{$row_hw_event['problem_num']}</td>";
        if($row_hw_event['pmh_num'] == "")
        {
            print "<td>N/A</td>";
        }
        else
        {
            print "<td class=\"text-danger\">{$row_hw_event['pmh_num']}</td>";
        }
        print "<td><a href=\"https://www.ibm.com/support/home/search-results?q={$row_hw_event['refcode']}\"  target=\"_blank\">{$row_hw_event['refcode']}</a></td>";
        print "<td>{$row_hw_event['status']}</td>";
        print "<td>{$row_hw_event['first_time']}</td>";
        print "<td>{$row_hw_event['sys_name']}</td>";
        print "<td>{$row_hw_event['sys_mtms']}</td>";
        print "<td>{$row_hw_event['enclosure_mtms']}</td>";
        print "<td>{$row_hw_event['text']}</td>";
        print "</tr>";
    }
    print "</tbody></table>";
}