# Thử lấy IP WiFi trước
$ip = (Get-NetIPAddress -AddressFamily IPv4 `
  | Where-Object { $_.InterfaceAlias -like "*Wi-Fi*" } `
  | Select-Object -First 1).IPAddress

# Fallback: lấy IP DHCP bất kỳ nếu không có WiFi
if (-not $ip) {
  $ip = (Get-NetIPAddress -AddressFamily IPv4 `
    | Where-Object { $_.PrefixOrigin -eq "Dhcp" } `
    | Select-Object -First 1).IPAddress
}

# Fallback cuối: localhost
if (-not $ip) {
  $ip = "localhost"
}

Write-Host "✅ IP phát hiện: $ip"

# Cập nhật defaultValue trong api_constants.dart
$file = "lib\core\constants\api_constants.dart"
$content = Get-Content $file -Raw
$updated = $content -replace "defaultValue: 'http://[^']*'", "defaultValue: 'http://${ip}:5291'"
Set-Content $file $updated -NoNewline

Write-Host "✅ Đã cập nhật api_constants.dart → http://${ip}:5291"
