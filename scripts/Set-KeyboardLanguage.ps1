# ============================================================
# Set-Language-nlBE.ps1
# Zet taal, regio en toetsenbord naar nl-BE + Belgisch (punt)
# ============================================================
#Taal/keyboard script: zet nl‑BE + Belgisch (punt)
#C:\OSDCloud\Scripts\SetupComplete\OSDCloud-main\scripts\Set-Language-nlBE.ps1

#######
$Title = "Set-KeyboardLanguage"
$host.UI.RawUI.WindowTitle = $Title
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials

$env:APPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Roaming"
$env:LOCALAPPDATA = "C:\Windows\System32\Config\SystemProfile\AppData\Local"
$Env:PSModulePath = $env:PSModulePath + ";C:\Program Files\WindowsPowerShell\Scripts"
$env:Path = $env:Path + ";C:\Program Files\WindowsPowerShell\Scripts"

$Global:Transcript = "$((Get-Date).ToString('dd-MM-yyyy-HHmmss'))-Set-KeyboardLanguage.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore

Write-Host "Taal en toetsenbord instellen op nl-BE / Belgisch (punt)..." -ForegroundColor Green
Start-Sleep -Seconds 5

$ErrorActionPreference = 'Stop'

#User language list
$languageTag = 'nl-BE'

$userLangList = New-WinUserLanguageList -Language $languageTag

#Keyboard layout: Belgisch (punt)
#Layout ID voor Belgisch (punt) is meestal gekoppeld aan nl-BE,
#maar we forceren het via InputMethodTips indien nodig.
#Voorbeeld TIP: 0413:00000813 (NL) vs 0813:00000813 (BE) – dit kan per build verschillen.
#We houden het hier bij de standaard voor nl-BE.

Set-WinUserLanguageList -LanguageList $userLangList -Force

#System locale
Set-WinSystemLocale -SystemLocale $languageTag

#Culture (region)
Set-Culture -CultureInfo $languageTag

#UI language override
Set-WinUILanguageOverride -Language $languageTag

#Input method (extra zekerheid)
try {
    $regPath = 'HKCU:\Keyboard Layout\Preload'
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }

    #00000813 = Belgian (Period) layout
    Set-ItemProperty -Path $regPath -Name '1' -Value '00000813'
}
catch {
    Write-Host "Kon keyboard layout in registry niet instellen, ga verder..." -ForegroundColor Yellow
}

Write-Host "Taal en toetsenbord zijn ingesteld (mogelijk is een herstart nodig voor volledige toepassing)." -ForegroundColor Green

Start-Sleep -Seconds 5

$LanguageList = Get-WinUserLanguageList
$LanguageList.Remove(($LanguageList | Where-Object LanguageTag -like 'de-DE'))
Set-WinUserLanguageList $LanguageList -Force

$LanguageList = Get-WinUserLanguageList
$LanguageList.Remove(($LanguageList | Where-Object LanguageTag -like 'en-US'))
Set-WinUserLanguageList $LanguageList -Force

Stop-Transcript
