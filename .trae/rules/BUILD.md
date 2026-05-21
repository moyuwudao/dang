---
alwaysApply: false
globs: android/**, ios/**, pubspec.yaml, build.gradle.kts
description: 构建流程规范 - APK 构建、测试构建、清理缓存
---

# BUILD.md - 构建流程规范

## 核心理念

构建是将代码变成可运行程序的过程。了解构建流程能帮助：
- 快速生成测试 APK
- 排查构建问题
- 在不同环境构建

---

## 🚀 推荐方案：WSL 一键构建

**使用 WSL 构建**，已验证可用，可直接生成 APK。

### ⚠️ 重要前提：代码必须同步

**本项目使用 WSL 环境构建，但代码编辑在 Windows 端完成。**

Windows 的 `D:\trae_projects\dang\` 和 WSL 的 `/home/mayn/dang/` 是两个独立的文件系统，**不会自动同步**。

**⚠️ 构建前必须先同步代码到 WSL，否则 APK 会包含旧代码！**

> **实际教训（2026-05-16）**：修复 Qwen ASR URL 后直接构建 APK，但安装后仍报错。原因是 WSL 中的代码是旧版本，构建使用的是旧代码。

### 方案优势
| 方面 | 说明 |
|-----|------|
| **环境已配置** | WSL 环境已完整配置 Flutter/Android SDK |
| **稳定性高** | 经过多次验证，构建成功率高 |
| **一键完成** | 一条命令完成构建和复制 |
| **无需额外安装** | 无需安装 Docker 或其他工具 |

### 标准构建流程（唯一流程）

> **本文件只定义一套构建流程。所有构建操作必须遵循此流程。**
> 详细红线见 [BUILD_RED_LINES.md](BUILD_RED_LINES.md)

```powershell
# 第1步：同步代码到 WSL（必须！）
wsl -d dang bash -c "rsync -av --delete /mnt/d/trae_projects/dang/lib/ /home/mayn/dang/lib/"

# 第2步：WSL 环境构建
wsl -d dang bash -c "export PUB_HOSTED_URL=https://pub.flutter-io.cn && export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn && export PATH=/home/mayn/flutter/bin:/usr/bin:/bin:/usr/local/bin:\$PATH && cd /home/mayn/dang && flutter clean && flutter build apk --release"

# 第3步：生成时间戳文件名并复制 APK 到 D:\trae_projects\dang
$timestamp = Get-Date -Format "yyyyMMdd_HHmm"
$apkName = "changji_app_${timestamp}.apk"
wsl -d dang bash -c "cp /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk /mnt/d/trae_projects/dang/${apkName}"

# 第4步：验证 APK
Get-Item D:\trae_projects\dang\${apkName} | Select-Object Name, LastWriteTime, Length

# 第5步：输出结果
Write-Host "APK 构建完成！"
Write-Host "版本：D:\trae_projects\dang\${apkName}"
```

### 核心规则

1. ✅ 构建前必须先同步代码到 WSL（`rsync`）
2. ✅ 必须使用 WSL `cp` 命令复制 APK，**禁止** Windows `copy`/`Copy-Item`
3. ✅ 时间戳命名：`changji_app_YYYYMMDD_HHMM.apk`
4. ✅ 构建前自动执行 `flutter clean`
5. ✅ 复制后必须验证 APK 修改时间

### 输出结果确认

```
✓ Built build/app/outputs/flutter-apk/app-release.apk (XX.XMB)
APK 构建完成！
版本：D:\trae_projects\dang\changji_app_20260516_1430.apk
```

### 📱 安装 APK

```powershell
# 覆盖安装（保留数据）
adb install -r "d:\trae_projects\dang\changji_app_20260518_1430.apk"

# 全新安装
adb install "d:\trae_projects\dang\changji_app_20260518_1430.apk"
```

> **注意**：上述命令中的 `20260518_1430` 需替换为实际的时间戳文件名。

---

## ⚠️ 构建关键注意事项

### 为什么必须同步代码到 WSL

**实际教训（2026-05-16）**：修复 Qwen ASR URL 后直接构建 APK，安装后仍报错。

**原因**：Windows 的 `D:\trae_projects\dang\` 和 WSL 的 `/home/mayn/dang/` 是两个独立的文件系统，**不会自动同步**。WSL 中的代码是旧版本。

**解决**：构建前必须执行 `rsync` 同步代码。

### 为什么必须使用 WSL cp 命令

**原因**：WSL 挂载到 Windows 的 `D:\trae_projects\dang\build\...` 有缓存延迟。Windows `copy` 命令读取的是缓存中的旧文件，时间戳不更新。

**解决**：使用 WSL 内部的 `cp` 命令，直接操作 WSL 内部的文件系统。

详见 [BUILD_TROUBLESHOOTING.md](BUILD_TROUBLESHOOTING.md) CASE-001

---

## ⚠️ 常见问题与解决方案

### 问题 1：WSL代码未同步（重要！）

**问题描述**：
修改代码后构建，但APK中没有包含最新修改。

**原因**：
WSL中的代码是之前同步的旧版本，没有自动同步Windows的最新修改。

**根本原因**：
本项目使用 **WSL 环境构建**，但代码编辑在 Windows 端完成。Windows 的 `D:\trae_projects\dang\` 和 WSL 的 `/home/mayn/dang/` 是两个独立的文件系统，**不会自动同步**。

**解决方案**：
构建前必须手动同步代码到WSL：

```powershell
# 同步代码到WSL（必须执行！）
wsl -d dang bash -c "rsync -av --delete /mnt/d/trae_projects/dang/lib/ /home/mayn/dang/lib/"
```

或者使用项目根目录的 `build_wsl.sh` 脚本（已包含同步逻辑）：

```powershell
# 使用构建脚本（自动同步+构建）
wsl -d dang bash /mnt/d/trae_projects/dang/build_wsl.sh
```

**验证同步成功**：
```powershell
# 检查WSL中的文件是否已更新
wsl -d dang bash -c "cd /home/mayn/dang && git diff --stat"
```

**⚠️ 实际案例**：
> 修改 `multi_api_config_screen.dart` 添加新功能选项后，直接构建 APK，安装后仍只显示3个选项而非4个。
> 
> **原因**：WSL 中的 `lib/` 目录仍是旧代码，构建使用的是旧代码。
> 
> **解决**：执行 `rsync` 同步 `lib/` 目录到 WSL 后重新构建，APK 正确显示4个选项。

### 问题 2：依赖下载慢

**解决方案**：
WSL 构建命令已内置国内镜像配置，无需额外设置。

### 问题 3：签名配置缺失

**错误信息**：
```
Cannot read keyAlias from key.properties
```

**解决方案**：
创建 `android/key.properties` 文件：
```properties
storePassword=your_password
keyPassword=your_password
keyAlias=changji
storeFile=../changji.jks
```

### 问题 4：编译错误

**错误信息**：
```
resource android:attr/lStar not found
```

**解决方案**：
确保所有模块的 `compileSdkVersion` 统一为 36。

---

## 📁 构建输出

| 路径 | 说明 |
|-----|------|
| `D:\trae_projects\dang\changji_app.apk` | 最终构建产物 |

---

## 🔄 清理构建缓存

```powershell
# 完整清理
wsl -d dang bash -c "cd /home/mayn/dang && flutter clean && rm -rf .dart_tool && flutter pub get"
```

---

## 📱 安装 APK

```powershell
# 覆盖安装（保留数据）
adb install -r "d:\trae_projects\dang\changji_app.apk"

# 全新安装
adb install "d:\trae_projects\dang\changji_app.apk"
```

---

## 📝 构建检查清单

在构建前确认：
- [ ] 项目路径无中文和特殊字符
- [ ] key.properties 已配置（仅 release 构建）
- [ ] **代码已同步到WSL**（重要！）

---

## 📋 完整构建流程

1. **保存代码**：确保所有修改已写入磁盘
2. **同步代码到WSL**：使用 `rsync` 或 `build_wsl.sh` 脚本（**关键步骤！**）
3. **验证同步**：检查 WSL 中的代码是否已更新
4. **运行构建命令**：复制粘贴一键构建命令到 PowerShell
5. **复制APK到Windows**：使用 `/mnt/d/` 路径（**关键步骤！**）
6. **测试安装**：使用 `adb install` 安装到设备

### ⚠️ 构建前检查清单

- [ ] 代码修改已保存到磁盘
- [ ] **代码已同步到 WSL**（`rsync` 命令已执行）
- [ ] **APK 复制使用 `/mnt/d/` 路径**（不是 WSL 内部路径）
- [ ] 验证 APK 修改时间已更新

---

## 🔧 构建脚本说明

项目根目录的 `build_wsl.sh` 脚本已配置完整的同步和构建流程：

1. 同步 `pubspec.yaml`
2. 同步 `lib/` 目录（核心代码）
3. 同步 `assets/` 目录（资源文件）
4. 同步 `android/` 目录（构建配置）
5. 执行 `flutter clean`
6. 执行 `flutter pub get`
7. 执行 `flutter build apk --release`
8. 复制APK到Windows目录

使用方式：
```powershell
wsl -d dang bash /mnt/d/trae_projects/dang/build_wsl.sh
```

---

## 🚀 代码更新后自动输出 APK（强制规则）

### 触发条件

当完成以下操作后，**必须**自动构建 APK：

| 操作类型 | 示例 |
|---------|------|
| 功能开发完成 | 新功能实现完毕 |
| Bug 修复完成 | 修复了某个问题 |
| UI 样式调整 | 修改了按钮颜色、布局等 |
| 配置文件变更 | 修改了 pubspec.yaml、build.gradle.kts 等 |
| 资源文件更新 | 添加/修改了图片、图标等 |

### 自动构建流程

代码更新完成后，按以下步骤自动输出 APK：

```
代码修改 → 保存 → 同步到WSL → 执行构建 → 复制APK
```

### 一键构建命令（代码更新后执行）

```powershell
# ⚠️ 第0步：验证代码已同步到 WSL（新增！）
# 构建前必须先同步，否则 APK 会包含旧代码！
wsl -d dang bash -c "rsync -av --delete /mnt/d/trae_projects/dang/lib/ /home/mayn/dang/lib/"

# 第1步：一键构建（在 WSL 内部完成）
wsl -d dang bash -c "export PUB_HOSTED_URL=https://pub.flutter-io.cn && export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn && export PATH=/home/mayn/flutter/bin:/usr/bin:/bin:/usr/local/bin:\$PATH && cd /home/mayn/dang && flutter clean && flutter build apk --release"

# 第2步：生成带时间戳的 APK 文件名（格式：changji_app_YYYYMMDD_HHMM.apk）
$timestamp = Get-Date -Format "yyyyMMdd_HHmm"
$apkName = "changji_app_${timestamp}.apk"

# 第3步：使用 WSL cp 命令复制 APK（禁止使用 Windows copy / Copy-Item）
wsl -d dang bash -c "cp /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk /mnt/d/trae_projects/dang/${apkName}"

# 第4步：验证 APK 时间戳已更新
Get-Item D:\trae_projects\dang\${apkName} | Select-Object Name, LastWriteTime, Length

# 第5步：输出构建结果
Write-Host "APK 构建完成！"
Write-Host "时间戳版本：D:\trae_projects\dang\${apkName}"
```

### 规则要求

1. ✅ **代码修改完成后，必须先同步代码到 WSL**（使用 `rsync` 命令）
2. ✅ 构建成功后，**必须使用 WSL `cp` 命令**复制 APK 到 Windows
3. ✅ **禁止**使用 Windows `copy` / `Copy-Item` 命令复制 APK
4. ✅ 确保使用 WSL 环境构建，**禁止**在本地构建
5. ✅ 构建前自动执行 `flutter clean` 确保完整重新编译
6. ✅ 复制后**必须**验证 APK 修改时间已更新

### ⚠️ 同步问题（必须重视）

**常见错误**：修改代码后直接构建，APK 包含旧代码

**原因**：Windows 和 WSL 是两个独立文件系统，不自动同步

**教训**：2026-05-16 修复 Qwen ASR URL 后直接构建，安装后仍报错，原因是 WSL 中是旧代码

### ⚠️ 重要提示

**更新完成后即可认为 APK 构建已完成，不需要额外考虑构建细节。**

- 代码更新保存后，构建流程会自动执行
- 不需要手动检查构建配置或环境
- 不需要处理构建过程中的警告或提示
- 构建命令已标准化，直接执行即可

### 输出结果确认

构建完成后应看到：
```
✓ Built build/app/outputs/flutter-apk/app-release.apk (XX.XMB)
APK 构建完成！
时间戳版本：D:\trae_projects\dang\changji_app_20260516_1430.apk
```

### ⚠️ APK 复制路径注意事项

**正确路径**（必须使用 WSL 内部命令复制）：
```powershell
# ✅ 使用 WSL cp 命令（确保复制的是 WSL 内部新生成的文件）
# 生成带时间戳的文件名
$timestamp = Get-Date -Format "yyyyMMdd_HHmm"
$apkName = "changji_app_${timestamp}.apk"

# 复制时间戳版本
wsl -d dang bash -c "cp /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk /mnt/d/trae_projects/dang/${apkName}"
```

**错误方式**（Windows 命令会复制旧文件）：
```powershell
# ❌ Windows copy / Copy-Item 会复制 WSL 挂载目录下的缓存文件，时间戳不更新
copy D:\trae_projects\dang\build\app\outputs\flutter-apk\app-release.apk D:\trae_projects\dang\changji_app.apk
Copy-Item D:\trae_projects\dang\build\app\outputs\flutter-apk\app-release.apk D:\trae_projects\dang\changji_app.apk -Force
```

**验证复制成功**（必须检查时间戳）：
```powershell
# 检查时间戳版本
Get-Item D:\trae_projects\dang\changji_app_*.apk | Select-Object Name, LastWriteTime, Length | Sort-Object LastWriteTime -Descending | Select-Object -First 1
# 预期：LastWriteTime 应该是当前时间，不是昨天或更早
```

---

## 🔧 构建异常处理

### 构建失败时

1. **查看错误日志**，找到关键错误信息
2. **查阅 [BUILD_TROUBLESHOOTING.md](BUILD_TROUBLESHOOTING.md)** 案例集锦
3. **按案例方案修复**
4. **重新构建验证**

### 常见异常案例（详见案例集锦）

| 案例编号 | 问题类型 | 关键错误信息 |
|---------|---------|------------|
| CASE-001 | APK 复制后不是最新 | 时间戳未更新 |
| CASE-002 | NDK 版本不匹配 | `requires Android NDK X` |
| CASE-003 | 资源文件缺失 | `error: resource xml/xxx not found` |
| CASE-004 | FlutterLifecycleAdapter 找不到 | `cannot find symbol class FlutterLifecycleAdapter` |
| CASE-005 | 类路径快照缺失 | `shrunk-classpath-snapshot.bin (No such file or directory)` |
| CASE-008 | WSL 代理警告导致命令退出 | `wsl: 检测到 localhost 代理配置` |

### 发现新案例时

1. 按格式添加到 [BUILD_TROUBLESHOOTING.md](BUILD_TROUBLESHOOTING.md)
2. 包含：问题现象、根本原因、解决方案、验证方法
3. 更新案例索引表

---

## �📊 构建输出规范

### APK 文件命名与路径

**标准输出路径**：`D:\trae_projects\dang`

| 文件 | 完整路径 | 用途 |
|-----|---------|------|
| `app-release.apk` | `build/app/outputs/flutter-apk/` | 原始构建产物（WSL 内部） |
| `changji_app_YYYYMMDD_HHMM.apk` | `D:\trae_projects\dang\` | 带时间戳的版本，用于交付和测试 |

**时间戳格式**：`changji_app_20260516_1430.apk`
- `20260516` - 年月日
- `1430` - 时分

**优势**：
- 避免交付错误版本（通过时间戳区分）
- 保留历史版本（可追溯）
- 唯一文件名，防止覆盖

### 版本标识

构建的 APK 应包含版本信息：
- 版本号：`pubspec.yaml` 中的 `version` 字段
- 构建类型：`release`

### 构建日志

构建过程中应保留完整日志，便于排查问题：
- 依赖下载日志
- 编译警告/错误
- 构建耗时
- 输出文件大小
