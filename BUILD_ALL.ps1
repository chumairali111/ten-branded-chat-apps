param(
    [string]$Flutter = 'C:\src\flutter\bin\flutter.bat',
    [ValidateRange(1,10)][int]$From = 1,
    [ValidateRange(1,10)][int]$To = 10
)
$ErrorActionPreference = 'Stop'
if ($From -gt $To) { throw 'From must not exceed To.' }
if (-not (Test-Path $Flutter)) { throw "Flutter executable not found: $Flutter" }
$root = $PSScriptRoot
$output = Join-Path $root 'APKs'
New-Item -ItemType Directory -Force -Path $output | Out-Null
$apps = Get-Content (Join-Path $root 'apps.json') -Raw | ConvertFrom-Json
$oldLocation = Get-Location
try {
    foreach ($index in $From..$To) {
        $app = $apps[$index - 1]
        Set-Location (Join-Path $root $app.folder)
        Write-Host "Building $($app.name) ($index of 10)" -ForegroundColor Cyan
        & $Flutter pub get
        if ($LASTEXITCODE -ne 0) { throw "Dependency setup failed for $($app.name)" }
        & $Flutter build apk --release "--dart-define=API_BASE_URL=$($app.backend)"
        if ($LASTEXITCODE -ne 0) { throw "Build failed for $($app.name). Resume using -From $index" }
        $apk = Join-Path (Get-Location) 'build\app\outputs\flutter-apk\app-release.apk'
        if (-not (Test-Path $apk)) { throw "APK missing for $($app.name)" }
        Copy-Item $apk (Join-Path $output "$($app.folder).apk") -Force
    }
} finally { Set-Location $oldLocation }
Write-Host "Finished. APKs saved in $output" -ForegroundColor Green
