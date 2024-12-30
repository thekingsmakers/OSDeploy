$vscodeInstaller = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
$installerPath = "$env:TEMP\vscode_installer.exe"
Invoke-WebRequest -Uri $vscodeInstaller -OutFile $installerPath
Start-Process -FilePath $installerPath -ArgumentList "/silent /install" -Wait

