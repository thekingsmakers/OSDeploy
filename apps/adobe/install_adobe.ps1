$adobeReaderInstaller = "https://get.adobe.com/reader/download/?installer=Reader_DC_XX_T1_GM&stype=main&standalone=1"
$installerPath = "$env:TEMP\adobe_reader_installer.exe"
Invoke-WebRequest -Uri $adobeReaderInstaller -OutFile $installerPath
Start-Process -FilePath $installerPath -ArgumentList "/sAll /msi" -Wait

