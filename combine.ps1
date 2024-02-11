Param(
    [String]$json1 = 'data1.json',
    [String]$json2 = 'data2.json' 
)

$d1 = (Get-Content $json1 | ConvertFrom-Json)
$d2 = (Get-Content $json2 | ConvertFrom-Json)

$d = $d1.data.locateVehiclesByZip.vehicleSummary
$d += $d2.data.locateVehiclesByZip.vehicleSummary

$d | ConvertTo-Json -Depth 4 | Out-File "data.json"