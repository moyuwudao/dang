# Flutter 测试

## 用途

指导 Flutter/Dart 项目的测试编写，包括单元测试、Widget 测试、集成测试。

## 触发方式

```bash
/flutter-test [测试类型或文件路径]
```

## 测试类型

### 单元测试（Unit Tests）

测试单个函数、类或方法。

**位置**: `test/unit/`

**示例**:
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('格式化用户名', () {
    // Arrange
    const input = 'john doe';
    
    // Act
    final result = formatUserName(input);
    
    // Assert
    expect(result, 'John Doe');
  });
}
```

### Widget 测试

测试单个 Widget 的行为和渲染。

**位置**: `test/widget/`

**示例**:
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('登录按钮显示正确文本', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );

    final button = find.widgetWithText(ElevatedButton, '登录');
    expect(button, findsOneWidget);
  });
}
```

### 集成测试（Integration Tests）

测试完整功能流程。

**位置**: `integration_test/`

**示例**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('完整录音流程', (tester) async {
    await tester.pumpWidget(const DangApp());
    
    // 开始录音
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    
    // 验证录音状态
    expect(find.byType(RecordingIndicator), findsOneWidget);
    
    // 停止录音
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();
    
    // 验证录音保存
    expect(find.text('录音已保存'), findsOneWidget);
  });
}
```

### Riverpod 测试

测试 Provider 和 StateNotifier。

**位置**: `test/provider/`

**示例**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('状态变化正确', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    
    final notifier = container.read(recordingNotifierProvider.notifier);
    await notifier.startRecording();
    
    expect(
      container.read(recordingStateProvider).isRecording,
      true,
    );
  });
}
```

## 测试覆盖率要求

按照 dart/testing.md：

| 模块类型 | 覆盖率要求 |
|---------|----------|
| 核心业务逻辑 | >= 90% |
| 一般功能模块 | >= 80% |
| UI 组件 | >= 70% |
| 工具函数 | >= 95% |

### 生成覆盖率报告

```bash
# 运行测试并生成覆盖率
flutter test --coverage

# 查看覆盖率报告（HTML）
genhtml coverage/lcov.info -o coverage/html

# 打开报告
start coverage/html/index.html
```

## TDD 流程

遵循 **红 - 绿 - 重构** 循环：

1. 🔴 **红** - 先写失败的测试
2. 🟢 **绿** - 写最少代码让测试通过
3. 🔄 **重构** - 优化代码，保持测试通过

详细流程见 `agents/tdd-guide.md`

## 测试最佳实践

### ✅ 推荐

- 使用 descriptive test names
- 遵循 AAA 模式（Arrange-Act-Assert）
- 测试独立、可重复
- 使用 `setUp` 和 `tearDown`
- Mock 外部依赖
- 测试边界条件

### ❌ 避免

- 测试之间相互依赖
- 测试逻辑过于复杂
- 测试真实 API 调用
- 测试依赖顺序
- 忽略异步操作

## 常用命令

```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/unit/recording_service_test.dart

# 运行测试并生成覆盖率
flutter test --coverage

# 运行测试并查看输出
flutter test -r expanded

# 只运行标记的测试
flutter test --tags smoke

# 排除某些测试
flutter test --exclude-tags slow
```

## Mock 生成

使用 mockito 生成 mock：

```dart
// 1. 添加注解
@GenerateMocks([RecordingService, UserRepository])
void main() {}

// 2. 运行代码生成
flutter pub run build_runner build --delete-conflicting-outputs

// 3. 导入生成的 mock
import 'recording_service_test.mocks.dart';
```

## 规则引用

- 测试规范：`dart/testing.md`
- 代码风格：`dart/coding-style.md`
- 状态管理：`RIVERPOD.md`
- TDD 流程：`agents/tdd-guide.md`

## 相关 Agent

- tdd-guide - TDD 流程指导
- flutter-reviewer - 测试代码审查

---

*好的测试是代码的安全网，让你放心重构和迭代。*
