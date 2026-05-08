Write-Host "[|] Start-DRI-Autopilot-OOBE.ps1 gestart..." -ForegroundColor Cyan

$titel = "Autopilot script gevonden, starten: $AutoPilotScript"
$vraag = "Autopilot script gevonden, starten: $AutoPilotScript `nWil je doorgaan met de actie?"
$keuzes = @(
    New-Object System.Management.Automation.Host.ChoiceDescription "&Ja", "Voert het script uit."
    New-Object System.Management.Automation.Host.ChoiceDescription "&Nee", "Stopt het script."
)

$beslissing = $Host.UI.PromptForChoice($titel, $vraag, $keuzes, 1)

if ($beslissing -eq 0) {
    $TaskName = "Scheduled Task for OSDCloud AutoPilot"
    $XmlContent = @'
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Author>Peter Gelders</Author>
    <Description>Launch DRI-AutoPilot</Description>
    <URI>\Scheduled Task for OSDCloud AutoPilot</URI>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
      <Delay>PT1M</Delay>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <GroupId>S-1-5-32-544</GroupId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe</Command>
      <Arguments>-ExecutionPolicy Bypass -File "C:\OSDCloud\Scripts\SetupComplete\DRIAutoPilotV5\Resources\DRIAutoPilotV5.10.ps1"</Arguments>
    </Exec>
  </Actions>
</Task>
'@

    # Registreer de taak direct vanuit de XML-string
    Register-ScheduledTask -Xml $XmlContent -TaskName $TaskName -Force
    Write-Host "[+] Scheduled Task succesvol aangemaakt." -ForegroundColor Green
}
