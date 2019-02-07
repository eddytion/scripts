<?php
if(isset($_GET['action']) && is_string($_GET['action']))
{
    $action = filter_var($_GET['action'], FILTER_SANITIZE_STRING);
    switch($action)
    {
        case "hmc_hw_events":
            include('hmc_hw_events.php');
            break;
        case "start":
            include('systems.php');
            break;
        case "reports":
            include('reports.php');
            break;
        case "vmware":
            include('vmware.php');
            break;
        case "hmc_asmi_events":
            include('hmc_asmi_events.php');
            break;
        case "hmc_asmi_deconfig":
            include('hmc_asmi_deconfig.php');
            break;
        case "path_check":
            include('path_check.php');
            break;
        default:
            include('systems.php');
            break;
    }
}
else
{
    header("Location: index.php?action=start");
}