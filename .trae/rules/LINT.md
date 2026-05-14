---
alwaysApply: false
description: Lint 检查规范 - 代码分析和检查的要求
---
# LINT.md - Lint 检查规范

## 核心理念

Lint 检查帮助我们在代码写完**提交之前**发现问题，而不是等到运行时才发现。

Flutter 自带 Dart Lint，我们配置了一些额外的规则。

---

## 配置文件

项目根目录的 `analysis_options.yaml` 控制 Lint 规则：

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    avoid_print: true
    prefer_const_constructors: true
    prefer_final_locals: true
    prefer_single_quotes: true
    # ... 更多规则

analyzer:
  exclude:
    - "**/*.g.dart"
```

---

## 运行检查

### 完整检查

```bash
flutter analyze
```

### 检查特定文件

```bash
flutter analyze lib/core/services/recording_service.dart
```

### 检查并显示详细信息

```bash
flutter analyze --fatal-infos
```

---

## 主要规则说明

### 错误类（必须修复）

| 规则 | 说明 | 示例 |
|-----|------|------|
| `avoid_print` | 禁止使用 print | ❌ `print('debug')` → ✅ 使用 logger |
| `prefer_const_constructors` | 使用 const 构造函数 | ❌ `Container()` → ✅ `const Container()` |
| `prefer_final_locals` | 局部变量使用 final | ❌ `var x = 5` → ✅ `final x = 5` |
| `prefer_single_quotes` | 字符串使用单引号 | ❌ `"hello"` → ✅ `'hello'` |
| `unnecessary_nullable` | 移除不必要的可空 | ❌ `String? x = 'a'` → ✅ `String x = 'a'` |

### 警告类（建议修复）

| 规则 | 说明 | 示例 |
|-----|------|------|
| `avoid_unnecessary_containers` | 避免不必要的 Container | 简化 Widget 树 |
| `prefer_const_literals_to_create_immutables` | 字面量使用 const | ❌ `[1, 2]` → ✅ `const [1, 2]` |
| `use_key_in_widget_constructors` | Widget 添加 key 参数 | 提升性能 |
| `prefer_is_empty` | 使用 isEmpty | ❌ `list.length == 0` → ✅ `list.isEmpty` |

### 风格类（可选）

| 规则 | 说明 | 示例 |
|-----|------|------|
| `lines_longer_than_80_chars` | 行不超过 80 字符 | 提升可读性 |
| `sort_pub_dependencies` | 排序 pub 依赖 | 保持一致性 |
| `use_build_context_synchronously` | 使用 build context | 避免异步后使用 |

---

## 自定义规则

### 项目特定规则

我们在 `analysis_options.yaml` 中添加了：

```yaml
linter:
  rules:
    # Flutter 特定
    - prefer_const_constructors_in_immutables
    - use_key_in_widget_constructors
    
    # Dart 3 特性
    - prefer_final_in_for_each
    - unnecessary_lambdas
    
    # 安全相关
    - avoid_dynamic_calls
    - avoid_equal_and_default
```

### 忽略特定规则

有时需要忽略某些规则：

```dart
// 忽略单行
// ignore: avoid_print
print('Debug info');

// 忽略多行
// ignore_for_file: avoid_print

void debug() {
  print('Debug');
}
```

**注意**: 除非有充分理由，否则不要忽略规则。

---

## CI/CD 集成

### GitHub Actions

```yaml
- name: Flutter Analyze
  run: flutter analyze --fatal-infos --fatal-warnings
```

### 提交前检查

使用 hooks 自动运行：

```bash
# .trae/hooks/pre-commit
flutter analyze
```

---

## 常见问题

### 规则冲突

如果不同规则冲突，优先级：
1. 安全相关规则
2. 性能相关规则
3. 风格相关规则

### 误报处理

如果认为 Lint 误报：
1. 检查是否确实有问题
2. 如确认误报，添加 ignore 注释
3. 记录原因（便于后续审查）

---

## 规则引用

- 代码风格：`dart/coding-style.md`
- 安全红线：`RED_LINES.md`
- 代码审查：`common/code-review.md`

## 相关命令

```bash
# 运行 Lint
flutter analyze

