---
alwaysApply: false
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

### ⚠️ 重要前提：代码同步

**本项目使用 WSL 环境构建，但代码编辑在 Windows 端完成。**

Windows 的 `D:\trae_projects\dang\` 和 WSL 的 `/home/mayn/dang/` 是两个独立的文件系统，**不会自动同步**。

**构建前必须先同步代码到 WSL！**

### 方案优势
| 方面 | 说明 |
|-----|------|
| **环境已配置** | WSL 环境已完整配置 Flutter/Android SDK |
| **稳定性高** | 经过多次验证，构建成功率高 |
| **一键完成** | 一条命令完成构建和复制 |
| **无需额外安装** | 无需安装 Docker 或其他工具 |

### 完整构建流程（含同步）

```powershell
# 第1步：同步代码到 WSL（必须！）
wsl -d dang bash -c "rsync -av --delete /mnt/d/trae_projects/dang/lib/ /home/mayn/dang/lib/"

# 第2步：构建 APK
wsl -d dang bash -c "export PUB_HOSTED_URL=https://pub.flutter-io.cn && export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn && export PATH=/home/mayn/flutter/bin:/usr/bin:/bin:/usr/local/bin:\$PATH && cd /home/mayn/dang && flutter clean && flutter pub get && flutter build apk --release"

# 第3步：复制 APK 到 Windows
wsl -d dang bash -c "cp /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk /mnt/d/trae_projects/dang/changji_app.apk"
```

### 一键构建命令（简化版）

如果确定代码已在 WSL 中：

```powershell
wsl -d dang bash -c "export PUB_HOSTED_URL=https://pub.flutter-io.cn && export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn && export PATH=/home/mayn/flutter/bin:/usr/bin:/bin:/usr/local/bin:\$PATH && cd /home/mayn/dang && flutter clean && flutter pub get && flutter build apk --release && cp /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk /mnt/d/trae_projects/dang/changji_app.apk"
```

### ⚠️ APK 复制必须使用 WSL 内部命令

**错误方式**（Windows `copy` 命令会复制 WSL 挂载目录下的旧文件，时间戳不更新）：
```powershell
# ❌ 不要这样复制
Copy-Item D:\trae_projects\dang\build\app\outputs\flutter-apk\app-release.apk D:\trae_projects\dang\changji_app.apk -Force
```

**正确方式**（使用 WSL `cp` 命令，确保复制的是 WSL 内部新生成的文件）：
```powershell
# ✅ 使用 WSL cp 命令
wsl -d dang bash -c "cp /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk /mnt/d/trae_projects/dang/changji_app.apk"
```

### 构建输出

| 路径 | 说明 |
|-----|------|
| `D:\trae_projects\dang\changji_app.apk` | 最终构建产物 |
| 大小 | ~98.5 MB |

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
# 第1步：一键构建（在 WSL 内部完成）
wsl -d dang bash -c "export PUB_HOSTED_URL=https://pub.flutter-io.cn && export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn && export PATH=/home/mayn/flutter/bin:/usr/bin:/bin:/usr/local/bin:\$PATH && cd /home/mayn/dang && flutter clean && flutter build apk --release"

# 第2步：使用 WSL cp 命令复制 APK（禁止使用 Windows copy / Copy-Item）
wsl -d dang bash -c "cp /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk /mnt/d/trae_projects/dang/changji_app.apk"

# 第3步：验证 APK 时间戳已更新
Get-Item D:\trae_projects\dang\changji_app.apk | Select-Object Name, LastWriteTime, Length

# 第4步：输出构建结果
Write-Host "APK 构建完成！"
Write-Host "输出路径：D:\trae_projects\dang\changji_app.apk"
```

### 规则要求

1. ✅ 代码修改完成后，**必须**先同步代码到 WSL，再执行构建
2. ✅ 构建成功后，**必须**使用 **WSL `cp` 命令**复制 APK 到 Windows（`cp /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk /mnt/d/trae_projects/dang/changji_app.apk`）
3. ✅ **禁止**使用 Windows `copy` / `Copy-Item` 命令复制 APK（会复制 WSL 挂载目录下的旧缓存文件）
4. ✅ 确保使用 WSL 环境构建，**禁止**在本地构建
5. ✅ 构建前自动执行 `flutter clean` 确保完整重新编译
6. ✅ 复制后**必须**验证 APK 修改时间已更新（`Get-Item` 检查 `LastWriteTime`）

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
输出路径：D:\trae_projects\dang\changji_app.apk
```

### ⚠️ APK 复制路径注意事项

**正确路径**（必须使用 WSL 内部命令复制）：
```powershell
# ✅ 使用 WSL cp 命令（确保复制的是 WSL 内部新生成的文件）
wsl -d dang bash -c "cp /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk /mnt/d/trae_projects/dang/changji_app.apk"
```

**错误方式**（Windows 命令会复制旧文件）：
```powershell
# ❌ Windows copy / Copy-Item 会复制 WSL 挂载目录下的缓存文件，时间戳不更新
copy D:\trae_projects\dang\build\app\outputs\flutter-apk\app-release.apk D:\trae_projects\dang\changji_app.apk
Copy-Item D:\trae_projects\dang\build\app\outputs\flutter-apk\app-release.apk D:\trae_projects\dang\changji_app.apk -Force
```

**错误路径**（Windows 无法访问）：
```bash
# ❌ WSL 内部路径，Windows 无法直接访问
/home/mayn/dang/changji_app.apk
```

**验证复制成功**（必须检查时间戳）：
```powershell
# 检查文件修改时间和大小
Get-Item D:\trae_projects\dang\changji_app.apk | Select-Object Name, LastWriteTime, Length
# 预期：LastWriteTime 应该是当前时间，不是昨天或更早
```

---

## � APK 复制防错指南（必读）

### 问题现象
多次出现"复制的 APK 不是最新版本"的问题：
- 构建日志显示 `✓ Built build/app/outputs/flutter-apk/app-release.apk`
- 但复制后的 `changji_app.apk` 时间戳仍是旧的（如昨天或更早）
- 安装后代码没有更新

### 根本原因

Windows 和 WSL 是**两个独立的文件系统**：

```
Windows 路径：D:\trae_projects\dang\build\app\outputs\flutter-apk\app-release.apk
                    ↑ 这是 WSL 挂载到 Windows 的"视图"，有缓存延迟！

