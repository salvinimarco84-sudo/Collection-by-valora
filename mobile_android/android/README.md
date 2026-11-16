# Android host configuration

This directory contains the native Android host for COLLECTION by VALORA.

- Application ID / namespace: `com.demonsoftwarehouse.valora`
- Authentication callback: `com.demonsoftwarehouse.valora://auth-callback`
- Deep-link intent filter: `app/src/main/AndroidManifest.xml`
- Main activity: `app/src/main/kotlin/com/demonsoftwarehouse/valora/MainActivity.kt`

The Gradle wrapper scripts (`gradlew`, `gradlew.bat`) and wrapper JAR are not yet present. Generate them with the Flutter SDK (`flutter create --platforms=android .` in a clean temporary Flutter project, then reconcile the generated wrapper files) before running a local Android build. Do not overwrite the application configuration in this repository blindly. No build is claimed by this scaffold commit.
