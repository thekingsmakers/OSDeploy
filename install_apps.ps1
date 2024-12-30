# Software Selection and Installation Script
$repoUrl = "https://github.com/thekingsmakers/OSDeploy/blob/4646ee042c66df1446a5dcefa5d919a65c67c1c9/install_apps.ps1"
$softwareList = Get-Content -Raw -Path ".\software_list.json" | ConvertFrom-Json
$selectedApps = @()

Write-Host "Select software to install (use space to select, Enter to proceed):"

foreach ($app in $softwareList) {
    $selected = Read-Host "Install $($app.name)? (Y/N)"
    if ($selected -eq "Y") {
        $selectedApps += $app.id
    }
}

$logFile = "$env:TEMP\install_log.txt"
$installSummary = @()

foreach ($software in $selectedApps) {
    $scriptUrl = "$repoUrl/$software/install_$software.ps1"
    try {
        Write-Host "Installing $software..."
        $scriptContent = Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing
        Invoke-Expression $scriptContent.Content
        $installSummary += "$software - Installed Successfully"
        Add-Content -Path $logFile -Value "$software - SUCCESS at $(Get-Date)"
    }
    catch {
        $installSummary += "$software - Failed to Install"
        Add-Content -Path $logFile -Value "$software - FAILED at $(Get-Date)"
    }
}

# Generate Summary Page
$summaryHtml = @"
<html>
<head><title>Installation Summary</title></head>
<body>
<h1>Installation Summary</h1>
<ul>
"@
foreach ($entry in $installSummary) {
    $summaryHtml += "<li>$entry</li>"
}
$summaryHtml += "</ul></body></html>"

$summaryPath = "$env:TEMP\install_summary.html"
$summaryHtml | Out-File -FilePath $summaryPath
Start-Process $summaryPath

