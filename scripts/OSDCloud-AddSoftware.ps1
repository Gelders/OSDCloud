$ErrorActionPreference = 'Stop'

$LogFile = Join-Path -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" -ChildPath "OSDCloud-AddSoftware.log"
Start-Transcript -Path $LogFile -Verbose

Write-Host "OSDCloud-AddSoftware.ps1 gevonden..." -ForegroundColor Cyan
Write-Host "OSDCloud-AddSoftware script starten." -ForegroundColor Green

$titel = "OSDCloud-AddSoftware script gevonden"
$vraag = "Wilt u de OfficeOne applicaties installeren of niet? `nWil je doorgaan met de actie?"
$keuzes = @(
    New-Object System.Management.Automation.Host.ChoiceDescription "&Ja", "Voert het script uit."
    New-Object System.Management.Automation.Host.ChoiceDescription "&Nee", "Stopt het script."
)

$beslissing = $Host.UI.PromptForChoice($titel, $vraag, $keuzes, 1) # 1 is de standaard (Nee)

if ($beslissing -eq 0) {
#OSDCloud-AddSoftware script starten in dezelfde user context

# ============================================
#  SoftwareDistribution Installer (OSDCloud)
#  PS1 > BAT > MSI > EXE (met speciale switches)
# ============================================

$BasePath = "C:\OSDCloud\Scripts\SetupComplete\SoftwareDistribution"
$rootPath = Join-Path $BasePath ""

Write-Host "`n=== OSDCloud Software Installer ===" -ForegroundColor Cyan

# -------------------------------
# Functie: Silent switches per EXE
# -------------------------------
#folder h (vcredist20XX_xXX remove de install.bat)
function Get-SilentArgs {
    param([string]$FileName)

    switch -Wildcard ($FileName.ToLower()) {

        #VC++ 2005
        "vcredist2005_x86.exe" { "/q" }
        "vcredist2005_x64.exe" { "/q" }

        #VC++ 2008
        "vcredist2008_x86.exe" { "/qb" }
        "vcredist2008_x64.exe" { "/qb" }

        #VC++ 2010
        "vcredist2010_x86.exe" { "/passive /norestart" }
        "vcredist2010_x64.exe" { "/passive /norestart" }

        #VC++ 2012
        "vcredist2012_x86.exe" { "/passive /norestart" }
        "vcredist2012_x64.exe" { "/passive /norestart" }

        #VC++ 2013
        "vcredist2013_x86.exe" { "/passive /norestart" }
        "vcredist2013_x64.exe" { "/passive /norestart" }

        #VC++ 2015–2022
        "vcredist2015*" { "/passive /norestart" }
        "vcredist2017*" { "/passive /norestart" }
        "vcredist2019*" { "/passive /norestart" }
        "vcredist2022*" { "/passive /norestart" }

        #Java Runtime
        "jre-*.exe" { "/s" }

        #FireFox
        "Firefox*"{ "/s" }

        #Andere software
        "OnePC-Word6ISLPsettings*" { "/qb" }
        "dri-commongraphics-*" { "/qb" }

        #Portal
        "dri-portal-30.2-prod-pcv54" { "/passive /norestart" }

        # Default: geen specifieke switch
        default { $null }
    }
}

# -------------------------------
# Functie: EXE installeren
# -------------------------------
function Install-EXE {
    param([string]$Path)

    $file = Split-Path $Path -Leaf
    $args = Get-SilentArgs -FileName $file

    if ($args) {
        Write-Host "     [EXE] Specifieke silent parameters: $args" -ForegroundColor Green
        Start-Process -FilePath $Path -ArgumentList $args -Wait
        return
    }

    #fallback voor onbekende installers
    $fallback = @(
        "/quiet /norestart",
        "/S",
        "/s",
        "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART",
        "/qn",
        "/passive /norestart"
    )

    foreach ($arg in $fallback) {
        try {
            $p = Start-Process -FilePath $Path -ArgumentList $arg -PassThru -WindowStyle Hidden -ErrorAction Stop
            $p.WaitForExit()

            if ($p.ExitCode -eq 0) {
                Write-Host "     [OK] Silent install gelukt met: $arg" -ForegroundColor Green
                return
            }
        } catch {}
    }

    Write-Host "     [ERR] Geen silent mode gevonden voor: $file" -ForegroundColor Red
}

# -------------------------------
# Start hoofdscript
# -------------------------------
if (Test-Path $rootPath) {
    Write-Host "SoftwareDistribution gevonden op: $rootPath" -ForegroundColor Magenta

    #Sorteer submappen numeriek
    $subFolders = Get-ChildItem -Path $rootPath -Directory |
        Sort-Object { [regex]::Replace($_.Name, '\d+', { $args.Value.PadLeft(10, '0') }) }

    foreach ($folder in $subFolders) {
        Write-Host "`n[MAP] Verwerken: $($folder.Name)" -ForegroundColor Yellow

        #1. PS1 install script
        $ps1 = Get-ChildItem -Path $folder.FullName -Filter "*.ps1" |
               Where-Object { $_.Name -notlike "*uninstall*" } |
               Select-Object -First 1

        if ($ps1) {
            Write-Host "  -> [PS1] Uitvoeren: $($ps1.Name)" -ForegroundColor Cyan
            Push-Location $folder.FullName
            try {
                powershell.exe -ExecutionPolicy Bypass -File $ps1.FullName
            }
            finally {
                Pop-Location
            }
            continue
        }

        #2. BAT script
        $bat = Get-ChildItem -Path $folder.FullName -Filter "*.bat" |
               Where-Object { $_.Name -notlike "*uninstall*" } |
               Select-Object -First 1

        if ($bat) {
            Write-Host "  -> [BAT] Uitvoeren: $($bat.Name)" -ForegroundColor Cyan
            Start-Process "cmd.exe" -ArgumentList "/c `"$($bat.FullName)`"" -WindowStyle Hidden -Wait
            continue
        }

        #3. MSI/EXE fallback
        $installers = Get-ChildItem -Path $folder.FullName -Include *.msi, *.exe -Recurse |
                      Where-Object { $_.Name -notlike "*uninstall*" }

        foreach ($file in $installers) {

            if ($file.Extension -eq ".msi") {
                Write-Host "  -> [MSI] Installeren: $($file.Name)" -ForegroundColor Cyan
                Start-Process msiexec.exe -ArgumentList "/i `"$($file.FullName)`" /quiet /norestart" -Wait
            }

            elseif ($file.Extension -eq ".exe") {
                Write-Host "  -> [EXE] Installeren: $($file.Name)" -ForegroundColor Cyan
                Install-EXE -Path $file.FullName
            }
        }
    }
    Stop-Transcript -Verbose
}
else {
    Write-Error "FOUT: De map 'SoftwareDistribution' is niet gevonden op $BasePath"
    Stop-Transcript -Verbose
}

#EINDE BESLISSING
} else {
    Write-Host "OSDCloud-AddSoftware geannuleerd." -ForegroundColor Red
    Stop-Transcript -Verbose
    exit
}
