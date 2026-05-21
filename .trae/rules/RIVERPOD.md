---
alwaysApply: false
globs: lib/**/*.dart
description: 状态管理规范 - Riverpod 的使用约定和最佳实践
---
# RIVERPOD.md - 状态管理规范

## 核心理念

Riverpod 是应用状态的"仓库"。
好的状态管理让代码：
- **可预测**：状态变化清晰可见
- **可测试**：状态逻辑独立于 UI
- **可复用**：多个页面共享同一状态

---

## 基础概念

### Provider 是什么

Provider = 数据的"提供者"，类似仓库管理员。

```dart
// 定义 Provider
final counterProvider = Provider<int>((ref) => 0);

// 使用
ref.watch(counterProvider)  // 读取
ref.read(counterProvider)   // 读取但不监听变化
```

### 什么时候用什么 Provider

| Provider 类型 | 适用场景 | 示例 |
|--------------|---------|------|
| `Provider` | 只读数据/服务 | `recordingServiceProvider` |
| `StateProvider` | 简单状态 | `isRecordingProvider` |
| `StateNotifierProvider` | 复杂状态/有逻辑 | `recordingStateProvider` |
| `FutureProvider` | 异步数据 | `recordDetailProvider` |
| `StreamProvider` | 实时数据流 | `recordsProvider` |

---

## Provider 命名规则

按照 NAMING_CONVENTIONS.md：

| 类型 | 命名 | 示例 |
|-----|------|------|
| Service Provider | `xxxServiceProvider` | `recordingServiceProvider` |
| State Provider | `xxxStateProvider` | `recordingStateProvider` |
| Notifier Provider | `xxxProvider` | `recordListProvider` |
| Future Provider | `xxxFutureProvider` | `recordsFutureProvider` |
| Stream Provider | `xxxStreamProvider` | `recordsStreamProvider` |

---

## Provider 文件位置

```
lib/
├── core/services/
│   └── recording_service.dart       # Service 类
│
├── features/
│   └── recording/
│       └── providers/
│           └── recording_provider.dart  # Provider 定义
```

**规则**：
- Service 类 → `lib/core/services/`
- Provider 定义 → `lib/features/xxx/providers/`

---

## 常见用法

### 1. Service Provider（只读服务）

```dart
// 定义
final recordingServiceProvider = Provider<RecordingService>((ref) {
  return RecordingService();
});

// 使用
final service = ref.watch(recordingServiceProvider);
```

### 2. StateProvider（简单状态）

```dart
// 定义
final isRecordingProvider = StateProvider<bool>((ref) => false);

// 使用
final isRecording = ref.watch(isRecordingProvider);

// 修改
ref.read(isRecordingProvider.notifier).state = true;
```

### 3. StateNotifierProvider（复杂状态）

**State 类**：
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

**Notifier 类**：
```dart
class RecordingStateNotifier extends StateNotifier<RecordingState> {
  final RecordingService _service;

  RecordingStateNotifier(this._service) : super(const RecordingState());

  Future<void> startRecording() async {
    try {
      await _service.startRecording();
      state = state.copyWith(isRecording: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> stopRecording() async {
    await _service.stopRecording();
    state = state.copyWith(isRecording: false);
  }
}
```

**Provider**：
```dart
final recordingStateProvider = StateNotifierProvider<RecordingStateNotifier, RecordingState>((ref) {
  return RecordingStateNotifier(
    ref.watch(recordingServiceProvider),
  );
});
```

### 4. FutureProvider（异步数据）

```dart
// 简单用法
final recordDetailProvider = FutureProvider.family<RecordModel?, int>((ref, id) async {
  final repository = ref.watch(recordRepositoryProvider);
  return repository.getRecordById(id);
});

// 使用
final recordAsync = ref.watch(recordDetailProvider(1));

// 在 Widget 中
recordAsync.when(
  data: (record) => Text(record?.title ?? 'No title'),
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);
```

### 5. StreamProvider（实时数据）

```dart
final recordsProvider = StreamProvider<List<RecordModel>>((ref) {
  final repository = ref.watch(recordRepositoryProvider);
  return repository.watchAllRecords();
});
```

---

## Repository 模式集成

### Repository 接口

```dart
// domain/repository/user_repository.dart
abstract interface class UserRepository {
  Future<User?> getById(String id);
  Future<List<User>> getAll();
  Stream<List<User>> watchAll();
  Future<void> save(User user);
  Future<void> delete(String id);
}
```

### Repository 实现

```dart
// data/repository/user_repository_impl.dart
class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this._remote, this._local);

  final UserRemoteDataSource _remote;
  final UserLocalDataSource _local;

  @override
  Future<User?> getById(String id) async {
    final local = await _local.getById(id);
    if (local != null) return local;
    final remote = await _remote.getById(id);
    if (remote != null) await _local.save(remote);
    return remote;
  }

  @override
  Future<List<User>> getAll() async {
    final remote = await _remote.getAll();
    for (final user in remote) {
      await _local.save(user);
    }
    return remote;
  }

  @override
  Stream<List<User>> watchAll() => _local.watchAll();

  @override
  Future<void> save(User user) => _local.save(user);

  @override
  Future<void> delete(String id) async {
    await _remote.delete(id);
    await _local.delete(id);
  }
}
```

### Riverpod Provider

```dart
// features/user/providers/user_repository_provider.dart
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    ref.read(userRemoteDataSourceProvider),
    ref.read(userLocalDataSourceProvider),
  );
});

// features/user/providers/user_state_provider.dart
final userStateNotifierProvider = StateNotifierProvider<UserStateNotifier, UserState>((ref) {
  return UserStateNotifier(ref.read(userRepositoryProvider));
});
```

