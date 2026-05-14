---
alwaysApply: false
description: Dart/Flutter 代码风格规范
---

# Dart/Flutter 代码风格

> 本文件扩展 `common/coding-style.md`，添加 Dart 和 Flutter 特定规范。

## 格式化

### dart format（强制）

- **所有 `.dart` 文件必须使用 `dart format`** - CI 强制执行
- 行长度限制：**80 字符**
- 多行参数/参数列表使用**尾随逗号**以改善 diff

```bash
# 格式化所有文件
dart format .

# 检查格式（CI 使用）
dart format --set-exit-if-changed .
```

### 导入排序

```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:convert';

// 2. Flutter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. 第三方包
import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// 4. 项目文件
import 'package:dang/models/user.dart';
import 'package:dang/services/auth_service.dart';

// 5. 相对导入
import '../utils/constants.dart';
import './widgets/user_card.dart';
```

## 不可变性

### 优先使用 final 和 const

```dart
// ❌ 不好
var count = 0;
List<String> items = ['a', 'b'];

// ✅ 好
final count = 0;
const items = ['a', 'b'];
```

### const 构造函数

```dart
// ✅ 所有字段为 final 时使用 const
class UserCard extends StatelessWidget {
  final User user;
  
  const UserCard({required this.user});
  
  @override
  Widget build(BuildContext context) {
    return Card(child: Text(user.name));
  }
}
```

### copyWith 模式

```dart
// 不可变状态的 mutations
class RecordingState {
  final bool isRecording;
  final String? error;
  final Duration duration;
  
  const RecordingState({
    this.isRecording = false,
    this.error,
    this.duration = Duration.zero,
  });
  
  RecordingState copyWith({
    bool? isRecording,
    String? error,
    Duration? duration,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      error: error ?? this.error,
      duration: duration ?? this.duration,
    );
  }
}

// 使用
state = state.copyWith(isRecording: true);
```

## 命名规范

遵循 Dart 约定：

| 类型 | 命名风格 | 示例 |
|-----|---------|------|
| 变量、参数、命名构造函数 | `camelCase` | `userName`, `totalCount` |
| 类、枚举、typedef、扩展 | `PascalCase` | `UserRepository`, `AsyncState` |
| 文件名、库名 | `snake_case` | `user_repository.dart`, `async_state.dart` |
| 顶层 const 常量 | `SCREAMING_SNAKE_CASE` | `API_TIMEOUT`, `MAX_RETRIES` |
| 私有成员 | `_` 前缀 | `_userService`, `_calculateTotal` |

### Provider 命名（Riverpod）

```dart
// StateNotifierProvider
final recordingStateProvider = StateNotifierProvider<...>(...);
final recordingStateNotifierProvider = StateNotifierProvider<...>(...);

// FutureProvider
final usersProvider = FutureProvider<List<User>>(...);

// StreamProvider
final recordingsProvider = StreamProvider<List<Recording>>(...);

// Provider（服务）
final dioProvider = Provider<Dio>((ref) => Dio());
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
```

## 空安全

### 避免 ! 操作符

```dart
// ❌ 不好 - 可能运行时崩溃
final name = user!.name;

// ✅ 好 - 空值操作符
final name = user?.name ?? 'Unknown';

// ✅ 好 - 早期返回
String getUserName(User? user) {
  if (user == null) return 'Unknown';
  return user.name; // 提升为非空
}
```

### 避免 late

```dart
// ❌ 不好 - 除非初始化保证
late final UserService _service;

// ✅ 好 - 使用 nullable 或构造函数初始化
final UserService? _service;

MyWidget() {
  _service = ref.read(userServiceProvider);
}
```

### 使用 required

```dart
class User {
  final String name;
  final int age;
  
  const User({
    required this.name,
    required this.age,
  });
}
```

## Dart 3+ 特性

### Sealed 类型

```dart
// 建模封闭状态层次
sealed class AsyncState<T> {
  const AsyncState();
}

final class Loading<T> extends AsyncState<T> {
  const Loading();
}

final class Success<T> extends AsyncState<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends AsyncState<T> {
  const Failure(this.error);
  final Object error;
}
```

### Exhaustive Switch（模式匹配）

```dart
// ❌ 不好 - 非 exhaustive
if (state is Loading) {
  return CircularProgressIndicator();
} else if (state is Success) {
  return Content(data: state.data);
}

// ✅ 好 - exhaustive switch
Widget build(BuildContext context) {
  return switch (asyncState) {
    Loading() => const CircularProgressIndicator(),
    Success(data: final d) => Content(data: d),
    Failure(error: final e) => ErrorText(error: e),
  };
}

// ✅ 好 - when 语法
return asyncState.when(
  loading: () => const CircularProgressIndicator(),
  data: (data) => Content(data: data),
  error: (error, _) => ErrorText(error: error.toString()),
);
```

## Widget 最佳实践

### const 构造函数

```dart
// ✅ 所有 final 字段 + const 构造函数
class UserCard extends StatelessWidget {
  final User user;
  
  const UserCard({required this.user});
  
  @override
  Widget build(BuildContext context) {
    return const Card( // ✅ const
      child: Text('User'),
    );
  }
}
```

### 避免 _build 方法

```dart
// ❌ 不好 - _build 方法阻止优化
Widget _buildHeader() {
  return Header(...);
}

// ✅ 好 - 提取为独立 widget
class HeaderWidget extends StatelessWidget {
  const HeaderWidget();
  
  @override
  Widget build(BuildContext context) {
    return Header(...);
  }
}
```

### Widget 提取阈值

- **>80 行** - 提取子 widget
- **重复 UI** - 提取为可复用组件
- **复杂逻辑** - 提取为独立类

## 错误处理

```dart
// ✅ 明确错误处理
try {
  await _service.startRecording();
  state = state.copyWith(isRecording: true);
} catch (e, st) {
  state = state.copyWith(error: e.toString());
  // 记录堆栈跟踪
  ref.read(loggerProvider).e('Recording failed', e, st);
}

// ✅ 使用 Result 类型
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}
```

## 代码组织

### 文件结构

```dart
// 1. Imports
import 'dart:async';
import 'package:flutter/';
import 'package:dang/';

// 2. Types/Enums
enum RecordingStatus { idle, recording, paused }

// 3. State classes
class RecordingState { ... }

// 4. Notifier/Controller
class RecordingNotifier extends StateNotifier<RecordingState> { ... }

// 5. Providers
final recordingProvider = StateNotifierProvider<...>(...);

// 6. Widget
class RecordingPage extends ConsumerWidget { ... }
```

### 类成员排序

```dart
class MyClass {
  // 1. 静态常量
  static const int maxItems = 100;
  
  // 2. 静态变量
  static int _count = 0;
  
  // 3. 实例常量
  final String id;
  
  // 4. 实例变量
  String? _name;
  
  // 5. 构造函数
  const MyClass({required this.id});
  
  // 6. Getter
  String get name => _name ?? 'Unknown';
  
  // 7. Setter
  set name(String value) => _name = value;
  
  // 8. 方法
  void update() { ... }
  Future<void> save() async { ... }
}
```

## 另请参阅

- 通用代码风格：`common/coding-style.md`
- 项目命名约定：`NAMING_CONVENTIONS.md`
- Lint 配置：`LINT.md`
