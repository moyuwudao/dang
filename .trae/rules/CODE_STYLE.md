---
alwaysApply: false
globs: lib/**/*.dart
description: 代码风格规范 - Dart/Flutter 代码的编写风格和格式
---
# CODE_STYLE.md - 代码风格规范

## 核心理念

代码风格统一比完美更重要。
一致的代码让人容易阅读和理解，减少认知负担。

---

## 格式化规则

### 缩进

- **使用空格**，2 空格（不是 Tab）
- 大括号 `{` 跟在语句同行， `}` 单独一行

```dart
// ✅ 正确
void doSomething() {
  if (condition) {
    doIt();
  }
}

// ❌ 错误
void doSomething(){
    if (condition){
        doIt();
    }
}
```

### 空行使用

| 场景 | 空行 |
|-----|------|
| 类之间 | 2 行 |
| 方法之间 | 1 行 |
| 逻辑段落之间 | 1 行 |
| import 之后 | 1 行 |
| 变量声明之间 | 不加 |

```dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String title;

  HomeScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final isEmpty = list.isEmpty;

    if (isEmpty) {
      return const EmptyView();
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(list[index]));
      },
    );
  }
}
```

---

## Import 导入顺序

### 规则

1. `dart:` 核心库
2. `package:` 外部包
3. `../` 相对导入（自己的代码）

每组之间空一行。

```dart
// 1. dart 核心
import 'dart:async';
import 'dart:io';

// 2. package 外部
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

// 3. 自己代码
import '../core/services/recording_service.dart';
import '../../data/models/record_model.dart';
```

### 避免循环引用

```
A 引用 B，B 引用 A → 循环引用，会报错
```

---

## 类和对象

### State 类的写法

```dart
class RecordingState {
  final bool isRecording;
  final Duration duration;
  final String? error;

  const RecordingState({
    this.isRecording = false,
    this.duration = Duration.zero,
    this.error,
  });

  RecordingState copyWith({
    bool? isRecording,
    Duration? duration,
    String? error,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      duration: duration ?? this.duration,
      error: error ?? this.error,
    );
  }
}
```

### 构造函数简写

```dart
// ✅ 简单赋值用这个
RecordingState({required this.isRecording, required this.duration});

// ❌ 不用这样
RecordingState({bool? isRecording, Duration? duration}) {
  this.isRecording = isRecording ?? false;
  this.duration = duration ?? Duration.zero;
}
```

### 使用 const

```dart
// ✅ 不可变的用 const
const RecordingState initialState = RecordingState();

// ✅ Widget 不可变属性用 const
return const Text('Hello');

// ✅ 列表为空时用 const
final List<String> emptyList = const [];
```

---

## 方法/函数

### 异步方法（async）

```dart
// ✅ 推荐
Future<void> saveRecord() async {
  final file = await _getFile();
  await file.writeAsString(content);
}

// ❌ 不要这样
Future<void> saveRecord() {
  return _getFile().then((file) {
    return file.writeAsString(content);
  });
}
```

### 单表达式函数用箭头函数

```dart
// ✅ 简单转换用箭头函数
String getDisplayName(String name) => name.toUpperCase();

// ✅ 简单返回用箭头函数
final isEmpty = list.isEmpty;
```

### 方法不要太长

```
理想：20-30 行以内
可接受：50 行以内
超过：考虑拆分
```

---

## 条件判断

### if/else

```dart
// ✅ 简短条件直接写
if (isLoading) {
  return const CircularProgressIndicator();
}

// ✅ else if 超过3个考虑用 switch
if (status == 'loading') {
  ...
} else if (status == 'error') {
  ...
} else if (status == 'success') {
  ...
} else {
  ...
}
```

### 三元运算符

```dart
// ✅ 简单二选一用三元
final label = isRecording ? '停止' : '录音';

// ❌ 复杂情况不用三元
// 不要：
final label = condition1 ? (condition2 ? 'A' : 'B') : 'C';
```

---

## 集合操作

### List/Map 字面量

```dart
// ✅
final list = [1, 2, 3];
final map = {'key': 'value'};

// ❌
final list = List<int>.from([1, 2, 3]);
```

### 遍历

```dart
// forEach - 只做操作不返回
list.forEach((item) => print(item));

// map - 转换
final names = users.map((u) => u.name).toList();

// where - 过滤
final adults = users.where((u) => u.age >= 18).toList();

// 循环要返回，用 for
final List<Widget> items = [];
for (final item in list) {
  items.add(Text(item));
}
```

---

## 空安全（? 的使用）

### 可空类型声明

```dart
String? nullableName;     // 可以是 String 也可以是 null
String nonNullableName;   // 必须是 String
```

### 空判断

```dart
// ✅ 用 ?? 提供默认值
final displayName = userName ?? '匿名';

// ✅ 用 ?. 调用方法（如果为 null 不调）
final length = text?.length;

// ✅ 用 ??= 赋值（如果为 null 才赋）
name ??= '默认名字';

// ✅ 用 if (value != null) 判断
if (error != null) {
  showSnackBar(error);
}
```

---

## 注释规则

### 什么时候加注释

| 情况 | 说明 |
|-----|------|
| 复杂逻辑 | 解释"为什么"而不是"做什么" |
| 业务规则 | 说明业务背景 |
| TODO | 标记未完成项 |

### 注释写法

```dart
// ✅ 解释为什么
// 使用 16000Hz 采样率因为 Whisper 模型训练数据是这个采样率
const int sampleRate = 16000;

// ✅ 标记 TODO
// TODO(Walle): 等 API 支持后实现批量删除

// ❌ 不要写显而易见的注释
// i 加 1
i++;

// ❌ 不要用注释解释语法
// 这是一个 for 循环
for (int i = 0; i < 10; i++) { }
```

---

## Widget 构建

### build 方法结构

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: _buildAppBar(),
    body: _buildBody(),
    floatingActionButton: _buildFab(),
  );
}

PreferredSizeWidget _buildAppBar() {
  return AppBar(title: const Text('录音'));
}

Widget _buildBody() {
  if (isLoading) {
    return const Center(child: CircularProgressIndicator());
  }
  return const Content();
}
```

### ConsumerWidget 用法

```dart
class RecordingScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recordingStateProvider);
    final notifier = ref.read(recordingStateProvider.notifier);

    return Scaffold(
      body: Text('状态: ${state.isRecording}'),
      onTap: () => notifier.startRecording(),
    );
  }
}
```

---

## 常见错误避免

| ❌ 错误写法 | ✅ 正确写法 |
|-----------|-----------|
| `String s = text ?? '';` | `String s = text ?? '';` |
| `if (list.length > 0)` | `if (list.isNotEmpty)` |
| `if (str != null && str != '')` | 视情况判断 |
| `list.forEach((i) => list2.add(i));` | `list2.addAll(list);` |
| `var x = 1; x += 1;` | `x++;` 或 `x += 1;` |
| `Container()` 加 child | `Container(child: Text())` |

---

## Lint 检查

项目使用 `analysis_options.yaml` 配置 lint 规则。

**常用规则**：
- `prefer_const_constructors`：优先用 const
- `avoid_print`：生产代码避免 print
- `prefer_single_quotes`：用单引号

**运行检查**：
```bash
flutter analyze
```

---

## 总结

| 原则 | 说明 |
|-----|------|
| **一致** | 和周围代码保持一致 |
| **简洁** | 不写废话代码 |
| **可读** | 让人容易看懂 |
| **const** | 能用 const 就用 |
| **不要太长** | 方法控制在 50 行以内 |

---

*如果不确定，看同目录下的代码是怎么写的，保持一致就行。*
