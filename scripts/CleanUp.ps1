#CleanUp.ps1
#https://gist.githubusercontent.com/AkosBakos/0b81812f5c6c6bc5b69495469c96be1b/raw/CleanUp.ps1
$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Cleanup-Script.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore

Write-Host "== Execute OSD Cloud Cleanup Script ==" -ForegroundColor Green

#Copying the OOBEDeploy and AutopilotOOBE Logs
Get-ChildItem 'C:\Windows\Temp' -Filter *OOBE* | Copy-Item -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force

#Copying OSDCloud Logs
If (Test-Path -Path 'C:\OSDCloud\Logs') {
    Move-Item 'C:\OSDCloud\Logs\*.*' -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force
    Write-Host "[+] Logfiles | 'C:\OSDCloud\Logs' naar 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD'" -ForegroundColor Green
}

If (Test-Path -Path 'C:\Temp') {
    Get-ChildItem 'C:\Temp' -Filter *OOBE* | Copy-Item -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force
    Get-ChildItem 'C:\Windows\Temp' -Filter *Events* | Copy-Item -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force
    Write-Host "[+] Logfiles | 'C:\Temp' & 'C:\Windows\Temp' naar 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD'" -ForegroundColor Green

}

#Cleanup dirs
If (Test-Path -Path 'C:\OSDCloud') { Get-ChildItem -Path "C:\OSDCloud" -Exclude "ServiceUI.exe" -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    
    Write-Host "[-] DIR | 'C:\OSDCloud' verwijderd." -ForegroundColor Cyan

    #Plan de rest van de map (inclusief ServiceUI.exe) voor verwijdering na herstart
    $targetPath = "C:\OSDCloud"
    if (Test-Path $targetPath) {
        #RunOnce register sleutel
        $cleanupCmd = "cmd.exe /c timeout /t 10 && rd /s /q `"$targetPath`""
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name "OSDCloudCleanup" -Value $cleanupCmd
    }
 }
If (Test-Path -Path 'C:\Drivers') { Remove-Item 'C:\Drivers' -Recurse -Force 
  Write-Host "[-] DIR | 'C:\Drivers' verwijderd." -ForegroundColor Cyan

}
If (Test-Path -Path 'C:\Intel') { Remove-Item 'C:\Intel' -Recurse -Force 
  Write-Host "[-] DIR | 'C:\Intel' verwijderd." -ForegroundColor Cyan
}
If (Test-Path -Path 'C:\ProgramData\OSDeploy') { Remove-Item 'C:\ProgramData\OSDeploy' -Recurse -Force 
  Write-Host "[-] DIR | 'C:\ProgramData\OSDeploy' verwijderd." -ForegroundColor Cyan
}

#Cleanup Scripts
Remove-Item C:\Windows\Setup\Scripts\*.* -Exclude *.TAG -Force | Out-Null

#remove Rudy's gif
If (Test-Path -Path 'C:\Windows\Temp\membeer.gif') {
    Remove-Item 'C:\Windows\Temp\membeer.gif' -Force
}

Stop-Transcript