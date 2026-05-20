---
alwaysApply: false
description: APK 构建异常案例集锦 - 收集所有构建问题及解决方案
---

# BUILD_TROUBLESHOOTING.md - APK 构建异常案例集锦

## 核心理念

这份文档收集所有 APK 构建过程中遇到的异常案例及解决方案。
**目标**：避免反复更新 BUILD.md，集中管理异常案例。

**使用方式**：
1. 构建失败时，先查看本文档是否有匹配案例
2. 如果有，按文档方案修复
3. 如果没有，修复后补充到本文档

> **API 相关异常** → 详见 [API_TROUBLESHOOTING.md](API_TROUBLESHOOTING.md)
>
> **构建流程规范** → 详见 [BUILD.md](BUILD.md)
>
> **构建红线** → 详见 [BUILD_RED_LINES.md](BUILD_RED_LINES.md)

---

## 📋 案例索引

| 编号 | 问题类型 | 关键错误信息 | 状态 |
|-----|---------|------------|------|
| CASE-001 | APK 复制后不是最新 | 时间戳未更新 | ✅ 已解决 |
| CASE-002 | NDK 版本不匹配 | `requires Android NDK X` | ✅ 已解决 |
| CASE-003 | 资源文件缺失 | `error: resource xml/xxx not found` | ✅ 已解决 |
| CASE-004 | FlutterLifecycleAdapter 找不到 | `cannot find symbol class FlutterLifecycleAdapter` | ✅ 已解决 |
| CASE-005 | 类路径快照缺失 | `shrunk-classpath-snapshot.bin (No such file or directory)` | ✅ 已解决 |
| CASE-007 | 代码未同步到 WSL | APK 包含旧代码 | ✅ 已解决 |

---

## 🔴 CASE-001: APK 复制后不是最新版本

### 问题现象
- 构建日志显示 `✓ Built build/app/outputs/flutter-apk/app-release.apk`
- 但复制后的 APK 时间戳仍是旧的
- 安装后代码没有更新

### 根本原因
Windows 和 WSL 是两个独立的文件系统：
- `flutter build` 在 WSL 内部执行，写入 `/home/mayn/dang/build/...`
- Windows 看到的 `D:\trae_projects\dang\build\...` 是 WSL 的挂载视图，有缓存延迟
- Windows `copy` 命令读取的是缓存中的旧文件

### 解决方案
**必须使用 WSL 内部 `cp` 命令复制，且生成时间戳版本**：
```powershell
# ✅ 正确：使用 WSL cp 命令，生成时间戳版本
$timestamp = Get-Date -Format "yyyyMMdd_HHmm"
$apkName = "changji_app_${timestamp}.apk"
wsl -d dang bash -c "cp /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk /mnt/d/trae_projects/dang/${apkName}"

# ❌ 错误：Windows copy 会复制旧文件
copy D:\trae_projects\dang\build\app\outputs\flutter-apk\app-release.apk D:\trae_projects\dang\changji_app.apk
```

### 验证方法
```powershell
Get-Item D:\trae_projects\dang\changji_app_*.apk | Select-Object Name, LastWriteTime, Length | Sort-Object LastWriteTime -Descending | Select-Object -First 1
```

---

## 🔴 CASE-002: NDK 版本不匹配

### 问题现象
```
Your project is configured with Android NDK 25.2.9519653, but the following plugin(s) depend on a different Android NDK version:
- add_2_calendar requires Android NDK 27.0.12077973
- audio_session requires Android NDK 27.0.12077973
...
Fix this issue by using the highest Android NDK version (they are backward compatible).
```

### 解决方案
更新 `android/app/build.gradle.kts` 中的 `ndkVersion`：
```kotlin
android {
    ndkVersion = "28.2.13676358"
}
```

---

## 🔴 CASE-003: 资源文件缺失

### 问题现象
```
ERROR: AAPT: error: resource xml/flutter_share_file_paths (aka com.changji.changji_app:xml/flutter_share_file_paths) not found.
```

### 解决方案
创建缺失的资源文件 `android/app/src/main/res/xml/flutter_share_file_paths.xml`：
```xml
<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <cache-path name="cache" path="." />
    <external-path name="external" path="." />
    <external-files-path name="external_files" path="." />
    <files-path name="files" path="." />
</paths>
```

---

## 🔴 CASE-004: FlutterLifecycleAdapter 找不到

### 问题现象
```
error: cannot find symbol
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter;
^
symbol:   class FlutterLifecycleAdapter
```

### 解决方案
确保 `image_picker_android` 依赖版本与 Flutter SDK 版本兼容。
通常执行 `flutter clean` 后重新构建即可解决。

---

## 🔴 CASE-005: 类路径快照缺失

### 问题现象
```
java.io.FileNotFoundException: /home/mayn/dang/build/shared_preferences_android/kotlin/compileReleaseKotlin/classpath-snapshot/shrunk-classpath-snapshot.bin (No such file or directory)
```

### 解决方案
执行 `flutter clean` 清理构建缓存，然后重新构建：
```bash
flutter clean
flutter pub get
flutter build apk --release
```

---

## 🔴 CASE-007: 代码未同步到 WSL，APK 包含旧代码

### 问题现象
- 修改了代码后构建 APK
- 安装后发现修改没有生效
- 日志显示仍使用旧的 URL 或旧的逻辑

### 实际案例（2026-05-16）
修复 Qwen ASR URL 后构建 APK，但安装后仍报 `url error`：
```
[23:45:50] Qwen ASR: URL=https://dashscope.aliyuncs.com/api/v1/services/audio/asr/transcription
[23:45:50] Qwen ASR ERROR: url error, please check url！
```

### 根本原因
**WSL 中的代码没有同步更新**：
- 代码编辑在 Windows 端完成（`D:\trae_projects\dang\`）
- 构建在 WSL 中执行（`/home/mayn/dang/`）
- 这两个目录是**独立的文件系统**，不会自动同步
- 直接构建时，WSL 中仍是旧代码

### 解决方案
**构建前必须先同步代码到 WSL**：

```powershell
# ✅ 正确流程：
# 1. 代码修改（Windows）
# 2. 同步到 WSL
wsl -d dang bash -c "rsync -av --delete /mnt/d/trae_projects/dang/lib/ /home/mayn/dang/lib/"
# 3. 构建 APK（详见 BUILD.md）
# 4. 复制和验证 APK
```

详见 [BUILD.md](BUILD.md) 完整构建流程。

### 验证方法
```powershell
# 检查 WSL 中的文件是否已更新
wsl -d dang bash -c "cd /home/mayn/dang && git diff --stat"
```

---

## 📖 使用指南

### 构建失败时

1. **查看错误日志**，找到关键错误信息
2. **对照案例索引**，查找匹配的案例编号
3. **按案例方案修复**
4. **重新构建验证**

### 发现新案例时

1. 按格式添加新案例（编号递增）
2. 包含：问题现象、根本原因、解决方案、验证方法
3. 更新案例索引表

### 案例格式模板

```markdown
## 🔴 CASE-XXX: 问题标题

### 问题现象
- 具体表现1
- 具体表现2

### 根本原因
简要说明原因

### 解决方案
具体的修复步骤

### 验证方法
如何确认已修复
```

---

## 更新记录

| 日期 | 更新内容 |
|-----|---------|
| 2026-05-12 | 初始版本，包含所有案例 |
| 2026-05-19 | 方案C重构：API 案例拆分到 API_TROUBLESHOOTING.md，保留纯构建案例 |