---
name: "build-apk"
description: "Build Flutter APK in WSL environment with code sync, timestamp naming, and verification. Invoke when user asks to build APK, generate APK, compile release build, or mentions 构建、打包、输出APK."
---

# Build APK SKILL

## 触发条件

用户提到以下关键词时触发：
- 构建 APK / 打包 / 编译 release
- build APK / generate APK / compile release
- 输出 APK / 生成安装包

## 执行方式

**本 SKILL 不包含构建命令。构建时直接读取并执行 [BUILD.md](../rules/BUILD.md)。**

BUILD.md 是唯一构建规则源，包含：
- 🔴 构建强制检查清单
- ✅ 强制流程（rsync → build → cp → 验证）
- 📦 一键构建命令
- 🚀 构建触发规则（自动/询问）
- 🛡 构建阻断机制
- 📁 APK 输出路径规范

## 参考文档

- [BUILD.md](../rules/BUILD.md) - 完整构建流程（唯一构建规则源）
- [BUILD_TROUBLESHOOTING.md](../rules/BUILD_TROUBLESHOOTING.md) - 构建问题排查
