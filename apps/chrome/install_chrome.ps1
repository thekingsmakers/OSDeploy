$chromeInstaller = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
$installerPath = "$env:TEMP\chrome_installer.exe"
Invoke-WebRequest -Uri $chromeInstaller -OutFile $installerPath
Start-Process -FilePath $installerPath -ArgumentList "/silent /install" -Wait

