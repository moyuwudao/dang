---
alwaysApply: false
description: 构建dang的APK文件时生效
---

# 构建 APK 规则

## 环境要求

- **WSL 实例**: `dang`（Ubuntu 24.04 LTS，安装在 D 盘）
- **Flutter SDK**: `/home/mayn/flutter`（WSL 内）
- **Android SDK**: `/home/mayn/Android/Sdk`（WSL 内，Linux 版）
- **项目路径（WSL）**: `/home/mayn/dang`
- **项目路径（Windows）**: `d:\trae_projects\dang`

---

## ⚠️ 关键原则：必须同步完整代码

**APK 不更新的最常见原因**：只同步了配置文件，没有同步代码。

### 错误做法 ❌

```bash
# 只复制这些文件是不够的！
cp /mnt/d/trae_projects/dang/pubspec.yaml /home/mayn/dang/pubspec.yaml
cp /mnt/d/trae_projects/dang/android/app/build.gradle.kts /home/mayn/dang/android/app/build.gradle.kts
# WSL 内的 lib/ 目录仍然是旧代码，构建出来的 APK 不会更新
```

### 正确做法 ✅

```bash
# 必须同步 lib/ 和 assets/ 目录
rsync -av --delete /mnt/d/trae_projects/dang/lib/ /home/mayn/dang/lib/
rsync -av --delete /mnt/d/trae_projects/dang/assets/ /home/mayn/dang/assets/

# 然后同步配置文件
cp /mnt/d/trae_projects/dang/pubspec.yaml /home/mayn/dang/pubspec.yaml
cp /mnt/d/trae_projects/dang/pubspec.lock /home/mayn/dang/pubspec.lock
cp /mnt/d/trae_projects/dang/android/app/build.gradle.kts /home/mayn/dang/android/app/build.gradle.kts
```

---

## 构建命令

### 🔸 一键构建（推荐，最可靠）

从 Windows PowerShell 执行：

```powershell
# 第1步：在 WSL 内部构建
wsl -d dang bash -c "export PUB_HOSTED_URL=https://pub.flutter-io.cn && export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn && export PATH=/home/mayn/flutter/bin:/usr/bin:/bin:/usr/local/bin:\$PATH && cd /home/mayn/dang && flutter clean && flutter build apk --release"

# 第2步：使用 WSL cp 命令复制 APK（禁止使用 Windows copy / Copy-Item）
wsl -d dang bash -c "cp /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk /mnt/d/trae_projects/dang/changji_app.apk"

# 第3步：验证 APK 时间戳已更新
Get-Item D:\trae_projects\dang\changji_app.apk | Select-Object Name, LastWriteTime, Length
```

**为什么这个方法最好？**
- ✅ `flutter clean` 确保完整重新编译
- ✅ `flutter build apk --release` 比直接调用 Gradle 更可靠
- ✅ 避免了 Gradle Daemon 的缓存问题
- ✅ **使用 WSL `cp` 命令复制，确保 APK 是最新生成的（Windows copy 会复制旧缓存文件）**

### 🔸 标准构建（使用脚本）
```powershell
# 从 Windows 执行
wsl -d dang exec /usr/bin/bash /mnt/d/trae_projects/dang/build_wsl.sh
```

### 构建脚本内容 (build_wsl.sh)

```bash
#!/bin/bash
set -e

export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PATH=/home/mayn/flutter/bin:/usr/bin:/bin:/usr/local/bin:$PATH

# ⚠️ 必须同步完整项目代码（lib/ 和 assets/ 目录）
echo "同步 lib/ 目录..."
rsync -av --delete /mnt/d/trae_projects/dang/lib/ /home/mayn/dang/lib/

echo "同步 assets/ 目录..."
rsync -av --delete /mnt/d/trae_projects/dang/assets/ /home/mayn/dang/assets/

# 同步配置文件
echo "同步配置文件..."
cp /mnt/d/trae_projects/dang/pubspec.yaml /home/mayn/dang/pubspec.yaml
cp /mnt/d/trae_projects/dang/pubspec.lock /home/mayn/dang/pubspec.lock
cp /mnt/d/trae_projects/dang/android/app/build.gradle.kts /home/mayn/dang/android/app/build.gradle.kts

# ⚠️ 使用 flutter clean 确保完整重新编译
echo "清理构建..."
cd /home/mayn/dang
flutter clean

# 获取依赖
echo "获取依赖..."
flutter pub get

# ⚠️ 使用 flutter build apk --release 而不是直接调用 Gradle
echo "构建 APK..."
flutter build apk --release

# 复制 APK 到 Windows（必须使用 WSL cp 命令，不能用 Windows copy）
cp /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk /mnt/d/trae_projects/dang/changji_app.apk

echo "构建完成！"
echo "APK 路径: /mnt/d/trae_projects/dang/changji_app.apk"
```

