$scriptFolderPath = "C:\OSDCloud\Scripts\SetupComplete\"
$ScriptPathOOBE = Join-Path $scriptFolderPath "OOBE.ps1"
$ScriptPathSendKeys = Join-Path $scriptFolderPath "SendKeys.ps1"

$OSDCloudMainFolderPath = "C:\OSDCloud\Scripts\SetupComplete\OSDCloud-main\scripts"

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
Start-Process PowerShell -ArgumentList "-NoL -ExecutionPolicy Bypass -File $OSDCloudMainFolderPath\Set-KeyboardLanguage.ps1" -Wait

Write-Host " [+] Installing embedded product key - Github" -ForegroundColor Cyan
Start-Process PowerShell -ArgumentList "-NoL -ExecutionPolicy Bypass -File $OSDCloudMainFolderPath\Install-EmbeddedProductKey.ps1" -Wait

Write-Host " [+] Checking Autopilot prerequisites - Github" -ForegroundColor Cyan
Start-Process PowerShell -ArgumentList "-NoL -ExecutionPolicy Bypass -File $OSDCloudMainFolderPath\AP-Prereq.ps1" -Wait

Write-Host " [+] Adding OfficeOne apps - Github" -ForegroundColor Cyan
Start-Process PowerShell -ArgumentList "-NoL -ExecutionPolicy Bypass -File $OSDCloudMainFolderPath\OSDCloud-AddSoftware.ps1" -Wait

Write-Host " [+] Removing Bloatware - Github" -ForegroundColor Cyan
Start-Process PowerShell -ArgumentList "-NoL -ExecutionPolicy Bypass -File $OSDCloudMainFolderPath\OSDCloud-RemoveBloatware.ps1" -Wait

Write-Host " [+] Starting AutopilotOOBE - Github" -ForegroundColor Cyan
Start-Process PowerShell -ArgumentList "-NoL -ExecutionPolicy Bypass -File $OSDCloudMainFolderPath\Start-DRI-Autopilot-OOBE.ps1" -Wait

Write-Host " [+] Executing Cleanup Script - Github" -ForegroundColor Cyan
Start-Process PowerShell -ArgumentList "-NoL -ExecutionPolicy Bypass -File $OSDCloudMainFolderPath\CleanUp.ps1" -Wait

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

# -------------------
# ServiceUI.exe
# -------------------
#ServiceUI.exe
#Maak de map aan als deze nog niet bestaat
$destPath = "C:\OSDCloud\Scripts\SetupComplete\OSDCloud-main\tools\"
if (!(Test-Path $destPath)) { New-Item -Path $destPath -ItemType Directory }

Write-Host -ForegroundColor Gray "[?] ServiceUI.exe zoeken..."

