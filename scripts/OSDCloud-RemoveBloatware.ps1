$ErrorActionPreference = 'Stop'
 
Write-Host "OSDCloud_RemoveBloatware script gevonden, starten." -ForegroundColor Green
Write-Host "OSDCloud-RemoveBloatware.ps1 gestart..." -ForegroundColor Cyan

$titel = "OSDCloud_RemoveBloatware script gevonden"
$vraag = "Wilt u bloatware (HP/INTEL/WinApp) verwijderen? `nWil je doorgaan met de actie?"
$keuzes = @(
    New-Object System.Management.Automation.Host.ChoiceDescription "&Ja", "Voert het script uit."
    New-Object System.Management.Automation.Host.ChoiceDescription "&Nee", "Stopt het script."
)

$beslissing = $Host.UI.PromptForChoice($titel, $vraag, $keuzes, 1) # 1 is de standaard (Nee)

if ($beslissing -eq 0) {
# ============================================================
#  OSDCloud-RemoveBloatware.ps1
#  Combined Windows + HP Debloat Script (Native Only, No WMIC)
# ============================================================

$LogFile = Join-Path -Path "env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" -ChildPath "OSDCloud-RemoveBloatware.log"

Function Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp  $Message" | Out-File -FilePath $LogFile -Append -Encoding utf8
    Write-Host $Message
}

Log "=== OSDCloud-RemoveBloatware Script Started ==="

#Voorkom automatische installatie van gesponsorde apps (Consumer Content)
Reg Add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f
Log "[REG] Add HKLM\Software\Policies\Microsoft\Windows\CloudContent"
Log "[REG] DisableWindowsConsumerFeatures - REG_DWORD - 1"

# ============================================================
# 1. REMOVE WINDOWS BLOATWARE FROM TXT LIST
# ============================================================
Log ""
Log "======================================"
Log "REMOVE WINDOWS BLOATWARE FROM TXT LIST"
Log "======================================"

$BasePath = "C:\OSDCloud\Scripts\SetupComplete\OOBE"

#Maak de map aan als deze nog niet bestaat
if (!(Test-Path $BasePath)) { New-Item -Path $BasePath -ItemType Directory }

#Download OSDCloud-RemoveBloatware-AppList.txt met de RAW URL
Write-Host -ForegroundColor Cyan "[|] Download OSDCloud-RemoveBloatware-AppList.txt van GitHub Repo..."
$rawUrl = "https://raw.githubusercontent.com/Gelders/OSDCloud/refs/heads/main/scripts/OSDCloud-RemoveBloatware-AppList.txt"

try {
    Invoke-WebRequest -Uri $rawUrl -OutFile "$BasePath\OSDCloud-RemoveBloatware-AppList.txt" -ErrorAction Stop
    Write-Host -ForegroundColor Green " [+] Download voltooid!"
    if ((Test-Path $BasePath)) {Write-Host -ForegroundColor Green "  [+] OSDCloud-RemoveBloatware-AppList.txt is in de folder C:\OSDCloud\Scripts\SetupComplete\OOBE"}

} catch {
    Write-Host -ForegroundColor Red "[-] Fout bij downloaden: $($_.Exception.Message)"
}

$TxtList = Join-Path $BasePath "OSDCloud-RemoveBloatware-AppList.txt"

if (Test-Path $TxtList) {
    $AppsToRemove = Get-Content $TxtList | Where-Object { $_.Trim() -ne "" }

    Log "TXT list gevonden: $TxtList"
    Log "$($AppsToRemove.Count) apps gevonden in TXT list"

    foreach ($app in $AppsToRemove) {
        $pkg = Get-AppxPackage -AllUsers -Name $app
        $ppkg = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq $app}


        if ($pkg -or $ppkg) {
            Log "[-] Verwijderen van Windows AppX & Provisioned: $app"
            Try {
                #Verwijder Provisioned Package (voor toekomstige gebruikers)
                if ($ppkg) {
                    Remove-AppxProvisionedPackage -Online -PackageName $ppkg.PackageName -ErrorAction SilentlyContinue
                }
                
                #Verwijder Appx Package (voor huidige/alle gebruikers)
                if ($pkg) {
                    Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
                }
                
                Log "[OK] Verwijderd: $app"
            }
            Catch {
                Log "[ERR] Verwijderen mislukt: $app - $($_.Exception.Message)"
            }
        } else {
            Log "[SKIP] $app is niet geïnstalleerd"
        }
    }
} else {
    Log "[WARN] TXT list niet gevonden — skipping Windows bloat removal"
    Log "[WARN] Txt-bestand: $TxtList"
    Log "[WARN] Script root: $ScriptRoot"
    Log "[WARN] PWD: $PWD"

}

# ============================================================
# 2. HP DEVICE DETECTION
# ============================================================
Log ""
Log "==================="
Log "HP DEVICE DETECTION"
Log "==================="
$Manufacturer = (Get-CimInstance Win32_ComputerSystem).Manufacturer

if ($Manufacturer -notmatch "HP") {
    Log "[INFO] Niet een HP device — skipping HP cleanup"
    Log "=== OSDCloud-RemoveBloatware Script End ==="
    exit
}

Log "[INFO] HP device gedetecteerd — starting HP cleanup..."

