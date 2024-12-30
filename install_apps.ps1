# Enable Colors in Terminal
$Host.UI.RawUI.BackgroundColor = "Black"
Clear-Host

# Define Paths and URLs
$repoURL = "https://raw.githubusercontent.com/thekingsmakers/OSDeploy/main/software_list.json"
$softwareListPath = "$PSScriptRoot\software_list.json"

# Function to Display Logs with Colors
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    switch ($Level) {
        "INFO"    { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
        "SUCCESS" { Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
        "ERROR"   { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        "WARN"    { Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
    }
}

# Download software_list.json if missing
if (-not (Test-Path -Path $softwareListPath)) {
    Write-Log "Downloading software_list.json..." "INFO"
    try {
        Invoke-WebRequest -Uri $repoURL -OutFile $softwareListPath
        Write-Log "software_list.json download successful!" "SUCCESS"
    } catch {
        Write-Log "Failed to download software_list.json. Exiting..." "ERROR"
        exit 1
    }
}

# Read the JSON File
try {
    $softwareList = Get-Content -Raw -Path $softwareListPath | ConvertFrom-Json
} catch {
    Write-Log "Error reading software_list.json. Exiting..." "ERROR"
    exit 1
}

# Display Software Selection with Numbers
Write-Log "`nSelect the software you want to install (or wait for auto-install in 10 seconds):" "INFO"
for ($i = 0; $i -lt $softwareList.software.Count; $i++) {
    Write-Host "[$($i+1)] $($softwareList.software[$i].name)" -ForegroundColor Yellow
}

# Countdown Timer for Auto-Install
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$timeout = 10
$choices = @()

Write-Host "`nPress Enter or choose software by typing numbers (e.g., 1,3,5)..." -ForegroundColor DarkGray
while ($stopwatch.Elapsed.Seconds -lt $timeout) {
    if ([console]::KeyAvailable) {
        $choices = Read-Host "Enter your choices"
        break
    }
    Write-Host "Auto-installing in [$($timeout - $stopwatch.Elapsed.Seconds)] seconds..." -NoNewline -ForegroundColor DarkCyan
    Start-Sleep -Milliseconds 1000
    Write-Host "`r" -NoNewline
}

# If no input, install all software
if (-not $choices) {
    Write-Log "No input detected. Installing all software..." "WARN"
    $toInstall = $softwareList.software
} else {
    $choices = $choices -split "," | ForEach-Object { $_.Trim() }
    $toInstall = @()
    
    foreach ($choice in $choices) {
        if ($choice -match '^\d+$' -and [int]$choice -le $softwareList.software.Count) {
            $toInstall += $softwareList.software[[int]$choice - 1]
        } else {
            Write-Log "Invalid choice: $choice" "WARN"
        }
    }
}

if ($toInstall.Count -eq 0) {
    Write-Log "No valid software selected. Exiting..." "ERROR"
    exit 1
}

# Install Selected Software
foreach ($software in $toInstall) {
    Write-Log "Installing $($software.name)..." "INFO"

    $installerPath = "$env:TEMP\$($software.id).exe"

    # Download Installer
    try {
        Invoke-WebRequest -Uri $software.url -OutFile $installerPath
        Write-Log "$($software.name) downloaded successfully!" "SUCCESS"
    } catch {
        Write-Log "Failed to download $($software.name). Skipping..." "ERROR"
        continue
    }

    # Install with Progress
    Write-Log "Starting installation for $($software.name)..." "INFO"
    try {
        Start-Process -FilePath $installerPath -ArgumentList $software.silentArgs -Wait
        Write-Log "$($software.name) installed successfully!" "SUCCESS"
    } catch {
        Write-Log "Installation failed for $($software.name)!" "ERROR"
    }

    # Clean Up
    Remove-Item -Path $installerPath -Force
}

# Generate Installation Summary
$summaryPath = "$PSScriptRoot\install_summary.html"
$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Installation Summary</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <h1>Installation Summary</h1>
    <table>
        <tr>
            <th>Software</th>
            <th>Status</th>
        </tr>
"@

foreach ($software in $toInstall) {
    $htmlContent += "<tr><td>$($software.name)</td><td>Installed</td></tr>`n"
}

$htmlContent += @"
    </table>
    <footer>Installation completed at $(Get-Date)</footer>
</body>
</html>
"@

$htmlContent | Out-File -FilePath $summaryPath
Write-Log "Installation summary created: $summaryPath" "INFO"

# Optional: Open Summary in Browser
Start-Process $summaryPath
