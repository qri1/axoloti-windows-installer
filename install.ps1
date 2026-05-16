$ErrorActionPreference = "Stop"

$releaseRepo = "qri1/axoloti-windows-installer"
$assetPattern = "Axoloti-OneClick-Setup-SAFE.cmd"

Write-Host "Axoloti bootstrap installer"
Write-Host "Release repo: $releaseRepo"
Write-Host "Asset match:  $assetPattern"
Write-Host ""

$apiUrl = "https://api.github.com/repos/$releaseRepo/releases/latest"
$release = Invoke-RestMethod -UseBasicParsing -Uri $apiUrl -Headers @{
    "User-Agent" = "AxolotiBootstrapInstaller"
}

$asset = $release.assets |
    Where-Object { $_.name -like $assetPattern } |
    Sort-Object -Property name |
    Select-Object -First 1

if (-not $asset) {
    $available = ($release.assets | ForEach-Object { $_.name }) -join ", "
    throw "No release asset matched '$assetPattern'. Available assets: $available"
}

$downloadPath = Join-Path $env:TEMP $asset.name
Write-Host "Downloading: $($asset.browser_download_url)"
Invoke-WebRequest -UseBasicParsing -Uri $asset.browser_download_url -OutFile $downloadPath

if (Get-Command Unblock-File -ErrorAction SilentlyContinue) {
    Unblock-File -Path $downloadPath
}

Write-Host "Starting installer: $downloadPath"
Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$downloadPath`"" -Wait
