# ============================================================
# Start-DRI-Autopilot-OOBE.ps1
# Draait in user context tijdens OOBE
# ============================================================
#Wrapper‑script: start Autopilot
#C:\OSDCloud\Scripts\SetupComplete\OOBE\Start-DRI-Autopilot-OOBE.ps1

$ErrorActionPreference = 'Stop'

Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\Start-DRI-Autopilot-OOBE.log" -ErrorAction Ignore | Out-Null

#Path to script
#Seek file DRIAutoPilot*.ps1 inside a folder that has DRIAutoPilot in it. 
Write-Host "[|] Seeking file DRIAutoPilot*.ps1 inside 'C:\OSDCloud' (recursive)."
$FoundScript = Get-ChildItem -Path "C:\OSDCloud" -Filter "DRIAutoPilot*.ps1" -Recurse | Where-Object { $_.DirectoryName -like "*DRIAutoPilot*" } | Select-Object -First 1

#Path script
if ($FoundScript) {
    $AutoPilotScript = $FoundScript.FullName
    Write-Host "  [+] Script found on: $AutoPilotScript" -ForegroundColor Green
} else {
    Write-Warning "  [-] AutoPilot script not found!"
}

Write-Host "[|] Start-DRI-Autopilot-OOBE.ps1 gestart..." -ForegroundColor Cyan

$titel = "Autopilot script gevonden, starten: $AutoPilotScript"
$vraag = "Autopilot script gevonden, starten: $AutoPilotScript `nWil je doorgaan met de actie?"
$keuzes = @(
    New-Object System.Management.Automation.Host.ChoiceDescription "&Ja", "Voert het script uit."
    New-Object System.Management.Automation.Host.ChoiceDescription "&Nee", "Stopt het script."
)

$beslissing = $Host.UI.PromptForChoice($titel, $vraag, $keuzes, 1) # 1 is de standaard (Nee)

if ($beslissing -eq 0) {
    Write-Host "Actie wordt uitgevoerd..." -ForegroundColor Green
#Autopilot script starten in dezelfde user context
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $AutoPilotScript

#Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$AutoPilotScript`"" -Verb RunAs

Stop-Transcript -Verbose

} else {
    Write-Host "[X] Actie geannuleerd." -ForegroundColor Red
    Stop-Transcript -Verbose
    exit
}
