@echo off
:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ========================================================
    echo [ERROR] Administrative privileges required.
    echo Please right-click fix_dns.bat and select:
    echo        "Run as administrator"
    echo ========================================================
    echo.
    pause
    exit /b 1
)

echo ========================================================
echo Updating active network adapters to Google DNS...
echo ========================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { Write-Host 'Setting DNS for:' $_.Name; Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses ('8.8.8.8','8.8.4.4') }"

echo.
echo Flushing local DNS cache...
ipconfig /flushdns

echo.
echo ========================================================
echo Testing Supabase domain resolution...
echo ========================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command "Resolve-DnsName -Name igwfwnclpairglgojeoo.supabase.co -Type A | Format-Table -Property Name, IPAddress"

echo ========================================================
echo All done! You can now reload your app in the browser.
echo ========================================================
pause
