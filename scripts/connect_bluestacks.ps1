# BlueStacks Flutter ADB Connector
# Resolves the Android SDK ADB and connects to active BlueStacks instances.

[CmdletBinding()]
param (
    [string]$Port,
    [switch]$Run
)

$ErrorActionPreference = "Stop"

Write-Host "=== BlueStacks Flutter ADB Connector ===" -ForegroundColor Cyan

# 1. Locate Android SDK ADB (avoid BlueStacks bundled HD-Adb.exe)
$adbCandidates = @(
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "$env:ANDROID_HOME\platform-tools\adb.exe",
    (Get-Command adb -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
)

$adbPath = $null
foreach ($candidate in $adbCandidates) {
    if ($candidate -and (Test-Path $candidate)) {
        if ($candidate -notmatch "BlueStacks") {
            $adbPath = $candidate
            break
        }
    }
}

if (-not $adbPath) {
    Write-Error "Could not find Android SDK adb.exe. Please ensure Android SDK platform-tools are installed."
    exit 1
}

Write-Host "[OK] Using Android SDK ADB: $adbPath" -ForegroundColor Green

# 2. Determine target port(s)
$targets = @()

if ($Port) {
    $targets += [PSCustomObject]@{
        Instance = "Manual"
        Port     = $Port
    }
} else {
    $confPath = "C:\ProgramData\BlueStacks_nxt\bluestacks.conf"
    if (Test-Path $confPath) {
        $lines = Get-Content $confPath
        foreach ($line in $lines) {
            if ($line -like "*status.adb_port=*") {
                $parts = $line.Split("=")
                if ($parts.Length -eq 2) {
                    $rawPort = $parts[1].Replace([string][char]34, [string]::Empty)
                    $port = $rawPort.Trim()
                    $rawInst = $parts[0].Replace("bst.instance.", [string]::Empty)
                    $inst = $rawInst.Replace(".status.adb_port", [string]::Empty).Trim()
                    $targets += [PSCustomObject]@{
                        Instance = $inst
                        Port     = $port
                    }
                }
            }
        }
    }

    if ($targets.Count -eq 0) {
        Write-Warning "No running BlueStacks instances found with active status.adb_port in $confPath."
        Write-Host "Please ensure BlueStacks is running and ADB is enabled in Settings -> Advanced." -ForegroundColor Yellow
        exit 1
    }
}

# 3. Connect to each target
$connectedDevice = $null
foreach ($target in $targets) {
    $instName = $target.Instance
    $instPort = $target.Port
    $address = "127.0.0.1:$instPort"
    Write-Host "[>] Connecting to BlueStacks instance $instName at $address..." -ForegroundColor Yellow
    $connectOutput = & $adbPath connect $address
    Write-Host "    $connectOutput" -ForegroundColor Gray

    if ($connectOutput -match "connected to") {
        $connectedDevice = $address
    }
}

# 4. Display connected devices
Write-Host "`n[OK] Current ADB Devices:" -ForegroundColor Cyan
& $adbPath devices

# 5. Optionally run Flutter app
if ($Run) {
    if (-not $connectedDevice) {
        Write-Warning "No BlueStacks device was successfully connected to run Flutter on."
        exit 1
    }

    $flutterProject = Join-Path $PSScriptRoot "..\word_search_app"
    if (-not (Test-Path $flutterProject)) {
        $flutterProject = (Get-Location).Path
    }

    Write-Host "`n[>] Launching Flutter app on $connectedDevice (Directory: $flutterProject)..." -ForegroundColor Cyan
    Push-Location $flutterProject
    try {
        flutter run -d $connectedDevice
    } finally {
        Pop-Location
    }
} else {
    Write-Host "`nTo run your Flutter app targeting this BlueStacks instance, run:" -ForegroundColor Green
    if ($connectedDevice) {
        Write-Host "  flutter run -d $connectedDevice" -ForegroundColor White
    } else {
        Write-Host "  flutter run -d 127.0.0.1:<port>" -ForegroundColor White
    }
}
