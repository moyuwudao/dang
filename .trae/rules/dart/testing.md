---
alwaysApply: false
description: Dart/Flutter 测试规范
---

# Dart/Flutter 测试规范

> 本文件扩展 `common/testing.md`，添加 Dart 和 Flutter 特定测试要求。

## 测试框架

### 核心依赖

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0        # 或 mocktail（无需代码生成）
  mocktail: ^1.0.0       # 轻量级替代
  bloc_test: ^3.1.0      # BLoC 测试
  fake_async: ^1.3.1     # 时间控制
  integration_test:      # E2E 测试
    sdk: flutter
```

### 测试类型

| 类型 | 工具 | 位置 | 何时编写 |
|------|------|------|---------|
| **单元测试** | `dart:test` | `test/unit/` | 所有领域逻辑、状态管理器、Repository |
| **Widget 测试** | `flutter_test` | `test/widget/` | 所有有意义的 widget |
| **Golden 测试** | `flutter_test` | `test/golden/` | 设计关键的 UI 组件 |
| **集成测试** | `integration_test` | `integration_test/` | 关键用户流程（真机/模拟器） |

## 单元测试：状态管理器

### Riverpod StateNotifier 测试

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dang/notifiers/recording_notifier.dart';
import 'package:dang/services/recording_service.dart';

@GenerateMocks([RecordingService])
void main() {
  late MockRecordingService mockService;
  late RecordingStateNotifier notifier;

  setUp(() {
    mockService = MockRecordingService();
    notifier = RecordingStateNotifier(mockService);
  });

  tearDown(() => notifier.dispose());

  test('初始状态正确', () {
    expect(notifier.state.isRecording, false);
    expect(notifier.state.error, isNull);
    expect(notifier.state.duration, Duration.zero);
  });

  test('开始录音成功', () async {
    // Arrange
    when(mockService.startRecording())
        .thenAnswer((_) async => Future.value());

    // Act
    await notifier.startRecording();

    // Assert
    expect(notifier.state.isRecording, true);
    expect(notifier.state.error, isNull);
    verify(mockService.startRecording()).called(1);
  });

  test('开始录音失败', () async {
    // Arrange
    when(mockService.startRecording())
        .thenThrow(Exception('Recording failed'));

    // Act
    await notifier.startRecording();

    // Assert
    expect(notifier.state.isRecording, false);
    expect(notifier.state.error, isNotNull);
  });
}
```

### Riverpod Provider 测试

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usersProvider 从 repository 加载用户', () async {
    final container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(
          FakeUserRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(usersProvider.future);
    
    expect(result, isNotEmpty);
    expect(result.first.name, 'Test User');
  });

  testWidgets('recordingProvider 响应状态变化', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RecordingPage(),
      ),
    );

    // 触发状态变化
    await container.read(recordingNotifierProvider.notifier)
        .startRecording();
    await tester.pump();

    // 验证 UI 更新
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

### BLoC 测试（使用 bloc_test）

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dang/blocs/cart_bloc.dart';

void main() {
  late CartBloc bloc;
  late MockCartRepository repository;

  setUp(() {
    repository = MockCartRepository();
    bloc = CartBloc(repository);
  });

  tearDown(() => bloc.close());

  blocTest<CartBloc, CartState>(
    '添加商品时发出更新后的状态',
    build: () => bloc,
    act: (b) => b.add(CartItemAdded(testItem)),
    expect: () => [
      CartState(items: [testItem]),
    ],
  );

  blocTest<CartBloc, CartState>(
    '清空购物车时发出空状态',
    seed: () => CartState(items: [testItem]),
    build: () => bloc,
    act: (b) => b.add(CartCleared()),
    expect: () => [
      const CartState(),
    ],
  );

  blocTest<CartBloc, CartState>(
    '添加商品失败时发出错误状态',
    build: () => bloc,
    act: (b) => b.add(CartItemAdded(testItem)),
    expect: () => [
      CartState(error: 'Failed to add item'),
    ],
    when: () => when(repository.add(testItem))
        .thenThrow(Exception('Failed')),
  );
}
```

## Widget 测试

### 基础 Widget 测试

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dang/widgets/user_card.dart';

void main() {
  testWidgets('UserCard 显示用户信息', (tester) async {
    final user = User(id: '1', name: 'Walle', email: 'walle@example.com');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UserCard(user: user),
        ),
      ),
    );

    expect(find.text('Walle'), findsOneWidget);
    expect(find.text('walle@example.com'), findsOneWidget);
  });

  testWidgets('UserCard 点击触发回调', (tester) async {
    var tapped = false;
    final user = User(id: '1', name: 'Walle', email: 'walle@example.com');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserCard(
            user: user,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(UserCard));
    await tester.pump();

    expect(tapped, true);
  });
}
```

