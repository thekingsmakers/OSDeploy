# Define Paths and URLs
$repoURL = "https://raw.githubusercontent.com/thekingsmakers/OSDeploy/main/software_list.json"
$softwareListPath = "$PSScriptRoot\software_list.json"

# Check if software_list.json exists, download if missing
if (-not (Test-Path -Path $softwareListPath)) {
    Write-Host "Downloading software_list.json..."
    try {
        Invoke-WebRequest -Uri $repoURL -OutFile $softwareListPath
        Write-Host "Download successful!"
    } catch {
        Write-Host "Failed to download software_list.json. Exiting..."
        exit 1
    }
}

# Read the JSON File
try {
    $softwareList = Get-Content -Raw -Path $softwareListPath | ConvertFrom-Json
} catch {
    Write-Host "Error reading software_list.json. Exiting..."
    exit 1
}

# Display Software Selection
Write-Host "Select the software you want to install:`n"
$selectedSoftware = @{}

for ($i = 0; $i -lt $softwareList.software.Count; $i++) {
    Write-Host "[$($i+1)] $($softwareList.software[$i].name) - $($softwareList.software[$i].category)"
}

$choices = Read-Host "Enter the numbers (comma-separated) of the software to install (e.g., 1,3,5)"

# Validate User Input
$choices = $choices -split "," | ForEach-Object { $_.Trim() }
$toInstall = @()

foreach ($choice in $choices) {
    if ($choice -match '^\d+$' -and [int]$choice -le $softwareList.software.Count) {
        $toInstall += $softwareList.software[[int]$choice - 1]
    } else {
        Write-Host "Invalid choice: $choice"
    }
}

if ($toInstall.Count -eq 0) {
    Write-Host "No valid software selected. Exiting..."
    exit 1
}

# Install Software
foreach ($software in $toInstall) {
    Write-Host "Installing $($software.name)..."

    $installerPath = "$env:TEMP\$($software.id).exe"

    # Download Installer
    try {
        Invoke-WebRequest -Uri $software.url -OutFile $installerPath
        Write-Host "$($software.name) downloaded successfully!"
    } catch {
        Write-Host "Failed to download $($software.name). Skipping..."
        continue
    }

    # Install Silently
    try {
        Start-Process -FilePath $installerPath -ArgumentList $software.silentArgs -Wait
        Write-Host "$($software.name) installed successfully!"
    } catch {
        Write-Host "Failed to install $($software.name)."
    }

    # Clean Up
    Remove-Item -Path $installerPath -Force
}

# Summary Page
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
Write-Host "Installation summary created: $summaryPath"

# Open Summary in Browser (Optional)
Start-Process $summaryPath