### 手动步骤（完整流程）

```bash
# 进入 WSL
wsl -d dang

# 设置环境变量
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PATH=/home/mayn/flutter/bin:/usr/bin:/bin:/usr/local/bin:$PATH

# ⚠️ 必须同步完整项目代码（lib/ 和 assets/ 目录）
echo "同步 lib/ 目录..."
rsync -av --delete /mnt/d/trae_projects/dang/lib/ /home/mayn/dang/lib/

echo "同步 assets/ 目录..."
rsync -av --delete /mnt/d/trae_projects/dang/assets/ /home/mayn/dang/assets/

# 同步配置文件
echo "同步配置文件..."
cp /mnt/d/trae_projects/dang/pubspec.yaml /home/mayn/dang/pubspec.yaml
cp /mnt/d/trae_projects/dang/pubspec.lock /home/mayn/dang/pubspec.lock
cp /mnt/d/trae_projects/dang/android/app/build.gradle.kts /home/mayn/dang/android/app/build.gradle.kts

# 进入项目目录
cd /home/mayn/dang

# ⚠️ 使用 flutter clean 确保完整重新编译
flutter clean

# 获取依赖
flutter pub get

# ⚠️ 使用 flutter build apk --release 而不是直接调用 Gradle
flutter build apk --release

# ⚠️ 使用 WSL cp 命令复制 APK 到 Windows（不能用 Windows copy）
cp /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk /mnt/d/trae_projects/dang/changji_app.apk

# 验证 APK 时间戳
ls -la /mnt/d/trae_projects/dang/changji_app.apk
```

---

## 签名配置

### 密钥库信息
- **文件位置（WSL）**: `/home/mayn/.android/signing/changji.jks`
- **密钥别名**: `changji`
- **存储密码**: `123456`
- **密钥密码**: `123456`

### key.properties 配置
```properties
storePassword=123456
keyPassword=123456
keyAlias=changji
storeFile=/home/mayn/.android/signing/changji.jks
```

---

## 输出文件

构建成功后生成的 APK 文件：
- **WSL**: `/home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk`
- **Windows**: `d:\trae_projects\dang\build\app\outputs\flutter-apk\app-release.apk`（自动复制）
- **工作副本**: `d:\trae_projects\dang\changji_app.apk`（需要手动复制）

### 复制 APK 为工作副本（必须使用 WSL cp 命令）

**错误方式** ❌（Windows 命令会复制 WSL 挂载目录下的旧缓存文件，时间戳不更新）：
```powershell
# ❌ 不要这样复制
copy D:\trae_projects\dang\build\app\outputs\flutter-apk\app-release.apk D:\trae_projects\dang\changji_app.apk
Copy-Item D:\trae_projects\dang\build\app\outputs\flutter-apk\app-release.apk D:\trae_projects\dang\changji_app.apk -Force
```

**正确方式** ✅（使用 WSL `cp` 命令，确保复制的是 WSL 内部新生成的文件）：
```powershell
# ✅ 使用 WSL cp 命令
wsl -d dang bash -c "cp /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk /mnt/d/trae_projects/dang/changji_app.apk"
```

### 验证 APK 已更新
```powershell
# 检查文件修改时间和大小（LastWriteTime 应该是当前时间，不是昨天或更早）
Get-Item D:\trae_projects\dang\changji_app.apk | Select-Object Name, LastWriteTime, Length
```

---

## 配置文件说明

### android/local.properties（WSL 版本）
```properties
flutter.sdk=/home/mayn/flutter
sdk.dir=/home/mayn/Android/Sdk
flutter.buildMode=release
flutter.versionName=1.0.0
flutter.versionCode=1
```

### android/gradle.properties
```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
org.gradle.daemon=false
```

---

## WSL 环境配置

### .bashrc 环境变量
```bash
source /home/mayn/env_setup.sh
```

### /home/mayn/env_setup.sh
```bash
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PATH=/home/mayn/flutter/bin:$PATH
```

---

## 排查问题

### ⚠️ APK 不更新

这是**最常见的问题**，请按以下步骤排查：

1. **确认 Windows 代码已保存** - 确保修改已写入磁盘
2. **同步 lib/ 目录** - 使用 rsync 或 cp -r
   ```bash
   rsync -av --delete /mnt/d/trae_projects/dang/lib/ /home/mayn/dang/lib/
   ```
3. **同步 assets/ 目录** - 如果有资源文件改动
   ```bash
   rsync -av --delete /mnt/d/trae_projects/dang/assets/ /home/mayn/dang/assets/
   ```
4. **使用 flutter clean 清理** - ⚠️ 这很重要！
   ```bash
   flutter clean
   ```
5. **使用 flutter build apk --release 重新构建** - 而不是直接调用 Gradle

