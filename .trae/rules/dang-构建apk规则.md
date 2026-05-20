---
alwaysApply: false
description: 构建dang的APK文件时生效 - 环境配置和签名信息
---

# 构建 APK 规则（环境与签名）

## 概述

本文档定义 dang 项目的 WSL 构建环境和签名配置。

> **⚠️ 本文不包含构建命令！构建流程统一由 [BUILD.md](BUILD.md) 定义。**
>
> 本文档仅包含 **环境信息** 和 **签名配置**，是 BUILD.md 的补充文档。

---

## 环境要求

- **WSL 实例**: `dang`（Ubuntu 24.04 LTS，安装在 D 盘）
- **Flutter SDK**: `/home/mayn/flutter`（WSL 内）
- **Android SDK**: `/home/mayn/Android/Sdk`（WSL 内，Linux 版）
- **项目路径（WSL）**: `/home/mayn/dang`
- **项目路径（Windows）**: `d:\trae_projects\dang`

### WSL 环境变量

`.bashrc` 中配置：
```bash
source /home/mayn/env_setup.sh
```

`/home/mayn/env_setup.sh`：
```bash
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PATH=/home/mayn/flutter/bin:$PATH
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

### Android 配置

**android/local.properties（WSL 版本）**：
```properties
flutter.sdk=/home/mayn/flutter
sdk.dir=/home/mayn/Android/Sdk
flutter.buildMode=release
flutter.versionName=1.0.0
flutter.versionCode=1
```

**android/gradle.properties**：
```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
org.gradle.daemon=false
```

---

## 构建流程

> **实际构建命令、步骤、验证方法** → 详见 [BUILD.md](BUILD.md)
>
> **构建异常和错误排查** → 详见 [BUILD_TROUBLESHOOTING.md](BUILD_TROUBLESHOOTING.md)
>
> **构建红线（禁止事项）** → 详见 [BUILD_RED_LINES.md](BUILD_RED_LINES.md)

### 构建核心原则

1. ⚠️ **构建前必须同步代码**：`rsync -av --delete /mnt/d/trae_projects/dang/lib/ /home/mayn/dang/lib/`
2. ⚠️ **必须使用 WSL cp 复制 APK**（不能用 Windows copy）
3. ⚠️ **时间戳命名**：`changji_app_YYYYMMDD_HHMM.apk`
4. ⚠️ **APK 输出到**：`D:\trae_projects\dang\`

---

## APK 安装

```powershell
# 覆盖安装（保留数据）
adb install -r "d:\trae_projects\dang\changji_app_20260518_1430.apk"

# 查看已安装的包
adb shell pm list packages | findstr dang
```

> **注意**：上述命令中的时间戳需替换为实际文件名。

---

## 相关文档索引

| 文档 | 用途 |
|-----|------|
| [BUILD.md](BUILD.md) | 构建流程规范（唯一构建流程定义） |
| [BUILD_RED_LINES.md](BUILD_RED_LINES.md) | 构建红线（强制检查清单） |
| [BUILD_TROUBLESHOOTING.md](BUILD_TROUBLESHOOTING.md) | 构建异常案例集锦 |
| [RED_LINES.md](RED_LINES.md) | 安全红线 |
| [INTERACTION.md](INTERACTION.md) | 交互规则（构建阻断机制） |

---

## 更新记录

| 日期 | 更新内容 |
|-----|---------|
| 2026-05-12 | 初始版本 |
| 2026-05-19 | 方案C重构：改为引用模式，移除重复构建内容，保留环境配置和签名信息 |