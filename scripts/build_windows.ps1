$ErrorActionPreference = 'Stop'
flutter pub get
flutter analyze
flutter test
flutter build windows
Write-Host "Windows package: build/windows/x64/runner/Release/"