WSL 内部路径：/home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk
                    ↑ 这是真正的构建产物，实时更新
```

**关键点**：
- `flutter build` 在 WSL 内部执行，写入 `/home/mayn/dang/build/...`
- Windows 看到的 `D:\trae_projects\dang\build\...` 是 WSL 的**挂载视图**
- 这个视图有**缓存延迟**，Windows `copy` 命令读取的是缓存中的旧文件
- 即使文件大小变了，内容可能还是旧的

### 正确复制流程（强制遵循）

```powershell
# 第1步：构建 APK（在 WSL 内部执行）
wsl -d dang bash -c "export PUB_HOSTED_URL=https://pub.flutter-io.cn && export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn && export PATH=/home/mayn/flutter/bin:/usr/bin:/bin:/usr/local/bin:\$PATH && cd /home/mayn/dang && flutter clean && flutter build apk --release"

# 第2步：在 WSL 内部验证 APK 是最新的
wsl -d dang bash -c "ls -la /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk"
# 预期输出：时间应该是刚刚（如 May 13 15:17）

# 第3步：使用 WSL cp 命令复制（从 WSL 内部路径到 Windows 路径）
wsl -d dang bash -c "cp /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk /mnt/d/trae_projects/dang/changji_app.apk"
# 注意：源路径是 WSL 内部路径 /home/mayn/...，目标路径是 /mnt/d/...（Windows D盘）

# 第4步：在 Windows 验证复制成功
Get-Item D:\trae_projects\dang\changji_app.apk | Select-Object Name, LastWriteTime, Length
# 预期：LastWriteTime 应该是当前时间
```

### 一键构建+复制命令（推荐）

```powershell
wsl -d dang bash -c "export PUB_HOSTED_URL=https://pub.flutter-io.cn && export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn && export PATH=/home/mayn/flutter/bin:/usr/bin:/bin:/usr/local/bin:\$PATH && cd /home/mayn/dang && flutter clean && flutter build apk --release && echo 'Build time:' && ls -la build/app/outputs/flutter-apk/app-release.apk && cp build/app/outputs/flutter-apk/app-release.apk /mnt/d/trae_projects/dang/changji_app.apk && echo 'Copy done' && ls -la /mnt/d/trae_projects/dang/changji_app.apk"
```

### 防错检查清单

复制 APK 前必须确认：
- [ ] 构建命令在 WSL 内部执行（`wsl -d dang bash -c "..."`）
- [ ] 构建日志显示 `✓ Built build/app/outputs/flutter-apk/app-release.apk`
- [ ] 使用 `ls -la /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk` 验证 WSL 内部文件时间是最新的
- [ ] 复制命令使用 WSL `cp`（源路径是 `/home/mayn/...`，不是 `D:\...`）
- [ ] 复制后使用 `Get-Item` 验证 Windows 文件时间已更新
- [ ] 如果 Windows 文件时间仍是旧的，**删除后重新复制**

### 如果还是复制了旧版本

```powershell
# 强制删除旧文件
Remove-Item D:\trae_projects\dang\changji_app.apk -Force

# 重新从 WSL 复制
wsl -d dang bash -c "cp /home/mayn/dang/build/app/outputs/flutter-apk/app-release.apk /mnt/d/trae_projects/dang/changji_app.apk"

# 再次验证
Get-Item D:\trae_projects\dang\changji_app.apk | Select-Object Name, LastWriteTime, Length
```

---

## �📊 构建输出规范

### APK 文件命名

| 文件 | 路径 | 用途 |
|-----|------|-----|
| `app-release.apk` | `build/app/outputs/flutter-apk/` | 原始构建产物 |
| `changji_app.apk` | 项目根目录 | 工作副本，用于测试安装 |

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