# ============================================================
# 3. HP APPX PACKAGES
# ============================================================
Log ""
Log "=================="
Log "HP APPX PACKAGES"
Log "=================="
$HP_Appx = @(
    "AD2F1837.HPJumpStarts",
    "AD2F1837.HPPCHardwareDiagnosticsWindows",
    "AD2F1837.HPPowerManager",
    "AD2F1837.HPPrivacySettings",
    "AD2F1837.HPSupportAssistant",
    "AD2F1837.HPSureShieldAI",
    "AD2F1837.HPSystemInformation",
    "AD2F1837.HPQuickDrop",
    "AD2F1837.HPWorkWell",
    "AD2F1837.myHP",
    "AD2F1837.HPDesktopSupportUtilities",
    "AD2F1837.HPQuickTouch",
    "AD2F1837.HPEasyClean",
    "AD2F1837.HPSystemInformation"
)

Log "[+] HP Client Security Manager"
Log "[+] HP Connection Optimizer"
Log "[+] HP Documentation"
Log "[+] HP MAC Address Manager"
Log "[+] HP Notifications"
Log "[+] HP Security Update Service"
Log "[+] HP System Default Settings"
Log "[+] HP Sure Click"
Log "[+] HP Sure Click Security Browser"
Log "[+] HP Sure Run"
Log "[+] HP Sure Recover"
Log "[+] HP Sure Sense"
Log "[+] HP Sure Sense Installer"
Log "[+] HP Wolf Security"
Log "[+] HP Wolf Security Application Support for Sure Sense"
Log "[+] HP Wolf Security Application Support for Windows"

$HPidentifier = "AD2F1837"

$InstalledHP = Get-AppxPackage -AllUsers |
    Where-Object { ($HP_Appx -contains $_.Name) -or ($_.Name -match "^$HPidentifier") }

$ProvisionedHP = Get-AppxProvisionedPackage -Online |
    Where-Object { ($HP_Appx -contains $_.DisplayName) -or ($_.DisplayName -match "^$HPidentifier") }

#Remove provisioned packages
foreach ($Prov in $ProvisionedHP) {
    Log "[-] Verwijderen van HP provisioned package: $($Prov.DisplayName)"
    Try {
        Remove-AppxProvisionedPackage -PackageName $Prov.PackageName -Online -ErrorAction Stop
        Log "[OK] Removed provisioned: $($Prov.DisplayName)"
    }
    Catch {
        Log "[ERR] Failed to remove provisioned: $($Prov.DisplayName)"
    }
}

#Remove installed AppX packages
foreach ($Appx in $InstalledHP) {
    Log "[-] Verwijderen HP AppX: $($Appx.Name)"
    Try {
        Remove-AppxPackage -Package $Appx.PackageFullName -AllUsers -ErrorAction Stop
        Log "[OK] Verwijderd AppX: $($Appx.Name)"
    }
    Catch {
        Log "[ERR] AppX verwijderen mislukt: $($Appx.Name)"
    }
}

# ============================================================
# 4. HP MSI PROGRAMS (Native Registry Scan + MSIEXEC)
# ============================================================
Log ""
Log "================"
Log "HP MSI PROGRAMS"
Log "================"

$HP_MSI_Names = @(
    "HP Client Security Manager",
    "HP Connection Optimizer",
    "HP Documentation",
    "HP MAC Address Manager",
    "HP Notifications",
    "HP Security Update Service",
    "HP System Default Settings",
    "HP Sure Click",
    "HP Sure Click Security Browser",
    "HP Sure Run",
    "HP Sure Recover",
    "HP Sure Sense",
    "HP Sure Sense Installer",
    "HP Wolf Security",
    "HP Wolf Security Application Support for Sure Sense",
    "HP Wolf Security Application Support for Windows"
)

#Registry paths voor MSI producten
$MSIPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

Log "Registry paths voor MSI producten"
foreach ($name in $HP_MSI_Names) {

    $Found = $false

    foreach ($path in $MSIPaths) {
        $keys = Get-ChildItem $path -ErrorAction SilentlyContinue

        foreach ($key in $keys) {
            $DisplayName = (Get-ItemProperty $key.PSPath -ErrorAction SilentlyContinue).DisplayName
            $GUID = $key.PSChildName

            if ($DisplayName -and $DisplayName -eq $name -and $GUID -match "^\{.*\}$") {
                $Found = $true
                Log "[-] Uninstalling MSI: $name ($GUID)"
                Try {
                    Start-Process "msiexec.exe" -ArgumentList "/x $GUID /qn /norestart" -Wait
                    Log "[OK] Uninstalled MSI: $name"
                }
                Catch {
                    Log "[ERR] MSI uninstall mislukt: $name"
                }
            }
        }
    }

    if (-not $Found) {
        Log "[SKIP] MSI niet geïnstalleerd: $name"
    }
}

# ============================================================
# 5. HP WOLF SECURITY FALLBACK MSI
# ============================================================
Log ""
Log "============================="
Log "HP WOLF SECURITY FALLBACK MSI"
Log "============================="

$WolfMSIs = @(
    "{0E2E04B0-9EDD-11EB-B38C-10604B96B11E}",
    "{4DA839F0-72CF-11EC-B247-3863BB3CB5A8}"
)

foreach ($msi in $WolfMSIs) {
    Log "[-] Fallback uninstall proberen: $msi"
    Try {
        Start-Process "msiexec.exe" -ArgumentList "/x $msi /qn /norestart" -Wait
        Log "[OK] Fallback uninstall uitgevoerd"
    }
    Catch {
        Log "[ERR] Fallback uninstall mislukt"
    }
}

Log "=== OSDCloud-RemoveBloatware Script End ==="

#EINDE BESLISSING
} else {
    Write-Host "Actie geannuleerd." -ForegroundColor Red
    exit
}
