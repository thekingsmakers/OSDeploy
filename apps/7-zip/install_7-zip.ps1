$zipInstaller = "https://github.com/ip7z/7zip/releases/download/24.09/7z2409.msi"
$installerPath = "$env:TEMP\7-zip_installer.msi"
Invoke-WebRequest -Uri $zipInstaller -OutFile $installerPath
Start-Process -FilePath $installerPath -ArgumentList "/qn /norestart" -Wait
