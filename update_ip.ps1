# Auto IP, backend, ngrok - fully automatic

# Doc NGROK_AUTHTOKEN tu backend/.env
$envFile = "$PSScriptRoot\backend\.env"
$ngrokToken = $null
if (Test-Path $envFile) {
  Get-Content $envFile | ForEach-Object {
    if ($_ -match "^NGROK_AUTHTOKEN=(.+)$") {
      $ngrokToken = $matches[1].Trim()
    }
  }
}

# Config ngrok token neu chua co
if ($ngrokToken) {
  Write-Host "Configuring ngrok token..."
  & ngrok config add-authtoken $ngrokToken | Out-Null
  Write-Host "ngrok token configured!"
} else {
  Write-Host "Warning: NGROK_AUTHTOKEN not found in .env"
}

# Get WiFi IP
$ip = (Get-NetIPAddress -AddressFamily IPv4 `
  | Where-Object { $_.InterfaceAlias -like "*Wi-Fi*" } `
  | Select-Object -First 1).IPAddress

# Neu khong co WiFi, thu Ethernet (day cap)
if (-not $ip) {
  $ip = (Get-NetIPAddress -AddressFamily IPv4 `
    | Where-Object { $_.InterfaceAlias -like "*Ethernet*" } `
    | Select-Object -First 1).IPAddress
}

if (-not $ip) {
  $ip = (Get-NetIPAddress -AddressFamily IPv4 `
    | Where-Object { $_.PrefixOrigin -eq "Dhcp" } `
    | Select-Object -First 1).IPAddress
}

# Loai bo IP APIPA (169.254.x.x - khong co mang)
if ($ip -like "169.254.*") {
  Write-Host "WARNING: IP khong hop le ($ip), kiem tra lai wifi/cap mang!"
  $ip = "localhost"
}

if (-not $ip) { $ip = "localhost" }
# Update api_constants.dart
$file = "lib\core\constants\api_constants.dart"
$content = Get-Content $file -Raw
$updated = $content -replace "defaultValue: '[^']*'", "defaultValue: 'http://${ip}:5291'"
Set-Content $file $updated -NoNewline
Write-Host "Updated -> http://${ip}:5291"

# Start backend neu chua chay
$portCheck = netstat -ano | findstr ":5291"
if ($portCheck) {
  Write-Host "Backend already running"
} else {
  Write-Host "Starting backend..."
  Start-Process powershell -ArgumentList `
    "-NoExit", "-Command", "cd '$PSScriptRoot\backend'; npm run dev" `
  -WindowStyle Normal
  Start-Sleep -Seconds 3
  Write-Host "Backend ready!"
}

# Start ngrok neu chua chay
$ngrokCheck = Get-Process -Name "ngrok" -ErrorAction SilentlyContinue
if ($ngrokCheck) {
  Write-Host "ngrok already running"
} else {
  Write-Host "Starting ngrok..."
  Start-Process powershell -ArgumentList `
    "-NoExit", "-Command", "E:\DevEnv\ngrok\ngrok.exe http 5291" `
  -WindowStyle Normal
  Start-Sleep -Seconds 4
}

# Lay ngrok URL
Write-Host "Getting ngrok URL..."
try {
  $ngrokApi = Invoke-RestMethod -Uri "http://127.0.0.1:4040/api/tunnels" -ErrorAction Stop
  $ngrokUrl = $ngrokApi.tunnels `
    | Where-Object { $_.proto -eq "https" } `
    | Select-Object -First 1 -ExpandProperty public_url

  if ($ngrokUrl) {
    $domain = $ngrokUrl -replace "https://", ""
    Write-Host ""
    Write-Host "====================================="
    Write-Host "NGROK URL: $ngrokUrl"
    Write-Host "====================================="
    Write-Host "Mac team chay: ./run_client.sh"
    Write-Host "Nhap domain: $domain"
    Write-Host ""
    $domain | Set-Clipboard
Write-Host "Da copy domain vao clipboard!"
  }
} catch {
  Write-Host "Chua lay duoc URL, mo: http://127.0.0.1:4040"
}