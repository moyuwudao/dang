---
alwaysApply: false
globs: test/**/*.dart, lib/**/*.dart
description: 测试规范 - 单元测试、集成测试的编写要求和约定
---
# TESTING.md - 测试规范

## 核心理念

测试的目的是**保护代码不被意外破坏**，而不是追求覆盖率数字。

对于 Walle 来说，不需要自己写测试，但我需要知道测试是怎么组织的、什么时候应该写测试。

---

## 测试文件结构

### 位置

```
test/
├── core/
│   ├── models/              # 模型测试
│   │   └── record_model_test.dart
│   ├── services/           # 服务测试
│   │   └── storage_service_test.dart
│   └── theme/              # 主题测试
├── data/
│   ├── database/           # 数据库测试
│   ├── models/             # 数据模型测试
│   └── repositories/       # 仓库测试
├── features/
│   └── records/
│       └── providers/      # Provider 测试
├── integration/            # 集成测试（API、真实环境）
├── widget/                 # Widget 测试
└── widget_test.dart        # 默认测试入口
```

### 命名规则

- 测试文件：`xxx_test.dart`
- 被测试文件：`xxx.dart`
- 在 `test/` 下保持与 `lib/` 相同的目录结构

---

## 测试类型

### 1. 单元测试

**测试对象**：单独的函数、类、方法

**特点**：
- 运行快（毫秒级）
- 不依赖外部环境
- Mock 外部依赖

**示例**：
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:changji_app/data/models/record_model.dart';

void main() {
  group('RecordModel', () {
    test('should create record with correct properties', () {
      final record = RecordModel(
        id: 1,
        type: RecordType.audio,
        content: 'Test content',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(record.id, 1);
      expect(record.type, RecordType.audio);
    });
  });
}
```

### 2. 集成测试

**测试对象**：多个组件配合工作的功能

**特点**：
- 运行慢（秒级）
- 真实环境测试
- 不 mock 数据

**示例**：
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  integrationTest('API transcription works', () async {
    final service = TranscriptionService();
    final result = await service.transcribe(audioFile);
    expect(result.text, isNotEmpty);
  });
}
```

### 3. Widget 测试

**测试对象**：Flutter UI 组件

**特点**：
- 测试 UI 渲染
- 可以模拟用户交互
- 属于集成测试的一种

---

## 测试结构

### 标准测试模板

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:changji_app/xxx.dart';  // 被测试的代码

void main() {
  group('XxxService / XxxModel', () {
    // 共享的 setup（可选）
    setUp(() {
      // 每个测试前运行
    });

    // 测试分组
    group('功能分组', () {
      test('should do something specific', () {
        // Arrange - 准备数据
        final service = XxxService();

        // Act - 执行操作
        final result = service.doSomething();

        // Assert - 验证结果
        expect(result, expectedValue);
      });
    });
  });
}
```

### group 分组

```dart
group('StorageService', () {
  group('Theme Mode', () {
    test('should save light theme', () { ... });
    test('should save dark theme', () { ... });
  });

  group('Locale', () {
    test('should save Chinese locale', () { ... });
    test('should save English locale', () { ... });
  });
});
```

---

## 常用匹配器

| 匹配器 | 用途 | 示例 |
|-------|------|------|
| `expect(value, equals(expected))` | 相等 | `expect(1 + 1, equals(2))` |
| `expect(value, isTrue)` | 是 true | `expect(isEmpty, isTrue)` |
| `expect(value, isFalse)` | 是 false | `expect(isEmpty, isFalse)` |
| `expect(value, isNull)` | 是 null | `expect(error, isNull)` |
| `expect(value, isNotNull)` | 不是 null | `expect(result, isNotNull)` |
| `expect(value, isA<T>())` | 是某个类型 | `expect(result, isA<List>())` |
| `expect(value, contains('text'))` | 包含文本 | `expect(list, contains('item'))` |
| `expect(value, throwsException)` | 抛出异常 | `expect(() => fn(), throwsException)` |
| `expect(value, predicate)` | 自定义条件 | `expect(value, predicate((v) => v > 0))` |

---

## Mock 使用

### mockito

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([DataRepository])
import 'data_repository_test.mocks.dart';

void main() {
  test('should call repository', () {
    final mockRepo = MockDataRepository();
    when(mockRepo.getData()).thenReturn('mock data');

    final service = MyService(mockRepo);
    final result = service.fetch();

    expect(result, 'mock data');
    verify(mockRepo.getData()).called(1);
  });
}
```

### setUp 注入 mock

```dart
void main() {
  late RecordingService service;
  late MockTranscriptionService mockTranscription;

  setUp(() {
    mockTranscription = MockTranscriptionService();
    service = RecordingService(transcriptionService: mockTranscription);
  });
}
```

---

## 异步测试

```dart
test('should save record async', () async {
  final repository = RecordRepository();

  await repository.save(testRecord);
  final loaded = await repository.getById(1);

  expect(loaded, isNotNull);
  expect(loaded!.content, testRecord.content);
});

test('should throw on error', () async {
  expect(
    () => repository.delete(nonExistentId),
    throwsException,
  );
});
```

---

## Widget 测试

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should display title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Hello'),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('should respond to tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: GestureDetector(
          onTap: () => tapped = true,
          child: const Text('Tap me'),
        ),
      ),
    );

    await tester.tap(find.text('Tap me'));
    expect(tapped, isTrue);
  });
}
```

---

## 什么时候需要写测试

### 应该写测试的情况

| 场景 | 原因 |
|-----|------|
| 新增 Service | 保护核心业务逻辑 |
| 新增数据模型 | 验证序列化/反序列化 |
| 修改现有功能 | 确保不破坏原有功能 |
| 复杂逻辑 | 防止边界情况漏掉 |

### 不需要写测试的情况

| 场景 | 原因 |
|-----|------|
| 简单 UI 页面 | Widget 测试价值有限 |
| 一次性代码 | 测试维护成本高 |
| 集成测试（API） | 慢且不稳定 |

---

## 运行测试

```bash
# 运行所有测试
flutter test

# 运行单个文件
flutter test test/core/services/storage_service_test.dart

# 运行集成测试
flutter test integration/

# 生成 coverage 报告
flutter test --coverage
```

---

## 集成测试环境

项目的 `integration/` 目录下是真实的 API 测试。

**注意**：
- 需要真实的 API 密钥
- 运行慢（秒级）
- 可能因为网络问题失败

---

## 总结

| 原则 | 说明 |
|-----|------|
| **保护核心** | Service、Model 等核心逻辑要测 |
| **保持简单** | 测试应该容易理解 |
| **独立** | 每个测试独立运行，不依赖其他 |
| **快速** | 单元测试应该在毫秒级完成 |
| **可读** | 测试名称要说明在测什么 |

---

*对于 Walle：你不需要自己写测试，但当我说"这个功能我需要写测试"时，你知道我在做什么。*
