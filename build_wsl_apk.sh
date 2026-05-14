#!/bin/bash

cd /mnt/d/trae_projects/dang

cat > android/local.properties << 'EOF'
flutter.sdk=/mnt/c/flutter-sdk
sdk.dir=/mnt/c/flutter-sdk/android-sdk
flutter.buildMode=release
flutter.versionName=1.0.0
flutter.versionCode=1
FLUTTER_ROOT=/mnt/c/flutter-sdk
EOF

export FLUTTER_ROOT=/mnt/c/flutter-sdk

cd android
./gradlew assembleRelease --no-daemon -Dorg.gradle.jvmargs="-Xmx8G"