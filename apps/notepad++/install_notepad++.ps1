$notepad++Installer = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.6/npp.8.6.Installer.x64.exe"
$installerPath = "$env:TEMP\notepad++_installer.exe"
Invoke-WebRequest -Uri $notepad++Installer -OutFile $installerPath
Start-Process -FilePath $installerPath -ArgumentList "/S /install" -Wait
