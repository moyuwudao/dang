---
alwaysApply: true
description: 构建红线规则 - 构建前必须遵守的强制要求
---

# BUILD_RED_LINES.md - 构建红线

## 核心理念

构建红线是**绝对不能违反**的构建规则。
违反这些规则会导致：构建失败、APK 错误、交付问题。

---

## 🔴 构建前强制检查

### 必须完成（缺一不可）

| 检查项 | 说明 | 验证方式 |
|-------|------|---------|
| 1. 阅读 BUILD.md | 非 alwaysApply 规则，必须主动读取 | 确认已了解构建流程 |
| 2. 同步代码到 WSL | Windows 和 WSL 文件系统不自动同步 | 执行 rsync 命令 |
| 3. WSL 环境构建 | 必须在 WSL `dang` 实例中构建 | 使用 wsl -d dang 命令 |
| 4. WSL cp 复制 | 必须使用 WSL cp 命令复制 APK | 禁止使用 Windows copy |
| 5. 时间戳命名 | 必须生成 changji_app_YYYYMMDD_HHMM.apk | 验证文件名 |
| 6. 验证 APK | 必须检查文件修改时间 | Get-Item 验证 |

---

## ❌ 绝对禁止

| 禁止行为 | 后果 |
|---------|------|
| 未阅读 BUILD.md 直接构建 | 遗漏关键步骤，构建失败 |
| Windows 本地构建 APK | 环境不完整，签名缺失 |
| 使用 Windows copy/Copy-Item 复制 APK | 复制缓存文件，APK 不是最新 |
| 未同步代码直接构建 | APK 包含旧代码，修复不生效 |
| 跳过 flutter clean | 增量编译问题，构建不一致 |
| 未验证 APK 时间戳 | 可能交付错误版本 |

---

## ✅ 强制流程

```
构建触发
  ↓
1. 主动读取 BUILD.md（非 alwaysApply，必须主动调用）
  ↓
2. 同步代码到 WSL
   rsync -av --delete /mnt/d/trae_projects/dang/lib/ /home/mayn/dang/lib/
  ↓
3. WSL 环境构建
   wsl -d dang bash -c "flutter clean && flutter build apk --release"
  ↓
4. WSL 复制 APK（带时间戳）到 D:\trae_projects\dang
   cp app-release.apk changji_app_20260516_1430.apk
  ↓
5. 验证 APK（确认在 D:\trae_projects\dang 目录下）
   Get-Item D:\trae_projects\dang\changji_app_*.apk | Select-Object Name, LastWriteTime
  ↓
构建完成
```

---

## 📁 APK 输出路径规范

### 标准输出路径

**APK 必须输出到**：`D:\trae_projects\dang`

| 文件类型 | 完整路径 | 用途 |
|---------|---------|------|
| 时间戳版本 | `D:\trae_projects\dang\changji_app_YYYYMMDD_HHMM.apk` | 正式交付和测试版本 |

### 路径检查命令

```powershell
# 检查 APK 是否在正确路径
Get-Item D:\trae_projects\dang\changji_app_*.apk | Select-Object FullName, LastWriteTime

# 预期输出：
# FullName                          LastWriteTime
# --------                          -------------
# D:\trae_projects\dang\changji_app_20260518_1430.apk  2026/05/18 14:30:00
```

### 路径错误后果

| 错误路径 | 后果 |
|---------|------|
| WSL 内部路径 | Windows 无法直接访问，无法交付 |
| 其他 Windows 路径 | 找不到 APK，交付失败 |
| 相对路径 | 路径解析错误，找不到文件 |

---

## ⚠️ 特别提醒

**BUILD.md 不是 alwaysApply 规则！**

每次构建前必须：
1. **主动读取** BUILD.md
2. **按流程执行** 每个步骤
3. **验证结果** 确认 APK 正确

---

## 更新记录

| 日期 | 更新内容 |
|-----|---------|
| 2026-05-17 | 初始版本 |
| 2026-05-18 | 强化 APK 输出路径规范：明确 D:\trae_projects\dang 为标准输出路径 |
