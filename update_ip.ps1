# Auto IP detection and backend startup script

$ip = (Get-NetIPAddress -AddressFamily IPv4 `
  | Where-Object { $_.InterfaceAlias -like "*Wi-Fi*" } `
  | Select-Object -First 1).IPAddress

if (-not $ip) {
  $ip = (Get-NetIPAddress -AddressFamily IPv4 `
    | Where-Object { $_.PrefixOrigin -eq "Dhcp" } `
    | Select-Object -First 1).IPAddress
}

if (-not $ip) { $ip = "localhost" }

Write-Host "IP: $ip"

# Update api_constants.dart
$file = "lib\core\constants\api_constants.dart"
$content = Get-Content $file -Raw
$updated = $content -replace "defaultValue: 'http://[^']*'", "defaultValue: 'http://${ip}:5291'"
Set-Content $file $updated -NoNewline
Write-Host "Updated api_constants.dart -> http://${ip}:5291"

# Check if backend already running on port 5291
$portCheck = netstat -ano | findstr ":5291"
if ($portCheck) {
  Write-Host "Backend already running, skip"
} else {
  Write-Host "Starting backend..."
  Start-Process powershell -ArgumentList `
    "-NoExit", `
    "-Command", `
    "cd '$PSScriptRoot\backend'; npm run dev" `
  -WindowStyle Normal
  Write-Host "Waiting for backend..."
  Start-Sleep -Seconds 3
  Write-Host "Backend ready!"
}