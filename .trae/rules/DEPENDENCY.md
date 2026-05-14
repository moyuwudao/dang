---
alwaysApply: false
description: 依赖管理规范 - pub 添加/更新依赖的流程和注意事项
---

# DEPENDENCY.md - 依赖管理规范

## 核心理念

依赖管理要谨慎。添加一个依赖很容易，但：
- 可能引入安全问题
- 可能增加 APK 大小
- 可能导致版本冲突
- 依赖作者可能停止维护

**加依赖前先问：真的需要吗？**

---

## 配置文件

### pubspec.yaml

```yaml
name: changji_app
description: AI Voice Notes for One-Person Companies

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  # ... 你的依赖

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
  # ... 开发依赖
```

---

## 添加依赖

### 步骤

```bash
# 1. 先问（按 INTERACTION.md）
# 我会说：想加 xxx 依赖，因为 xxx

# 2. 得到确认后，执行
flutter pub add package_name

# 或者手动添加到 pubspec.yaml，然后
flutter pub get
```

### 依赖来源

| 来源 | 命令 | 示例 |
|-----|------|------|
| pub.dev | `flutter pub add xxx` | `flutter pub add dio` |
| 指定版本 | `flutter pub add xxx:^1.0.0` | `flutter pub add dio:^5.8.0` |
| Git | `flutter pub add xxx --git-url=...` | 私有包 |

### 版本约束

| 写法 | 含义 |
|-----|------|
| `^1.0.0` | >=1.0.0 且 <2.0.0 |
| `1.0.0` | 严格等于 1.0.0 |
| `>=1.0.0 <2.0.0` | 范围约束 |

**推荐用 `^`**，既能获得安全更新，又不会breaking change。

---

## 更新依赖

### 更新单个依赖

```bash
flutter pub upgrade package_name
```

### 更新所有依赖

```bash
flutter pub upgrade
```

### 查看可更新版本

```bash
flutter pub outdated
```

---

## 删除依赖

```bash
flutter pub remove package_name
```

或者手动从 pubspec.yaml 删除，然后 `flutter pub get`。

---

## 添加依赖前的检查

### 1. 真的需要吗？

| 问题 | 如果是，加 | 如果不是，替代方案 |
|-----|----------|------------------|
| 这个功能 Flutter 内置吗？ | 检查 Flutter SDK | 用内置实现 |
| 一行代码能搞定吗？ | 考虑自己写 | 自己写 |
| 依赖有多复杂？ | 检查 size | 找更轻量的库 |

### 2. 库的质量

| 检查项 | 怎么查 |
|-------|--------|
| 维护状态 | 最近更新是什么时候？ |
| 下载量 | pub.dev 看周下载量 |
| issues | 有多少 open issues？活跃吗？ |
| 文档 | 文档齐全吗？ |
| 依赖数量 | 依赖太多会拖慢 pub get |

### 3. 兼容性

| 检查项 | 怎么做 |
|-------|--------|
| Dart SDK | 确保 `sdk: '>=3.0.0'` 兼容 |
| Flutter 版本 | 看 `flutter: sdk` 要求 |
| 其他依赖 | 可能有版本冲突 |

---

## 依赖分类

### dependencies（运行时）

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1    # 状态管理
  dio: ^5.8.0                  # 网络请求
  drift: ^2.31.0              # 数据库
```

### dev_dependencies（开发时）

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7         # 代码生成
  drift_dev: ^2.31.0          # drift 代码生成
```

---

## 常见依赖问题

### 1. 版本冲突

**问题**：
```
Because package_a depends on dio ^5.0.0 and package_b requires dio ^4.0.0, version solving failed.
```

**解决**：
```bash
# 查看依赖树
flutter pub deps

# 尝试升级/降级某个包
flutter pub upgrade package_a
```

### 2. 缓存问题

```bash
# 清理缓存
flutter pub cache clean

# 重新获取
flutter pub get
```

### 3. pub get 失败

```bash
# 删除 pubspec.lock 和 .dart_tool，重新获取
rm pubspec.lock
rm -rf .dart_tool/
flutter pub get
```

---

## 特殊依赖

### 代码生成依赖

如果加了需要 build_runner 的包：

```bash
# 运行代码生成
dart run build_runner build

# 如果是 watch 模式
dart run build_runner watch
```

### Android 特定依赖

在 `android/app/build.gradle.kts` 中可能需要额外配置。

---

## APK 大小考虑

### 查看依赖大小

```bash
flutter build apk --analyze-size
```

### 大依赖警告

| 依赖类型 | 典型大小 | 警告阈值 |
|---------|---------|---------|
| 机器学习 | 20MB+ | google_mlkit_text_recognition |
| 数据库 | 5-10MB | drift + sqlite |
| 图像处理 | 10MB+ | image_picker |

**加了大依赖要告诉 Walle**。

---

## 禁止的行为

| 禁止 | 原因 |
|-----|------|
| ❌ 不问就加依赖 | 可能不必要、可能有风险 |
| ❌ 加没维护的依赖 | 以后出问题没人修 |
| ❌ 加有很多漏洞的依赖 | 安全风险 |
| ❌ 加超大的依赖（除非必要） | APK 太大 |

---

## 总结

| 操作 | 命令 |
|-----|------|
| 加依赖 | `flutter pub add xxx` |
| 删依赖 | `flutter pub remove xxx` |
| 更新 | `flutter pub upgrade` |
| 查看依赖 | `flutter pub deps` |
| 清理缓存 | `flutter pub cache clean` |
| 代码生成 | `dart run build_runner build` |

---

*加依赖前先问：真的需要吗？有更简单的方案吗？*
