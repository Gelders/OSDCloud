$scriptFolderPath = "C:\OSDCloud\Scripts\SetupComplete\oobe"
$ScriptPathOOBE = Join-Path $scriptFolderPath "OOBE.ps1"
$ScriptPathSendKeys = Join-Path $scriptFolderPath "SendKeys.ps1"

If (!(Test-Path $scriptFolderPath)) {
    New-Item -Path $scriptFolderPath -ItemType Directory -Force | Out-Null
}

#===========================
# OOBE SCRIPT (LOKAAL)
#===========================
$OOBEScript = @"
`$Global:Transcript = "`$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OOBEScripts.log"
Start-Transcript -Path (Join-Path "`$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" `$Global:Transcript) -ErrorAction Ignore | Out-Null

Write-Host -ForegroundColor DarkGray "[+] Installing AutopilotOOBE PS Module"
Start-Process PowerShell -ArgumentList "-NoL -C Install-Module AutopilotOOBE -Force -Verbose" -Wait

Write-Host -ForegroundColor DarkGray "[+] Installing OSD PS Module"
Start-Process PowerShell -ArgumentList "-NoL -C Install-Module OSD -Force -Verbose" -Wait

Write-Host " [+] Setting language to nl-BE - Github" -ForegroundColor Cyan
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/Gelders/OSDCloud/refs/heads/main/scripts/Set-KeyboardLanguage.ps1" -Wait

Write-Host " [+] Installing embedded product key - Github" -ForegroundColor Cyan
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/Gelders/OSDCloud/refs/heads/main/scripts/Install-EmbeddedProductKey.ps1" -Wait

Write-Host " [+] Checking Autopilot prerequisites - Github" -ForegroundColor Cyan
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/Gelders/OSDCloud/refs/heads/main/scripts/AP-Prereq.ps1" -Wait

### TOEVOEGING VAN ADD OSDCloud-AddSoftware en OSDCloud-RemoveBloatware
Write-Host " [+] Adding OfficeOne apps - Github" -ForegroundColor Cyan
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/Gelders/OSDCloud/refs/heads/main/scripts/OSDCloud-AddSoftware.ps1" -Wait

Write-Host " [+] Removing Bloatware - Github" -ForegroundColor Cyan
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/Gelders/OSDCloud/refs/heads/main/scripts/OSDCloud-RemoveBloatware.ps1" -Wait
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

Write-Host " [+] Starting AutopilotOOBE - Github" -ForegroundColor Cyan
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/Gelders/OSDCloud/refs/heads/main/scripts/Start-DRI-Autopilot-OOBE.ps1" -Wait

Write-Host " [+] Executing Cleanup Script - Github" -ForegroundColor Cyan
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/Gelders/OSDCloud/refs/heads/main/scripts/CleanUp.ps1" -Wait

#Cleanup scheduled Tasks
Write-Host " [+] Cleanup ScheduledTask" -ForegroundColor Cyan
Unregister-ScheduledTask -TaskName "Scheduled Task for SendKeys" -Confirm:`$false
Unregister-ScheduledTask -TaskName "Scheduled Task for OSDCloud post installation" -Confirm:`$false

Write-Host -ForegroundColor Green "[|] Restarting Computer"

Stop-Transcript -Verbose
Start-Process PowerShell -ArgumentList "-NoL -C Restart-Computer -Force" -Wait
"@

Out-File -FilePath $ScriptPathOOBE -InputObject $OOBEScript -Encoding ascii

# ------------------------------
# SENDKEYS SCRIPT (LOKAAL)
# ------------------------------
$SendKeysScript = @"
`$Global:Transcript = "`$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-SendKeys.log"
Start-Transcript -Path (Join-Path "`$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" `$Global:Transcript) -ErrorAction Ignore | Out-Null

Write-Host -ForegroundColor DarkGray "Stop Debug-Mode (SHIFT + F10) with WscriptShell.SendKeys"
`$WscriptShell = New-Object -com Wscript.Shell

# ALT + TAB
Write-Host -ForegroundColor DarkGray "SendKeys: ALT + TAB"
`$WscriptShell.SendKeys("%({TAB})")

Start-Sleep -Seconds 1

# Shift + F10
Write-Host -ForegroundColor DarkGray "SendKeys: SHIFT + F10"
`$WscriptShell.SendKeys("+({F10})")

Stop-Transcript -Verbose
"@

Out-File -FilePath $ScriptPathSendKeys -InputObject $SendKeysScript -Encoding ascii

#Download ServiceUI.exe
#Write-Host -ForegroundColor Gray "ServiceUI.exe is in de folder C:\OSDCloud\Scripts\SetupComplete\ServiceUI.exe"
#Test-Path "C:\OSDCloud\Scripts\SetupComplete\ServiceUI.exe"
#Invoke-WebRequest https://github.com/AkosBakos/Tools/raw/main/ServiceUI64.exe -OutFile "C:\OSDCloud\ServiceUI.exe"

#Maak de map aan als deze nog niet bestaat
$destPath = "C:\OSDCloud\Scripts\SetupComplete\"
if (!(Test-Path $destPath)) { New-Item -Path $destPath -ItemType Directory }

#Download ServiceUI.exe met de RAW URL
Write-Host -ForegroundColor Cyan "[|] Download ServiceUI.exe van GitHub Repo..."
$rawUrl = "https://github.com/Gelders/OSDCloud/raw/refs/heads/main/tools/ServiceUI.exe"

try {
    Invoke-WebRequest -Uri $rawUrl -OutFile "$destPath\ServiceUI.exe" -ErrorAction Stop
    Write-Host -ForegroundColor Green " [+] Download voltooid!"
    if ((Test-Path $destPath)) {Write-Host -ForegroundColor Green "  [+] ServiceUI.exe is in de folder C:\OSDCloud\Scripts\SetupComplete\"}

} catch {
    Write-Host -ForegroundColor Red "[-] Fout bij downloaden: $($_.Exception.Message)"
}

#============================================================================
#   Create Scheduled Task for SendKeys with 15 seconds delay
#============================================================================
$TaskName = "Scheduled Task for SendKeys"

$ShedService = New-Object -comobject 'Schedule.Service'
$ShedService.Connect()

$Task = $ShedService.NewTask(0)
$Task.RegistrationInfo.Description = $taskName
$Task.Settings.Enabled = $true
$Task.Settings.AllowDemandStart = $true

#https://msdn.microsoft.com/en-us/library/windows/desktop/aa383987(v=vs.85).aspx
$trigger = $task.triggers.Create(9) # 0 EventTrigger, 1 TimeTrigger, 2 DailyTrigger, 3 WeeklyTrigger, 4 MonthlyTrigger, 5 MonthlyDOWTrigger, 6 IdleTrigger, 7 RegistrationTrigger, 8 BootTrigger, 9 LogonTrigger
$trigger.Delay = 'PT15S'
$trigger.Enabled = $true

$action = $Task.Actions.Create(0)
$action.Path = 'C:\OSDCloud\Scripts\SetupComplete\ServiceUI.exe'
$action.Arguments = '-process:RuntimeBroker.exe C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe ' + $ScriptPathSendKeys + ' -NoExit'

$taskFolder = $ShedService.GetFolder("\")
#https://msdn.microsoft.com/en-us/library/windows/desktop/aa382577(v=vs.85).aspx
$taskFolder.RegisterTaskDefinition($TaskName, $Task , 6, "SYSTEM", $NULL, 5)





#==================================================================================
#   Create Scheduled Task for OSDCloud post installation with 20 seconds delay
#==================================================================================
$TaskName = "Scheduled Task for OSDCloud post installation"

$ShedService = New-Object -comobject 'Schedule.Service'
$ShedService.Connect()

$Task = $ShedService.NewTask(0)
$Task.RegistrationInfo.Description = $taskName
$Task.Settings.Enabled = $true
$Task.Settings.AllowDemandStart = $true

#https://msdn.microsoft.com/en-us/library/windows/desktop/aa383987(v=vs.85).aspx
$trigger = $task.triggers.Create(9) # 0 EventTrigger, 1 TimeTrigger, 2 DailyTrigger, 3 WeeklyTrigger, 4 MonthlyTrigger, 5 MonthlyDOWTrigger, 6 IdleTrigger, 7 RegistrationTrigger, 8 BootTrigger, 9 LogonTrigger
$trigger.Delay = 'PT20S'
$trigger.Enabled = $true

$action = $Task.Actions.Create(0)
$action.Path = 'C:\OSDCloud\Scripts\SetupComplete\ServiceUI.exe'
$action.Arguments = '-process:RuntimeBroker.exe C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe ' + $ScriptPathOOBE + ' -NoExit'

$taskFolder = $ShedService.GetFolder("\")
#https://msdn.microsoft.com/en-us/library/windows/desktop/aa382577(v=vs.85).aspx
$taskFolder.RegisterTaskDefinition($TaskName, $Task , 6, "SYSTEM", $NULL, 5) 