### 常见问题

| 问题 | 解决方案 |
|-----|---------|
| **APK 不更新** | ⚠️ 检查是否同步了 lib/ 和 assets/ 目录 + flutter clean |
| **Gradle Daemon 缓存问题** | 使用 `flutter build apk --release` 而不是 `./gradlew` |
| **integration_test 编译错误** | 构建前临时移除 `integration_test`，构建后恢复 |
| **compileSdkVersion 过低** | 修改插件的 `build.gradle` 中的 `compileSdkVersion` 为 36 |
| **Kotlin Daemon 权限问题** | 使用 `--no-daemon` 参数 |
| **跨文件系统性能问题** | 使用 rsync 同步代码到 WSL 本地文件系统 |

### ⚠️ 实际案例：代码已修改但 APK 未更新

**现象**：
修改 `multi_api_config_screen.dart` 添加"语音实时转写"选项（第4个功能），构建 APK 后安装，仍只显示3个选项。

**排查过程**：
1. ✅ 代码已保存到磁盘
2. ✅ `flutter clean` 已执行
3. ✅ 构建成功，无错误
4. ❌ **未执行 `rsync` 同步 `lib/` 目录到 WSL**

**根本原因**：
WSL 中的 `/home/mayn/dang/lib/` 仍是旧代码，构建使用的是旧代码，Windows 上的新代码未被同步。

**解决**：
```bash
# 同步 lib/ 目录到 WSL
rsync -av --delete /mnt/d/trae_projects/dang/lib/ /home/mayn/dang/lib/

# 重新构建
flutter clean && flutter build apk --release
```

**验证**：
构建后 APK 正确显示4个功能选项（文本分析、语音转写、语音实时转写、图像识别）。

**教训**：
> 修改代码后构建 APK，**必须**先执行 `rsync` 同步 `lib/` 目录到 WSL，否则构建的是旧代码。

### 常见问题详细解决

#### 1. integration_test 编译错误
**问题**: `package dev.flutter.plugins.integration_test does not exist`
**解决**: 构建前临时从 `pubspec.yaml` 移除 `integration_test`，构建后恢复

#### 2. compileSdkVersion 过低
**问题**: `resource android:attr/lStar not found`
**解决**: 修改插件的 `build.gradle` 中的 `compileSdkVersion` 为 36
```bash
sed -i 's/compileSdkVersion 29/compileSdkVersion 36/g' /home/mayn/.pub-cache/hosted/pub.flutter-io.cn/google_mlkit_commons-0.6.1/android/build.gradle
sed -i 's/compileSdkVersion 31/compileSdkVersion 36/g' /home/mayn/.pub-cache/hosted/pub.flutter-io.cn/google_mlkit_text_recognition-0.11.0/android/build.gradle
```

#### 3. Windows Flutter SDK 路径问题
**问题**: WSL 无法使用 Windows 的 `dart.exe`
**解决**: 使用 WSL 内的 Flutter SDK（`/home/mayn/flutter`），确保 Dart SDK 已下载

#### 4. Kotlin Daemon 权限问题
**解决**: 使用 `--no-daemon` 参数，或者直接用 `flutter build apk --release`

#### 5. 跨文件系统性能问题
**问题**: 在 `/mnt/d/` 上构建非常慢
**解决**: 将项目复制到 WSL 本地文件系统（`/home/mayn/dang`），使用 rsync 同步

---

## 安装命令

### 覆盖安装（保留数据）
```powershell
adb install -r "d:\trae_projects\dang\build\app\outputs\flutter-apk\app-release.apk"
```

### 全新安装（清除数据）
```powershell
adb install "d:\trae_projects\dang\build\app\outputs\flutter-apk\app-release.apk"
```

### 查看已安装的包
```powershell
adb shell pm list packages | findstr dang
```

---

## 📋 完整构建流程总结

每次构建时按以下顺序执行：

1. **保存 Windows 代码** - 确保所有修改已写入文件
2. **同步代码到 WSL** - `rsync -av --delete /mnt/d/trae_projects/dang/lib/ /home/mayn/dang/lib/`
3. **一键构建** - 使用推荐的 PowerShell 命令
4. **复制为工作副本** - 使用 WSL `cp` 命令复制到 `changji_app.apk`
5. **验证 APK 时间戳** - `Get-Item` 检查 `LastWriteTime`
6. **安装测试** - adb install 测试

### ⚠️ 关键检查点

| 步骤 | 检查项 | 失败后果 |
|-----|--------|---------|
| 同步代码 | `rsync` 是否执行 | APK 包含旧代码，修改不生效 |
| 复制 APK | 是否使用 WSL `cp` | 复制的是旧缓存文件，时间戳不更新 |
| 验证时间戳 | `LastWriteTime` 是否当前时间 | 无法确认 APK 是否已更新 |
