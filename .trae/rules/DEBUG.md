---
alwaysApply: false
globs: lib/**/*.dart
description: Flutter 开发调试规范 - 热重载、设备选择、日志查看等日常操作
---

# DEBUG.md - Flutter 开发调试规范

## 核心理念

Flutter 开发调试的效率取决于能否快速：
- 运行应用
- 查看日志
- 热重载修改
- 排查问题

---

## 环境要求

### WSL 环境

```bash
# 进入 WSL
wsl -d dang

# 设置环境变量
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PATH=/home/mayn/flutter/bin:/usr/bin:/bin:/usr/local/bin:$PATH
```

### Windows 环境

确保：
- Android 手机已开启开发者模式
- USB 调试已开启
- 数据线连接电脑

---

## 运行应用

### 连接设备查看

```bash
# 查看已连接设备
flutter devices

# 期望输出示例：
# Chrome
# Windows
# Android SDK built for x86 (emulator)
# Mi 9 (device)
```

### 运行 Debug 版本

```bash
# 选择设备运行
flutter run -d <device-id>

# 示例
flutter run -d Mi 9

# 或者直接运行，会选择第一个可用设备
flutter run
```

### 运行 Release 版本

```bash
flutter run --release
```

---

## 热重载（Hot Reload）

### 使用场景

修改了 UI、样式、简单逻辑时使用，不需要重启应用。

### 快捷键

| 环境 | 快捷键 |
|-----|--------|
| VS Code | `Ctrl + S`（保存时自动） |
| Android Studio | `Ctrl + \` |
| 命令行 | `r` |

### 命令行热重载

```bash
# 在 flutter run 运行时按 r
# 或者
flutter hotreload
```

### 热重启（Hot Restart）

修改了状态管理、initState、Provider 等时使用，会重置状态。

```bash
# 在 flutter run 运行时按 R（大写）
# 或者
flutter hotrestart
```

---

## 日志查看

### flutter logs

```bash
# 查看 Android 日志
flutter logs

# 指定设备
flutter logs -d <device-id>
```

### adb logcat（更详细）

```bash
# 进入 adb
adb shell

# 查看 Flutter 日志
logcat -s flutter

# 查看所有日志
logcat

# 过滤某个 tag
logcat -s myapp

# 清除日志
logcat -c
```

### VS Code

安装 Flutter 扩展后，调试控制台会显示日志。

---

## Debug 模式的特点

| 特点 | 说明 |
|-----|------|
| 断言开启 | Debug 模式会检查断言 |
| 调试信息 | 有额外的调试信息 |
| 性能优化关闭 | 性能不如 Release |
| 热重载支持 | 支持 Hot Reload |

---

## Release 模式测试

### 为什么重要

- Debug 模式下有些问题不会暴露
- 性能问题只在 Release 下明显
- 某些行为 Debug 和 Release 不同

### 构建 Release

```bash
# WSL 内
cd /home/mayn/dang/android
./gradlew assembleRelease --no-daemon
```

### 安装 Release APK

```bash
# 通过 flutter 安装（需要设备连接）
flutter install

# 或者手动安装 APK
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## 常见问题排查

### 设备找不到

```bash
# 1. 检查设备
flutter devices

# 2. 重启 ADB
adb kill-server
adb start-server

# 3. 重新连接设备
```

### 应用崩溃

```bash
# 1. 查看日志
flutter logs

# 2. 用 adb 查看更详细的 crash 日志
adb logcat | grep -i crash
```

### 热重载不生效

```bash
# 1. 使用热重启
flutter hotrestart

# 2. 清理后重新运行
flutter clean
flutter pub get
flutter run
```

---

## 代码调试

### IDE 断点调试

VS Code 或 Android Studio 中：
1. 在代码行号左侧点击设置断点
2. `flutter run --debug`
3. 断点会触发，查看变量值

### print 调试

```dart
print('Debug: value = $value');

// 注意：生产代码删除 print
// 用 assert 或日志框架代替
```

### Debug Mode 专用代码

```dart
// 只在 Debug 模式运行
assert(() {
  print('Debug only: $debugInfo');
  return true;
}());
```

---

## 性能分析

### DevTools

```bash
flutter run --observatory
```

浏览器打开显示的 URL，查看：
- 性能 timeline
- 内存使用
- Widget 树

### APK 大小分析

```bash
flutter build apk --analyze-size
```

---

## 总结

| 操作 | 命令 |
|-----|------|
| 查看设备 | `flutter devices` |
| 运行 Debug | `flutter run` |
| 热重载 | `r` 或 Ctrl+S |
| 热重启 | `R` |
| 查看日志 | `flutter logs` |
| Release 构建 | `./gradlew assembleRelease` |

---

*开发时多使用热重载，发布前用 Release 测试。*
