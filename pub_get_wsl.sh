#!/bin/bash
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PATH=/home/mayn/flutter/bin:/usr/bin:/bin:/usr/local/bin:$PATH

rm -f /home/mayn/flutter/.pub-cache
cd /home/mayn/dang
flutter pub get 2>&1
