# 7-Zip Installer URL
$zipInstaller = "https://github.com/ip7z/7zip/releases/download/24.09/7z2409.msi"
$installerPath = "$env:TEMP\7-zip_installer.msi"

# Download Installer
Write-Host "Downloading 7-Zip installer..."
Invoke-WebRequest -Uri $zipInstaller -OutFile $installerPath

# Install 7-Zip (Silent Mode)
Write-Host "Installing 7-Zip..."
Start-Process msiexec.exe -ArgumentList "/i $installerPath /qn /norestart" -Wait

# Verify Installation
if (Test-Path "C:\Program Files\7-Zip\7z.exe") {
    Write-Host "7-Zip installed successfully!"
} else {
    Write-Host "7-Zip installation failed!"
}

# Clean Up Installer
Remove-Item -Path $installerPath -Force
