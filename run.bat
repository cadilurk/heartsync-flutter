@echo off
chcp 65001 >nul
echo.
echo Dang lay IP tu dong...
powershell -ExecutionPolicy Bypass -File "%~dp0update_ip.ps1"
echo.
echo Dang chay Flutter...
flutter run
