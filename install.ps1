$ErrorActionPreference = "Stop"

$releaseRepo = "qri1/axoloti-windows-installer"
$assetPattern = "Axoloti-Windows-Payload.zip"
$installDir = Join-Path $env:LOCALAPPDATA "Axoloti"
$logFile = Join-Path ([Environment]::GetFolderPath("DesktopDirectory")) "Axoloti-Setup.log"

function Write-Log($Message) {
    $Message | Tee-Object -FilePath $logFile -Append
}

function Download-ReleaseAsset($Pattern, $OutFile) {
    $apiUrl = "https://api.github.com/repos/$releaseRepo/releases/latest"
    $release = Invoke-RestMethod -UseBasicParsing -Uri $apiUrl -Headers @{
        "User-Agent" = "AxolotiBootstrapInstaller"
    }

    $asset = $release.assets |
        Where-Object { $_.name -like $Pattern } |
        Sort-Object -Property name |
        Select-Object -First 1

    if (-not $asset) {
        $available = ($release.assets | ForEach-Object { $_.name }) -join ", "
        throw "No release asset matched '$Pattern'. Available assets: $available"
    }

    Write-Log "Downloading: $($asset.browser_download_url)"
    Invoke-WebRequest -UseBasicParsing -Uri $asset.browser_download_url -OutFile $OutFile
    if (Get-Command Unblock-File -ErrorAction SilentlyContinue) {
        Unblock-File -Path $OutFile
    }
}

function New-Shortcut($Path, $Target, $WorkingDirectory, $Icon) {
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($Path)
    $shortcut.TargetPath = $Target
    $shortcut.WorkingDirectory = $WorkingDirectory
    $shortcut.IconLocation = $Icon
    $shortcut.Save()
}

"" | Set-Content -Path $logFile
Write-Log "Axoloti setup started"
Write-Log "Install dir: $installDir"
Write-Log "Log file:    $logFile"

$payloadZip = Join-Path $env:TEMP "Axoloti-Windows-Payload.zip"

Write-Log "Downloading Axoloti payload..."
Download-ReleaseAsset $assetPattern $payloadZip

if (Test-Path $installDir) {
    Write-Log "Removing old install folder: $installDir"
    Remove-Item -LiteralPath $installDir -Recurse -Force
}

Write-Log "Unpacking Axoloti..."
New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Expand-Archive -Force $payloadZip $installDir
Remove-Item -LiteralPath $payloadZip -Force

Write-Log "Installing/checking dependencies..."
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $installDir "tools\install_windows_dependencies.ps1") *>> $logFile
if ($LASTEXITCODE -ne 0) {
    throw "Dependency installation failed. See log: $logFile"
}

Write-Log "Building Axoloti..."
& cmd.exe /c "`"$installDir\platform_win\build.bat`"" *>> $logFile
if ($LASTEXITCODE -ne 0) {
    throw "Axoloti build failed. See log: $logFile"
}

Write-Log "Creating shortcuts..."
$desktop = [Environment]::GetFolderPath("DesktopDirectory")
$startMenu = [Environment]::GetFolderPath("StartMenu")
$icon = Join-Path $installDir "src\main\java\resources\axoloti_icon.ico"
New-Shortcut (Join-Path $desktop "Axoloti.lnk") (Join-Path $installDir "Axoloti.bat") $installDir $icon
New-Shortcut (Join-Path $startMenu "Programs\Axoloti.lnk") (Join-Path $installDir "Axoloti.bat") $installDir $icon

Write-Log "Done."
Write-Host ""
Write-Host "Axoloti is installed in: $installDir"
Write-Host "Log file: $logFile"