### Provider 依赖的 Widget 测试

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dang/pages/recording_page.dart';

void main() {
  testWidgets('RecordingPage 显示录音状态', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recordingStateProvider.overrideWith((ref) => RecordingState(isRecording: true)),
        ],
        child: const MaterialApp(home: RecordingPage()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('录音中...'), findsOneWidget);
  });
}
```

### Golden 测试

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:dang/widgets/user_card.dart';

void main() {
  testGoldens('UserCard 匹配设计稿', (tester) async {
    final user = User(id: '1', name: 'Walle', email: 'walle@example.com');

    await tester.pumpDeviceBuilder(
      MaterialDeviceScaffold.light(),
      (widgetTestingContext) async {
        await widgetTestingContext.pumpWidget(
          UserCard(user: user),
        );
      },
    );

    await screenMatchesGolden(tester, 'user_card_light');
  });
}
```

## 集成测试

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dang/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('完整录音流程', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. 点击录音按钮
    await tester.tap(find.byKey(const Key('record_button')));
    await tester.pumpAndSettle();

    // 2. 验证录音状态
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 3. 停止录音
    await tester.tap(find.byKey(const Key('stop_button')));
    await tester.pumpAndSettle();

    // 4. 验证录音列表更新
    expect(find.byType(RecordingCard), findsWidgets);
  });
}
```

## 测试覆盖率

### 覆盖率要求

- **最低覆盖率**: 80%
- **关键模块**: 90%+（状态管理、服务层）
- **UI 组件**: 70%+（widget 测试）

### 运行覆盖率

```bash
# 运行测试并生成覆盖率（设 10 分钟超时）
timeout 600 flutter test --coverage

# 查看覆盖率报告
genhtml coverage/lcov.info -o coverage/html

# 打开报告
open coverage/html/index.html
```

### 覆盖率检查脚本

```bash
#!/bin/bash
# scripts/check_coverage.sh
set -e
timeout 600 flutter test --coverage
lcov --list coverage/lcov.info | grep -E "^\|.*\|.*100\.0%.*\|$"
```

## 测试最佳实践

### AAA 模式

```dart
test('计算总价正确', () {
  // Arrange
  final cart = Cart();
  final item = Item(id: '1', price: 100, quantity: 2);

  // Act
  cart.addItem(item);

  // Assert
  expect(cart.total, equals(200));
});
```

### 测试命名

```dart
// ✅ 描述行为
test('添加商品时总价更新', () {});
test('商品数量为 0 时抛出异常', () {});
test('网络失败时显示错误信息', () {});

// ❌ 过于简单
test('测试添加', () {});
test('验证功能', () {});
```

### Mock 使用

```dart
// ✅ 使用 mockito
@GenerateMocks([UserService, AuthService])
void main() {
  late MockUserService mockUserService;
  
  setUp(() {
    mockUserService = MockUserService();
  });
}

// ✅ 使用 mocktail（无需代码生成）
class MockUserService extends Mock implements UserService {}

// ✅ 使用 fake 实现
class FakeUserRepository implements UserRepository {
  final users = <User>[];
  
  @override
  Future<List<User>> getAll() async => users;
}
```

## 测试检查清单

编写测试前：

- [ ] 理解被测功能
- [ ] 识别边界情况
- [ ] 准备测试数据
- [ ] 设置 mock/fake

编写测试时：

- [ ] 遵循 AAA 模式
- [ ] 测试 happy path
- [ ] 测试错误路径
- [ ] 测试边界情况
- [ ] 使用有意义的断言

编写测试后：

- [ ] 测试独立运行
- [ ] 测试名称清晰
- [ ] 覆盖率达标
- [ ] 无重复测试

## 另请参阅

- 通用测试要求：`common/testing.md`
- TDD 工作流：`common/development-workflow.md`
- Riverpod 模式：`RIVERPOD.md`
