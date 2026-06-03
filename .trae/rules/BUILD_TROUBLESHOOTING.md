---
alwaysApply: false
globs: android/**, ios/**, pubspec.yaml
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
> **构建规则** → 详见 [BUILD.md](BUILD.md)

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
| CASE-008 | WSL 代理警告导致命令退出 | `wsl: 检测到 localhost 代理配置` | ✅ 已解决 |
| CASE-009 | 同步后 key.properties 丢失 | `Keystore was tampered with, or password was incorrect` | ✅ 已解决 |
| CASE-010 | rsync --delete 误删目标端独有文件 | key.properties / .env 等被删除 | ✅ 已解决 |
| CASE-011 | 引用未定义变量（编译期不报错）| `The argument type 'String' can't be assigned to the parameter type 'bool'` | ✅ 已解决 |

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
执行 `flutter clean` 清理构建缓存，然后重新构建（pub get 设 120 秒超时，build 设 20 分钟超时）：
```bash
flutter clean
timeout 120 flutter pub get
timeout 1200 flutter build apk --release
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
# 2. 同步到 WSL（rsync 设 60 秒超时）
wsl -d dang bash -c "rsync -av --timeout=60 --delete /mnt/d/trae_projects/dang/lib/ /home/mayn/dang/lib/"
# 3. 构建 APK（详见 BUILD.md）
# 4. 复制和验证 APK
```

详见 [BUILD.md](BUILD.md) 完整构建流程。

### 验证方法
```powershell
# 检查 WSL 中的文件是否已更新（设 30 秒超时）
wsl -d dang bash -c "cd /home/mayn/dang && timeout 30 git diff --stat"
```

---

## � CASE-008: WSL 代理警告导致命令提前退出

### 问题现象
- 执行 WSL 命令后，终端立即返回，没有预期输出
- 只看到警告信息：`wsl: 检测到 localhost 代理配置，但未镜像到 WSL。NAT 模式下的 WSL 不支持 localhost 代理。`
- 命令返回码为 0，但实际操作未执行（如 `flutter analyze` 没有运行）
- 反复执行相同命令，结果一样

### 实际案例（2026-05-21）
尝试运行 `flutter analyze` 验证代码修改：
```powershell
wsl -d dang bash -c 'export PATH="/home/mayn/flutter/bin:$PATH" && cd /home/mayn/dang && flutter analyze lib/core/models/ai_model_config.dart'
```
输出只有代理警告，没有 analyze 结果。多次重试均如此。

### 根本原因
WSL 检测到 Windows 配置了 localhost 代理，但 NAT 模式下无法镜像该代理。这个警告导致 bash 命令在 WSL 初始化阶段异常退出，`flutter analyze` 实际未执行。

**注意**：这与命令执行时间无关，不是"卡住"，而是命令根本没运行。

### 解决方案

**方案 A：使用异步模式执行（推荐用于耗时命令）**
```powershell
# 对于 flutter build、flutter analyze 等耗时命令，使用非阻塞模式
wsl -d dang bash -c '...flutter build apk --release...'
# 然后使用 CheckCommandStatus 轮询检查进度
```

**方案 B：直接验证构建结果**
```powershell
# 如果 analyze 无法运行，直接运行 flutter build（20 分钟超时）
# 构建成功 = 代码无编译错误
wsl -d dang bash -c 'export PATH="/home/mayn/flutter/bin:$PATH" && cd /home/mayn/dang && timeout 1200 flutter build apk --release'
```

**方案 C：检查 WSL 代理配置**
```powershell
# 在 WSL 内部禁用代理警告（可选）
wsl -d dang bash -c 'echo "[wsl2]" > /etc/wsl.conf'
```

### 验证方法
```powershell
# 正确执行后应看到实际输出，而非仅代理警告
# 例如 flutter build 应看到：
# ✓ Built build/app/outputs/flutter-apk/app-release.apk (XX.XMB)
```

---

## 🔴 CASE-009: 同步后 key.properties 丢失

### 问题现象
- Flutter 构建时报错：
  ```
  Keystore file '/home/mayn/dang/android/key.properties' not found for signing config 'release'.
  ```
  或
  ```
  Keystore was tampered with, or password was incorrect
  ```
- 但 Windows 端没动过 `key.properties`

### 实际案例（2026-06-03）
从 Windows 同步代码到 WSL 后构建，提示 `Keystore was tampered with, or password was incorrect`。检查发现 WSL 端 `/home/mayn/dang/android/key.properties` 文件被删除。

### 根本原因
**`rsync --delete` 同步 `android/` 目录时，会删除目标端独有的文件**：
- Windows 端 `D:\trae_projects\dang\android\` 中**没有** `key.properties`（因为它不进入 git）
- WSL 端 `/home/mayn/dang/android/key.properties` 是手动放的（按规则不入 git）
- 同步命令：
  ```bash
  rsync -av --delete /mnt/d/trae_projects/dang/android/ /home/mayn/dang/android/
  ```
  `--delete` 会删除 WSL 端所有 Windows 端没有的文件，包括 `key.properties`

### 解决方案
**方案 A（推荐）：同步 `android/` 时不用 `--delete`，并加 `--exclude`**：
```bash
rsync -av \
  --exclude='build/' \
  --exclude='.gradle/' \
  --exclude='.idea/' \
  --exclude='key.properties' \
  /mnt/d/trae_projects/dang/android/ /home/mayn/dang/android/
```

**方案 B：用 `--delete` 时**先备份关键文件**：
```bash
cp /home/mayn/dang/android/key.properties /tmp/key.properties.bak
rsync -av --delete /mnt/d/trae_projects/dang/android/ /home/mayn/dang/android/
[ -f /home/mayn/dang/android/key.properties ] || cp /tmp/key.properties.bak /home/mayn/dang/android/key.properties
```

**方案 C：被删后恢复**（按 [dang-构建apk规则](dang-构建apk规则.md#android-签名配置)）：
```bash
# 在 WSL 端重新创建
cat > /home/mayn/dang/android/key.properties << 'EOF'
storePassword=123456
keyPassword=123456
keyAlias=changji
storeFile=/home/mayn/.android/signing/changji.jks
EOF
chmod 600 /home/mayn/dang/android/key.properties
```

### 验证方法
```bash
# 构建前先验证 key.properties 存在
[ -f /home/mayn/dang/android/key.properties ] && echo "OK" || echo "MISSING"

# 检查密钥库文件
ls -la /home/mayn/.android/signing/changji.jks
```

### 预防清单
- [ ] 同步 `android/` 时**禁用 `--delete`** 或
- [ ] 用 `--exclude='key.properties'` 排除
- [ ] 构建前检查 `[ -f /home/mayn/dang/android/key.properties ]`
- [ ] 备份 `key.properties` 到 `~/.android/` 或 `tmp/`

---

## 🔴 CASE-010: rsync --delete 误删目标端独有文件

### 问题现象
- 同步代码后，目标端**独有**的文件被删除
- 这些文件通常不入 git（如 `.env`、`key.properties`、`*.local`、`*.bak` 等）
- 构建或运行时找不到关键文件

### 实际案例（2026-06-03）
同步 `server/` 目录时也用 `--delete`，导致：
- 服务器 `/home/admin/dang/server/.env`（应存在）被删（虽然这次是反向问题）
- WSL 端 `/home/mayn/dang/android/key.properties` 被删

### 根本原因
`--delete` 行为：
> "delete extraneous files from destination directories"

任何目标端存在、源端不存在的文件都会被删除。**`--delete` 是双向破坏**：
- 同步 Windows → WSL：删 WSL 端独有的（如 `key.properties`、`.env`）
- 同步 WSL → 服务器：删服务器端独有的（如 `.env`、日志、配置）

### 解决方案

**铁律：谨慎使用 `--delete`，必须配合 `--exclude`**

**标准 rsync 命令模板**（带 exclude 列表）：
```bash
# 同步 lib/（不需要 --delete，因为完全替换）
rsync -av /mnt/d/trae_projects/dang/lib/ /home/mayn/dang/lib/

# 同步 android/（需要 --delete 清理 build/.gradle/，但要保护 key.properties）
rsync -av --delete \
  --exclude='build/' \
  --exclude='.gradle/' \
  --exclude='.idea/' \
  --exclude='key.properties' \
  /mnt/d/trae_projects/dang/android/ /home/mayn/dang/android/

# 同步 server/（需要 --delete 清理 dist/，但要保护 .env）
rsync -av --delete \
  --exclude='node_modules/' \
  --exclude='dist/' \
  --exclude='.env' \
  --exclude='*.log' \
  /mnt/d/trae_projects/dang/server/ /home/mayn/dang/server/
```

### 关键 exclude 项

| 目录 | 必须 exclude | 原因 |
|------|------------|------|
| `android/` | `key.properties` | 签名密钥，**绝对不能删** |
| `android/` | `build/` `.gradle/` | 构建产物，下次构建会重新生成 |
| `server/` | `.env` | 环境变量配置（不入 git）|
| `server/` | `node_modules/` | 依赖（下次 install 重新生成）|
| `server/` | `*.log` | 日志文件 |
| 任何目录 | `.local` `*.bak` `*.swp` | 临时/本地文件 |

### 验证方法
```bash
# 同步后立即验证关键文件
[ -f /home/mayn/dang/android/key.properties ] || echo "❌ key.properties 丢失"
[ -f /home/admin/dang/server/.env ] || echo "❌ .env 丢失"
```

### 预防
- ❌ **禁止**用裸 `rsync -av --delete /src/ /dst/`（无 exclude）
- ✅ **必须**配合 `--exclude='关键文件'`
- ✅ **必须**先备份再操作
- ✅ 同步后立即验证关键文件

---

## 🔴 CASE-011: 引用未定义变量（编译期不报错）

### 问题现象
- Flutter 构建时报编译错误：
  ```
  Error: The argument type 'String' can't be assigned to the parameter type 'bool'.
  ```
  或
  ```
  The function 'xxx' is not defined
  ```
- 但该变量在**当前类**中确实不存在
- 错误指向的函数签名有误，参数类型不匹配

### 实际案例（2026-06-03）
修改 `recording_screen.dart` 的实时转写 UI 优化时，新加的 `_buildRealtimeTranscriptView(realtimeText, isRecording)` 调用时传了 `isRecording`（字符串），导致：
```
Error: The argument type 'String' can't be assigned to the parameter type 'bool'.
```

实际本意是 `state.isRecording`（bool），漏写了 `state.` 前缀。

### 根本原因
- **Dart 词法作用域**：`isRecording` 这种短名在 widget 内部可能因为属性提升（extension / mixin）而指向其他类型
- 在 `_showRealtimeTranscriptionSheet` 函数里，`state` 是参数，但调用时漏写 `state.` 前缀
- 编译期错误信息不够直观（`isRecording` 实际是 String 类型而非 bool）

### 解决方案
**修复时按错误位置定位，再读上下文确认变量来源**：
```dart
// 错误调用
_buildRealtimeTranscriptView(realtimeText, isRecording)  // 传了 String

// 正确调用
_buildRealtimeTranscriptView(realtimeText, state.isRecording)  // 传了 bool
```

### 预防
- ✅ 修复杂构造函数调用时，**先读函数签名**确认参数类型
- ✅ IDE 警告优先（红线、高亮）— 不要忽略
- ✅ `flutter analyze` 能在编译前发现大部分此类问题
- ❌ 不要"凭感觉"猜变量名

### 验证方法
```bash
# 编译前先 analyze
wsl -d dang bash -c 'export PATH=/home/mayn/flutter/bin:$PATH && cd /home/mayn/dang && timeout 120 flutter analyze lib/'
# 期望：No issues found!
```

---

## � 使用指南

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
| 2026-06-03 | **新增 3 个案例**（基于 2026-06-03 修复过程沉淀）：CASE-009 同步后 key.properties 丢失；CASE-010 rsync --delete 误删目标端独有文件（含铁律+exclude 模板+多目录 exclude 表）；CASE-011 引用未定义变量编译错误。完整 11 个案例覆盖：APK 时间戳 / NDK / 资源文件 / 依赖兼容 / 缓存缺失 / 代码同步 / WSL 代理 / 签名密钥 / rsync 风险 / 变量引用 |
| 2026-05-25 | 安全修复：flutter build 加 timeout 1200；pub get 加 timeout 120；rsync 加 --timeout=60；git diff 加 timeout 30 |
| 2026-05-12 | 初始版本，包含所有案例 |
| 2026-05-19 | 方案C重构：API 案例拆分到 API_TROUBLESHOOTING.md，保留纯构建案例 |
| 2026-05-21 | 新增 CASE-008：WSL 代理警告导致命令提前退出 |