<?php

require 'header2.php';
if (isset($_GET['hmc']) && isset($_GET['event_id'])) {
    $hmc = filter_var($_GET['hmc'], FILTER_SANITIZE_STRING);
    $event_id = filter_var($_GET['event_id'], FILTER_SANITIZE_NUMBER_INT);

    $cmd = "/var/www/html/cloud/scripts/chsvcevent.py " . $hmc . " " . $event_id;

    echo '<pre>';
    print(shell_exec($cmd));
    echo '</pre>';
}