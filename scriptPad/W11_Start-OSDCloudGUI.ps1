#================================================
#   [PreOS] Update Module
#================================================
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host  -ForegroundColor Green "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module OSD -Force

Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force   

#=======================================================================
#   [OS] Params and Start-OSDCloudGUI
#=======================================================================
Start-OSDCloudGUI -BrandName "" -BrandColor "#17458a" -OSLanguage "nl-nl" -OSVersion "Windows 11" -OSEdition "Pro" -OSActivation "Retail" -RestartComputer -UpdateDiskDrivers -UpdateNetworkDrivers -UpdateSCSIDrivers -SyncMSUpCatDriverUSB -OEMActivation -WindowsUpdate -WindowsUpdateDrivers -WindowsDefenderUpdate
