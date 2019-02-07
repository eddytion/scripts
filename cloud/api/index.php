<?php
require 'api_functions.php';

$data = strtolower(trim($_GET['action']));
$data = filter_var($data, FILTER_SANITIZE_STRING);
switch($data)
{
    case "asmi_data":
        getAsmiData();
        break;
    case "hmc_data":
        getHardwareEvents();
        break;
    default:
        print("Invalid data request");
        http_response_code(400);
        break;
}