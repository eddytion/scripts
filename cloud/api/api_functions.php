<?php

function getVms()
{
    header('Content-Type: application/json');
    require '../config.php';
    $query = "select * from lpar_ms";
    $result = mysqli_query($db, $query);
    $rows = array();
    while($r = mysqli_fetch_assoc($result))
    {
        $rows[] = $r;
    }
    echo(json_encode($rows, JSON_PRETTY_PRINT));
}

function getAsmiData()
{
    header('Content-Type: application/json');
    require '../config.php';
    $query = "select * from asmi_events";
    $result = mysqli_query($db, $query);
    $rows = array();
    while($r = mysqli_fetch_assoc($result))
    {
        $rows[] = $r;
    }
    echo(json_encode($rows, JSON_PRETTY_PRINT));
}

function getHardwareEvents()
{
    header('Content-Type: application/json');
    require '../config.php';
    $query = "select * from hw_events where status='Open'";
    $result = mysqli_query($db, $query);
    $rows = array();
    while($r = mysqli_fetch_assoc($result))
    {
        $rows[] = $r;
    }
    echo(json_encode($rows, JSON_PRETTY_PRINT));
}