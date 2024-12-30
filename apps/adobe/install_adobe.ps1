$adobeInstaller = "https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/2400520320/AcroRdrDC2400520320_en_US.exe"
$installerPath = "$env:TEMP\adobe_reader_installer.exe"

try {
    # Download the installer with error handling
    Invoke-WebRequest -Uri $adobeInstaller -OutFile $installerPath -ErrorAction Stop

    # Start installation with progress reporting and error capturing
    Start-Process -FilePath $installerPath -ArgumentList "/sAll /rs /msi EULA_ACCEPT=YES" -Wait -ErrorAction Stop | 
        Write-Progress -Activity "Installing Adobe Reader" -Status "Downloading and installing..."

    Write-Host "Adobe Reader installation completed successfully." -ForegroundColor Green
}
catch {
    Write-Host "Failed to install Adobe Reader: $($_.Exception.Message)" -ForegroundColor Red
}
