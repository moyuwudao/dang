#!/bin/bash
# WSL APK构建脚本
# 重要：此脚本负责将Windows代码同步到WSL并构建APK

export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PATH=/home/mayn/flutter/bin:/usr/bin:/bin:/usr/local/bin:$PATH

echo "=== 开始同步代码到WSL ==="

# 同步pubspec.yaml
cp /mnt/d/trae_projects/dang/pubspec.yaml /home/mayn/dang/pubspec.yaml

# 同步Android构建配置
cp /mnt/d/trae_projects/dang/android/app/build.gradle.kts /home/mayn/dang/android/app/build.gradle.kts

# 同步lib目录（核心代码）
echo "同步 lib/ 目录..."
rsync -av --delete /mnt/d/trae_projects/dang/lib/ /home/mayn/dang/lib/

# 同步assets目录（资源文件）
echo "同步 assets/ 目录..."
rsync -av --delete /mnt/d/trae_projects/dang/assets/ /home/mayn/dang/assets/ 2>/dev/null || true

# 同步其他可能修改的文件
echo "同步其他配置文件..."
rsync -av --delete /mnt/d/trae_projects/dang/android/ /home/mayn/dang/android/ 2>/dev/null || true

echo "=== 代码同步完成 ==="
echo ""
echo "=== 开始构建APK ==="

cd /home/mayn/dang

# 清理旧构建
flutter clean

# 获取依赖
flutter pub get

# 构建Release APK
flutter build apk --release

# 复制APK到Windows目录
cp /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk /mnt/d/trae_projects/dang/changji_app.apk

echo ""
echo "=== 构建完成 ==="
echo "APK已复制到: /mnt/d/trae_projects/dang/changji_app.apk"