### StateNotifier 使用 Repository

```dart
class UserStateNotifier extends StateNotifier<UserState> {
  UserStateNotifier(this._repository) : super(const UserState());

  final UserRepository _repository;

  Future<void> loadUsers() async {
    state = const UserState.loading();
    try {
      final users = await _repository.getAll();
      state = UserState.success(users);
    } catch (e) {
      state = UserState.failure(e);
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _repository.delete(userId);
      // 重新加载
      await loadUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
```

---

## 测试示例

### StateNotifier 单元测试

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

### Provider 集成测试

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

---

## 最佳实践

### ✅ 推荐

- 使用 `StateNotifierProvider` 管理复杂状态
- 使用 `copyWith` 进行不可变更新
- 在 try-catch 中处理异步操作
- 使用 sealed class 表示状态
- 在 Notifier 中注入 Repository

### ❌ 避免

- 在 Widget 中直接修改状态（应通过 Notifier）
- 在 Notifier 中直接调用 API（应通过 Repository）
- 使用 mutable 状态（应使用 immutable）
- 在 build 方法中创建 Provider

---

## 在 Widget 中使用

### ConsumerWidget（推荐）

```dart
class RecordingScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听状态
    final state = ref.watch(recordingStateProvider);

    return Scaffold(
      body: Center(
        child: Text(state.isRecording ? '录音中' : '未开始'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 读取 notifier
          final notifier = ref.read(recordingStateProvider.notifier);
          if (state.isRecording) {
            notifier.stopRecording();
          } else {
            notifier.startRecording();
          }
        },
      ),
    );
  }
}
```

### ref.watch vs ref.read

| 方法 | 何时用 | 说明 |
|-----|-------|------|
| `ref.watch()` | UI 需要响应变化 | Widget 中监听状态 |
| `ref.read()` | 只取一次值 | 事件处理中，onPressed 等 |

```dart
// ✅ 在 build 中用 watch
final state = ref.watch(recordingStateProvider);

// ✅ 在 onPressed 中用 read
onPressed: () => ref.read(recordingStateProvider.notifier).startRecording(),
```

---

## Provider 依赖

### ref.watch 监听依赖

```dart
final paginatedRecordsProvider = StateNotifierProvider<PaginatedRecordsNotifier, AsyncValue<List<RecordModel>>>((ref) {
  return PaginatedRecordsNotifier(
    ref.watch(recordRepositoryProvider),  // 监听这个 Provider
  );
});
```

### ref.read 获取依赖

```dart
final recordingStateProvider = StateNotifierProvider<RecordingStateNotifier, RecordingState>((ref) {
  return RecordingStateNotifier(
    ref.read(recordingServiceProvider),  // 只取一次
    ref.read(recordRepositoryProvider),
  );
});
```

---

## 常见模式

### 分页加载

```dart
class PaginatedRecordsNotifier extends StateNotifier<AsyncValue<List<RecordModel>>> {
  final RecordRepository _repository;
  final int _pageSize = 20;
  int _currentPage = 0;

  PaginatedRecordsNotifier(this._repository) : super(const AsyncValue.data([])) {
    loadMore();
  }

  Future<void> loadMore() async {
    if (state.isLoading) return;

    state = state.copyWith loading: () => const AsyncValue.loading();

    try {
      final newRecords = await _repository.getRecordsWithPagination(_currentPage * _pageSize, _pageSize);
      _currentPage++;
      state = AsyncValue.data([...state.valueOrNull ?? [], ...newRecords]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
```

### 带过滤的状态

```dart
final filterProvider = StateProvider<RecordFilter>((ref) => RecordFilter.all);

final filteredRecordsProvider = Provider<List<RecordModel>>((ref) {
  final records = ref.watch(recordsProvider);
  final filter = ref.watch(filterProvider);

  return records.where((r) => filter.matches(r)).toList();
});
```

---

## 错误处理

### AsyncValue 用法

```dart
final state = ref.watch(recordingStateProvider);

// 使用 when
state.when(
  data: (data) => ContentWidget(data: data),
  loading: () => LoadingWidget(),
  error: (error, _) => ErrorWidget(error: error),
);

// 使用 whenOrNull
final data = state.valueOrNull;

// 使用 isLoading/isError
if (state.isLoading) return LoadingWidget();
if (state.hasError) return ErrorWidget(state.error);
```

---

## 规则总结

| 规则 | 说明 |
|-----|------|
| **Service 用 Provider** | `xxxServiceProvider` |
| **复杂状态用 StateNotifier** | State + Notifier + StateNotifierProvider |
| **Widget 用 ConsumerWidget** | 不是 StatelessWidget |
| **监听用 watch** | build 方法中 |
| **一次性用 read** | onPressed 等回调中 |
| **异步用 FutureProvider** | 返回 Future 的数据 |
| **实时用 StreamProvider** | 数据库监听等 |

---

## 禁止的做法

| ❌ 禁止 | ✅ 改为 |
|--------|--------|
| `StatefulWidget` 管理业务状态 | 用 `ConsumerWidget` + Provider |
| 在 build 外用 `ref.watch` | 在 build 内用 watch |
| 直接修改 state | 用 `state.copyWith()` |
| 在 Provider 外创建对象 | 所有依赖通过参数传入 |

---

## 总结

| 场景 | Provider 类型 |
|-----|-------------|
| 读取服务 | `Provider` |
| 简单开关/值 | `StateProvider` |
| 有业务逻辑的状态 | `StateNotifierProvider` |
| 网络请求/数据库查询 | `FutureProvider` |
| 实时数据流 | `StreamProvider` |

---

*遇到状态管理问题，先想：这个状态属于谁，谁需要监听它。*
