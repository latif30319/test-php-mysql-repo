<?php
$servername = "mysql";
$username = "root";
$password = "Ret0@l012990";
$dbname = "latif-mysqldb";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
} 
echo "Connected successfully<br>";
$arrChartData[] = array();
$sql = "SELECT name, owner, species FROM pet";
$result = $conn->query($sql) or trigger_error($conn->error."[$sql]");

$row = $result->fetch_array(MYSQLI_ASSOC);
while($row = $result->fetch_assoc()) {
    $arrChartData[] = $row;
    printf ("%s %s\n", $row["name"], $row["owner"]);
    echo "<br>";
}

if ($result->num_rows > 0) {
    // output data of each row
    while($row = $result->fetch_assoc()) {
        echo "<br> name: ". $row["name"]. " - Owner: ". $row["owner"]. " " . $row["species"] . "<br>";
    }
} else {
    echo "0 results";
}

$conn->close();
echo phpinfo();
?>
