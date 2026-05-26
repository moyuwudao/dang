---
name: "build-troubleshoot"
description: "Diagnose and fix Flutter APK build failures using case-based troubleshooting. Invoke when build fails, user reports build error, or mentions 构建失败、打包出错、NDK error、APK not found."
---

# Build Troubleshoot SKILL

## 触发条件

用户提到以下关键词时触发：
- 构建失败 / 打包出错 / 编译错误
- build failed / compile error / APK not found
- NDK 版本不匹配 / 资源文件缺失

## 执行方式

**本 SKILL 不包含排查步骤。排查时直接读取并执行 [BUILD_TROUBLESHOOTING.md](../rules/BUILD_TROUBLESHOOTING.md)。**

BUILD_TROUBLESHOOTING.md 是唯一排查规则源，包含所有案例的诊断流程和解决方案。

## 参考文档

- [BUILD_TROUBLESHOOTING.md](../rules/BUILD_TROUBLESHOOTING.md) - 完整案例集锦
- [BUILD.md](../rules/BUILD.md) - 构建流程