# 严格模式
flutter analyze --fatal-infos --fatal-warnings

# 查看规则列表
dart help analyze

# 格式化代码（解决部分 Lint 问题）
dart format .
```

---

*Lint 是代码质量的守门员，帮助我们保持一致性和安全性。*

### ✅ 应该遵守的规则

| 规则 | 说明 | 示例 |
|-----|------|------|
| `prefer_const_constructors` | 优先用 const | `const Text('hello')` |
| `prefer_final_locals` | 局部变量用 final | `final name = 'test'` |
| `prefer_single_quotes` | 用单引号 | `'hello'` 而不是 `"hello"` |
| `avoid_print` | 生产代码不打印 | 删除 debug print |
| `avoid_unnecessary_containers` | 不要多余的 Container | 直接用 Text |
| `sort_child_properties_last` | child 属性放最后 | `FlatButton(child: Text(), onPressed: ...)` |
| `use_build_context_synchronously` | 异步使用 context 要检查 mounted | 防止内存泄漏 |

### ⚠️ 已关闭的规则

| 规则 | 关闭原因 |
|-----|---------|
| `always_specify_types` | 项目风格允许类型推断，代码更简洁 |

---

## 常见警告与修复

### 1. prefer_const_constructors

**警告**：
```
Don't use 'const' for constructors that can be inferred.
```

**修复**：如果可以推断出是 const，就加 const

```dart
// ✅ 修复前
final widget = Text('hello');

// ✅ 修复后
final widget = const Text('hello');
```

### 2. prefer_final_locals

**警告**：
```
Don't use 'var' for local variables that are not reassigned.
```

**修复**：用 final 代替 var

```dart
// ❌ 修复前
var name = 'test';
var count = 0;

// ✅ 修复后
final name = 'test';
final count = 0;
```

### 3. unnecessary_this

**警告**：
```
Unnecessary 'this.' usage.
```

**修复**：不要用 this.

```dart
// ❌ 修复前
class A {
  int value;
  A(this.value);
  void test() => print(this.value);
}

// ✅ 修复后
class A {
  int value;
  A(this.value);
  void test() => print(value);
}
```

### 4. avoid_print

**警告**：
```
Don't use 'print' in production code.
```

**修复**：
```dart
// ❌ 生产代码删除 print
print('debug: $value');

// ✅ 如果是 debug 模式，可以用
assert(() {
  print('debug: $value');
  return true;
}());
```

---

## 自动修复

很多 Lint 问题可以自动修复：

```bash
# 自动修复
dart fix --dry-run   # 先看会改什么
dart fix --apply     # 实际执行修复
```

---

## CI/CD 中的 Lint

在提交代码前，应该运行检查：

```bash
flutter analyze
```

如果检查不通过，代码不应该提交。

---

## IDE 配置

### VS Code

安装 Flutter 扩展后，Lint 会自动显示。

### IntelliJ/Android Studio

自带 Flutter 支持，Lint 警告会显示在编辑器中。

### 保存时自动修复

可以在 VS Code 设置中开启：

```json
{
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  }
}
```

---

## 生成的代码

项目中 `*.g.dart` 文件是自动生成的，不需要检查：

```yaml
analyzer:
  exclude:
    - "**/*.g.dart"  # drift 生成的数据库代码
```

---

## 总结

| 命令 | 用途 |
|-----|------|
| `flutter analyze` | 运行所有检查 |
| `flutter analyze lib/file.dart` | 检查特定文件 |
| `dart fix --dry-run` | 预览自动修复 |
| `dart fix --apply` | 执行自动修复 |

---

*在每次提交代码前，我会运行 `flutter analyze`，确保没有问题。*
