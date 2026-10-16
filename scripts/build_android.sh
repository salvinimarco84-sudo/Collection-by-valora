#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v flutter >/dev/null 2>&1 || { echo 'Flutter SDK non trovato.' >&2; exit 2; }
if [[ ! -d android || ! -d windows ]]; then
  flutter create --platforms=android,windows .
fi
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
printf '\nAPK generato: build/app/outputs/flutter-apk/app-debug.apk\n'
