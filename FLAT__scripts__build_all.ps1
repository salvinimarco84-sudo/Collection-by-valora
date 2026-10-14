$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter SDK non trovato.' }
if (-not (Test-Path 'android') -or -not (Test-Path 'windows')) {
  flutter create --platforms=android,windows .
  if ($LASTEXITCODE -ne 0) { throw 'Generazione piattaforme fallita.' }
}
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get fallito.' }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'flutter analyze fallito.' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'flutter test fallito.' }
flutter build apk --debug
if ($LASTEXITCODE -ne 0) { throw 'Build APK fallita.' }
flutter build windows
if ($LASTEXITCODE -ne 0) { throw 'Build Windows fallita.' }
Write-Host 'APK: build/app/outputs/flutter-apk/app-debug.apk'
Write-Host 'Windows: build/windows/x64/runner/Release/'
