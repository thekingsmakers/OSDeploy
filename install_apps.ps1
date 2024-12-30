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

# Function to Clear Current Line
function Clear-Line {
    Write-Host "`r" + (" " * 80) + "`r" -NoNewline
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
Write-Log "`nAvailable Software:" "INFO"
for ($i = 0; $i -lt $softwareList.software.Count; $i++) {
    Write-Host "[$($i+1)] $($softwareList.software[$i].name)" -ForegroundColor Yellow
}

# Input Handling with Timeout
$timeout = 10
$choices = $null
$startTime = Get-Date

Write-Host "`nPress Enter to install all, or type numbers (e.g., 1,3,5) for specific software..." -ForegroundColor DarkGray
Write-Host "Auto-installing all in $timeout seconds..." -ForegroundColor DarkGray

while ((Get-Date) - $startTime).TotalSeconds -lt $timeout) {
    if ($Host.UI.RawUI.KeyAvailable) {
        $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        Clear-Line
        if ($key.VirtualKeyCode -eq 13) { # Enter key
            $choices = ""
            break
        }
        $Host.UI.RawUI.FlushInputBuffer()
        $choices = Read-Host "Enter your choices"
        break
    }
    
    $remainingTime = [math]::Round($timeout - ((Get-Date) - $startTime).TotalSeconds)
    Write-Host "Auto-installing in [$remainingTime] seconds..." -NoNewline -ForegroundColor DarkCyan
    Start-Sleep -Milliseconds 1000
    Clear-Line
}

Clear-Line

# Process Software Selection
if (-not $choices) {
    Write-Log "Installing all software..." "WARN"
    $toInstall = $softwareList.software
} else {
    $choices = $choices -split "[,\s]+" | Where-Object { $_ -match '^\d+$' }
    $toInstall = @()
    
    foreach ($choice in $choices) {
        if ([int]$choice -le $softwareList.software.Count) {
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

# Create Installation Directory if it doesn't exist
$installDir = "$env:TEMP\SoftwareInstall"
if (-not (Test-Path -Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir | Out-Null
}

# Install Selected Software
$installationResults = @()
foreach ($software in $toInstall) {
    Write-Log "Processing $($software.name)..." "INFO"
    $status = "Failed"
    $installerPath = "$installDir\$($software.id).exe"

    # Download Installer
    try {
        Invoke-WebRequest -Uri $software.url -OutFile $installerPath
        Write-Log "$($software.name) downloaded successfully!" "SUCCESS"
        
        # Install Software
        Write-Log "Installing $($software.name)..." "INFO"
        $process = Start-Process -FilePath $installerPath -ArgumentList $software.silentArgs -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Log "$($software.name) installed successfully!" "SUCCESS"
            $status = "Successful"
        } else {
            Write-Log "Installation failed for $($software.name) with exit code $($process.ExitCode)" "ERROR"
        }
    } catch {
        Write-Log "Error processing $($software.name): $_" "ERROR"
    } finally {
        # Cleanup
        if (Test-Path -Path $installerPath) {
            Remove-Item -Path $installerPath -Force
        }
    }
    
    $installationResults += [PSCustomObject]@{
        Software = $software.name
        Status = $status
        InstallTime = Get-Date
    }
}

# Generate Installation Summary
$summaryPath = "$PSScriptRoot\install_summary.html"
$css = @"
<style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1 { color: #333; }
    table { border-collapse: collapse; width: 100%; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background-color: #f2f2f2; }
    .success { color: green; }
    .failed { color: red; }
    footer { margin-top: 20px; color: #666; }
</style>
"@

$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Installation Summary</title>
    $css
</head>
<body>
    <h1>Installation Summary</h1>
    <table>
        <tr>
            <th>Software</th>
            <th>Status</th>
            <th>Install Time</th>
        </tr>
"@

foreach ($result in $installationResults) {
    $statusClass = if ($result.Status -eq "Successful") { "success" } else { "failed" }
    $htmlContent += @"
        <tr>
            <td>$($result.Software)</td>
            <td class="$statusClass">$($result.Status)</td>
            <td>$($result.InstallTime)</td>
        </tr>
"@
}

$htmlContent += @"
    </table>
    <footer>Installation completed at $(Get-Date)</footer>
</body>
</html>
"@

$htmlContent | Out-File -FilePath $summaryPath -Encoding UTF8
Write-Log "Installation summary created: $summaryPath" "INFO"

# Clean up installation directory
Remove-Item -Path $installDir -Recurse -Force

# Optional: Open Summary in Browser
Start-Process $summaryPath
