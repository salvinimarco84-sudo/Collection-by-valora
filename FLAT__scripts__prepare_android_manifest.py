#!/usr/bin/env python3
"""Prepare Android manifest permissions required by speech_to_text."""
from pathlib import Path
import sys

manifest = Path("android/app/src/main/AndroidManifest.xml")
if not manifest.exists():
    print(f"Manifest Android non trovato: {manifest}", file=sys.stderr)
    sys.exit(1)
text = manifest.read_text(encoding="utf-8")
permissions = [
    '    <uses-permission android:name="android.permission.INTERNET" />',
    '    <uses-permission android:name="android.permission.RECORD_AUDIO" />',
]
for permission in permissions:
    name = permission.split('name="', 1)[1].split('"', 1)[0]
    if name not in text:
        text = text.replace('<application', permission + "\n    <application", 1)
if 'android.speech.RecognitionService' not in text:
    query = "    <queries>\n        <intent>\n            <action android:name=\"android.speech.RecognitionService\" />\n        </intent>\n    </queries>\n"
    text = text.replace('<application', query + '    <application', 1)
manifest.write_text(text, encoding="utf-8")
print("Permessi Android per rete e riconoscimento vocale verificati.")
