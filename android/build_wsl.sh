#!/bin/bash

FLUTTER_SDK="/home/mayn/flutter"

echo "flutter.sdk=$FLUTTER_SDK" > /mnt/d/trae_projects/dang/android/local.properties
echo "sdk.dir=/home/mayn/Android/Sdk" >> /mnt/d/trae_projects/dang/android/local.properties
echo "flutter.buildMode=release" >> /mnt/d/trae_projects/dang/android/local.properties
echo "flutter.versionName=1.0.0" >> /mnt/d/trae_projects/dang/android/local.properties
echo "flutter.versionCode=1" >> /mnt/d/trae_projects/dang/android/local.properties

cd /mnt/d/trae_projects/dang/android
./gradlew assembleRelease --no-daemon