if(Test-Path "C:\OSDCloud\Scripts\SetupComplete\OSDCloud-main\tools\ServiceUI.exe"){
    Write-Host -ForegroundColor Green " [+] ServiceUI.exe is in de folder C:\OSDCloud\Scripts\SetupComplete\OSDCloud-main\tools\ServiceUI.exe"
}
else{
    Write-Host -ForegroundColor Red " [-] ServiceUI.exe niet gevonden."
    Write-Host -ForegroundColor Red "  [|] Er is iets misgelopen bij het kopieren van de GitHub Repo."

    #Download ServiceUI.exe met de RAW URL
    Write-Host -ForegroundColor Cyan "[|] Download ServiceUI.exe van GitHub Repo..."
    $rawUrl = "https://github.com/Gelders/OSDCloud/raw/refs/heads/main/tools/ServiceUI.exe"

    try {
        Invoke-WebRequest -Uri $rawUrl -OutFile "$destPath\ServiceUI.exe" -ErrorAction Stop
        Write-Host -ForegroundColor Green " [+] Download voltooid!"
        if ((Test-Path $destPath)) {Write-Host -ForegroundColor Green "  [+] ServiceUI.exe is in de folder C:\OSDCloud\Scripts\SetupComplete\OSDCloud-main\tools\"}

    } catch {
        Write-Host -ForegroundColor Red "[-] Fout bij downloaden: $($_.Exception.Message)"
    }
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
$action.Path = 'C:\OSDCloud\Scripts\SetupComplete\OSDCloud-main\tools\ServiceUI.exe'
$action.Arguments = '-process:RuntimeBroker.exe C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe ' + $ScriptPathSendKeys + ' -NoExit'

$taskFolder = $ShedService.GetFolder("\")
#https://msdn.microsoft.com/en-us/library/windows/desktop/aa382577(v=vs.85).aspx
$taskFolder.RegisterTaskDefinition($TaskName, $Task , 6, "SYSTEM", $NULL, 5)





#==================================================================================
#   Create Scheduled Task for OSDCloud post installation with 20 seconds delay
#==================================================================================
<#$TaskName = "Scheduled Task for OSDCloud post installation"

$ShedService = New-Object -comobject 'Schedule.Service'
$ShedService.Connect()

$Task = $ShedService.NewTask(0)
$Task.RegistrationInfo.Description = $taskName
$Task.Settings.Enabled = $true
$Task.Settings.AllowDemandStart = $true
$Task.Principal.RunLevel = 1 # 0 is 'Limited', 1 is 'Highest'

#https://msdn.microsoft.com/en-us/library/windows/desktop/aa383987(v=vs.85).aspx
$trigger = $task.triggers.Create(9) # 0 EventTrigger, 1 TimeTrigger, 2 DailyTrigger, 3 WeeklyTrigger, 4 MonthlyTrigger, 5 MonthlyDOWTrigger, 6 IdleTrigger, 7 RegistrationTrigger, 8 BootTrigger, 9 LogonTrigger
$trigger.Delay = 'PT20S'
$trigger.Enabled = $true

$action = $Task.Actions.Create(0)
$action.Path = 'C:\OSDCloud\Scripts\SetupComplete\OSDCloud-main\tools\ServiceUI.exe'
#$action.Arguments = '-process:RuntimeBroker.exe C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe ' + $ScriptPathOOBE + ' -NoExit'
#$action.Arguments = '-process:explorer.exe C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File ' + $ScriptPathOOBE + ' -NoExit'
$action.Arguments = '-process:CloudExperienceHost.exe C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File ' + $ScriptPathOOBE + ' -NoExit'

$taskFolder = $ShedService.GetFolder("\")
#https://msdn.microsoft.com/en-us/library/windows/desktop/aa382577(v=vs.85).aspx
$taskFolder.RegisterTaskDefinition($TaskName, $Task , 6, "SYSTEM", $NULL, 5) 
#>

#==================================================================================
#   Create Scheduled Task for OSDCloud post installation with 20 seconds delay
#==================================================================================
$TaskName = "Scheduled Task for OSDCloud post installation"

$Service = New-Object -ComObject "Schedule.Service"
$Service.Connect()

$Task = $Service.NewTask(0)

#-------------------------
# Registration Info
#-------------------------
$Task.RegistrationInfo.Description = $taskName
$Task.RegistrationInfo.Author      = "$env:COMPUTERNAME\defaultuser0"
$Task.RegistrationInfo.URI         = "\Scheduled Task for OSDCloud post installation"

#-------------------------
$Task.Settings.MultipleInstances          = 0   # IgnoreNew
$Task.Settings.DisallowStartIfOnBatteries = $true
$Task.Settings.StopIfGoingOnBatteries     = $true
$Task.Settings.AllowHardTerminate         = $true
$Task.Settings.AllowDemandStart           = $true
$Task.Settings.StartWhenAvailable         = $false
$Task.Settings.RunOnlyIfNetworkAvailable  = $false
$Task.Settings.Enabled                    = $true
$Task.Settings.Hidden                     = $false
$Task.Settings.RunOnlyIfIdle              = $false
$Task.Settings.WakeToRun                  = $false
$Task.Settings.ExecutionTimeLimit         = "PT72H"
$Task.Settings.Priority                   = 7

$Task.Settings.IdleSettings.StopOnIdleEnd = $true
$Task.Settings.IdleSettings.RestartOnIdle = $false

$Principal = $Task.Principal
$Principal.Id = "Author"
$Principal.GroupId = "S-1-5-32-544"   # Administrators group
$Principal.RunLevel = 1               # HighestAvailable

$Trigger = $Task.Triggers.Create(9)   # LogonTrigger
$Trigger.Enabled = $true
$Trigger.Delay   = "PT20S"

$Action = $Task.Actions.Create(0)
$Action.Path = "C:\OSDCloud\Scripts\SetupComplete\OSDCloud-main\tools\ServiceUI.exe"
$Action.Arguments = "C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File C:\OSDCloud\Scripts\SetupComplete\OOBE.ps1 -NoExit"

$root = $service.GetFolder("\")
$root.RegisterTaskDefinition($TaskName, $task, 6, $null, $null, 5)
