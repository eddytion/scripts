<?php
require("header2.php");
?>
<link href="https://cdnjs.cloudflare.com/ajax/libs/datatables/1.10.12/css/dataTables.bootstrap4.min.css" rel="stylesheet"/>
<script src="https://cdnjs.cloudflare.com/ajax/libs/datatables/1.10.12/js/jquery.dataTables.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/datatables/1.10.13/js/dataTables.bootstrap4.min.js"></script>
<script type="text/javascript">
$(document).ready(function() {
    $('#adapters').DataTable(
            {
                fixedHeader: true,
                orderMulti: true,
                responsive: true,
                paging: false,
                info: false,
                searching: false,
                autoWidth: false,
                columnDefs: [
                    { "width": "20%", "targets": 0 }
                ]
            }
            );
});
</script>
<?php
if(isset($_GET['msname']) && is_string($_GET['msname']))
{
    $ms = filter_var($_GET['msname'],FILTER_SANITIZE_STRING);
    require("config.php");
    if(!$db)
    {
	die("Conn failed: " . mysqli_connect_error());
    }
    else
    {
        $sql="SELECT DISTINCT ms_name,lpar_name,unit_phys_loc,phys_loc,drc_name,description
              FROM `ms_io` WHERE ms_name='{$ms}' AND description !='Empty_slot' AND lpar_name !='null' ORDER BY phys_loc";
        $result = mysqli_query($db,$sql);
        if (mysqli_num_rows($result) > 0)
	{
		echo "<table class=\"table table-hover\" style=\"width:100%\" id=\"adapters\">";
		echo "<thead><tr>";
		echo "<th>MS Name</th>
		      <th>Phys Loc</th>
		      <th>Description</th>
		      <th>Assigned to</th>
                      <th>DRC Name</th>";
                echo "</tr></thead><tbody>";
		while($row = mysqli_fetch_assoc($result)) 
		{
			echo "<tr>";
			echo "<td>" . $row["ms_name"] . "</td><td>" . 
                             $row["unit_phys_loc"] . "-" . $row["phys_loc"] . "</td><td>" . 
                             $row["description"] . "</td><td>" .
                             $row["lpar_name"] . "</td><td>" .
                             $row["drc_name"] . "</td>";
			echo "</tr>";
		}
	}
	else
	{
	    echo "0 results";
	}
        
        $sql2 = "SELECT DISTINCT ms_name,phys_loc,parent,lpar_name,description FROM `ms_io_subdev` WHERE ms_name ='{$ms}' AND lpar_name !=''";
        $result2 = mysqli_query($db, $sql2);
        if(mysqli_num_rows($result2) > 0)
        {
            while($row = mysqli_fetch_assoc($result2)) 
		{
			echo "<tr>";
			echo "<td>" . $row["ms_name"] . "</td><td>" . 
                             $row["parent"] . "</td><td>" . 
                             $row["description"] . "</td><td>" .
                             $row["lpar_name"] . "</td><td>" .
                             $row["phys_loc"] . "</td>";
			echo "</tr>";
		}
        }
        echo "</tbody></table>";
	mysqli_close($db);
    }
}
else
{
    die("<h2>Bad Request</h2>");
}
