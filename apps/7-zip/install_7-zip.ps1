$7-zipInstaller = "https://github.com/ip7z/7zip/releases/download/24.09/7z2409.msi"
$installerPath = "$env:TEMP\7-zip_installer.exe"
Invoke-WebRequest -Uri $7-zipInstaller -OutFile $installerPath
Start-Process -FilePath $installerPath -ArgumentList "/qn /norestart /install" -Wait
