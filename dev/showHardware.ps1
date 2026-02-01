# Set-ExecutionPolicy -ExecutionPolicy Unrestricted   --||--   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

$sensors = Get-WmiObject -Namespace root/LibreHardwareMonitor -Query 'SELECT * FROM Sensor'
foreach ($sensor in $sensors) {
    #Write-Host -NoNewline "parent=$($sensor.Parent),type=$($sensor.SensorType),name=$($sensor.name) value=$($sensor.Value)`n"
    $sensor | ConvertTo-Json 
}

Pause

$hardware = Get-WmiObject -Namespace root/LibreHardwareMonitor -Query 'SELECT * FROM Hardware'
foreach ($item in $hardware) {
    $item | ConvertTo-Json 
}
