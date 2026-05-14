---
alwaysApply: false
description: Dart/Flutter 规则目录说明
---

# Dart/Flutter Rules

> 本目录包含 Dart/Flutter 项目特定规则，扩展通用规则。

## 目录结构

```
dart/
├── coding-style.md    # Dart 代码风格（扩展 common/coding-style.md）
├── testing.md         # Dart 测试规范（扩展 common/testing.md）
├── security.md       # Dart 安全规范（扩展 common/security.md）
└── patterns.md        # Dart 架构模式（扩展 common/patterns.md）
```

## 规则优先级

当规则冲突时：

**dart > common > project-specific**

- `common/` 定义通用原则
- `dart/` 扩展 Dart/Flutter 特定规范
- `dang/` 项目特定规则可能覆盖（如有冲突）

## 核心规范

### 格式化

```bash
# 格式化所有文件
dart format .

# CI 检查
dart format --set-exit-if-changed .
```

### 分析

```bash
# 静态分析
flutter analyze

# 严格模式（致命警告）
flutter analyze --fatal-infos --fatal-warnings
```

### 测试

```bash
# 运行测试
flutter test

# 带覆盖率
flutter test --coverage

# 集成测试
flutter test integration_test/
```

### 构建

```bash
# Debug 构建
flutter build apk --debug

# Release 构建
flutter build apk --release

# 构建 iOS
flutter build ios --release --no-codesign
```

## 另请参阅

- 通用规则：`common/README.md`
- 项目特定规则：检查 `dang/` 目录
- Agent 配置：`.trae/agents/`
- Command 配置：`.trae/commands/`
