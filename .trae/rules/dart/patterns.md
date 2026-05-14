---
alwaysApply: false
description: Dart/Flutter 架构模式
---

# Dart/Flutter 架构模式

> 本文件扩展 `common/patterns.md`，添加 Dart 和 Flutter 特定架构模式。

## Repository 模式

### 定义

Repository 模式封装数据访问，提供一致的业务层接口。

### 实现

```dart
// 抽象接口（Domain 层）
abstract interface class UserRepository {
  Future<User?> getById(String id);
  Future<List<User>> getAll();
  Stream<List<User>> watchAll();
  Future<void> save(User user);
  Future<void> delete(String id);
}

// 具体实现（Data 层）
class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this._remote, this._local);

  final UserRemoteDataSource _remote;
  final UserLocalDataSource _local;

  @override
  Future<User?> getById(String id) async {
    // 先查本地缓存
    final local = await _local.getById(id);
    if (local != null) return local;
    
    // 缓存未命中，查远程
    final remote = await _remote.getById(id);
    if (remote != null) {
      await _local.save(remote); // 更新缓存
    }
    return remote;
  }

  @override
  Future<List<User>> getAll() async {
    final remote = await _remote.getAll();
    // 批量更新本地缓存
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

### Riverpod 集成

```dart
// Repository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    ref.read(userRemoteDataSourceProvider),
    ref.read(userLocalDataSourceProvider),
  );
});

// 在 ViewModel/Notifier 中使用
class UserStateNotifier extends StateNotifier<UserState> {
  UserStateNotifier(this._repository);
  
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
}

final userStateNotifierProvider = StateNotifierProvider<UserStateNotifier, UserState>((ref) {
  return UserStateNotifier(ref.read(userRepositoryProvider));
});
```

### 优势

- ✅ 业务逻辑不关心数据来源
- ✅ 轻松切换数据源（测试用 fake）
- ✅ 统一的数据访问接口
- ✅ 清晰的职责分离

## Service 层模式

### 定义

Service 层封装业务逻辑和外部 API 调用。

### 实现

```dart
// 服务接口
abstract interface class TranscriptionService {
  Future<String> transcribe(Uint8List audioData);
  Future<TranscriptionStatus> getStatus(String jobId);
}

// 服务实现
class TranscriptionServiceImpl implements TranscriptionService {
  TranscriptionServiceImpl(this._dio, this._apiKey);

  final Dio _dio;
  final String _apiKey;

  @override
  Future<String> transcribe(Uint8List audioData) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(audioData, filename: 'recording.wav'),
      'model': 'whisper-1',
    });

    final response = await _dio.post(
      'https://api.openai.com/v1/audio/transcriptions',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      ),
    );

    return response.data['text'] as String;
  }

  @override
  Future<TranscriptionStatus> getStatus(String jobId) async {
    // 实现状态查询逻辑
  }
}
```

## State Management 模式

### Riverpod StateNotifier

```dart
// 不可变状态
@freezed
class RecordingState with _$RecordingState {
  const factory RecordingState({
    @Default(false) bool isRecording,
    @Default(false) bool isPaused,
    @Default(Duration.zero) Duration duration,
    String? error,
    Recording? currentRecording,
  }) = _RecordingState;
}

// StateNotifier
class RecordingStateNotifier extends StateNotifier<RecordingState> {
  RecordingStateNotifier(this._service) : super(const RecordingState());

  final RecordingService _service;
  StreamSubscription? _subscription;

  Future<void> startRecording() async {
    try {
      await _service.startRecording();
      state = state.copyWith(isRecording: true, error: null);
      
      // 监听录音时长
      _subscription = _service.durationStream.listen((duration) {
        state = state.copyWith(duration: duration);
      });
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> stopRecording() async {
    try {
      final recording = await _service.stopRecording();
      state = state.copyWith(
        isRecording: false,
        isPaused: false,
        currentRecording: recording,
      );
      _subscription?.cancel();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// Provider 定义
final recordingServiceProvider = Provider<RecordingService>((ref) {
  return RecordingService();
});

final recordingStateProvider = StateNotifierProvider<RecordingStateNotifier, RecordingState>((ref) {
  return RecordingStateNotifier(ref.read(recordingServiceProvider));
});
```

### BLoC 模式

```dart
// 事件
@freezed
abstract class RecordingEvent with _$RecordingEvent {
  const factory RecordingEvent.started() = RecordingStarted;
  const factory RecordingEvent.stopped() = RecordingStopped;
  const factory RecordingEvent.paused() = RecordingPaused;
  const factory RecordingEvent.resumed() = RecordingResumed;
}

// 状态
@freezed
abstract class RecordingState with _$RecordingState {
  const factory RecordingState.initial() = RecordingInitial;
  const factory RecordingState.recording(Duration duration) = RecordingInProgress;
  const factory RecordingState.paused(Duration duration) = RecordingPaused;
  const factory RecordingState.completed(Recording recording) = RecordingCompleted;
  const factory RecordingState.error(String message) = RecordingError;
}

// BLoC
class RecordingBloc extends Bloc<RecordingEvent, RecordingState> {
  RecordingBloc(this._service) : super(const RecordingState.initial()) {
    on<RecordingStarted>(_onStarted);
    on<RecordingStopped>(_onStopped);
    on<RecordingPaused>(_onPaused);
    on<RecordingResumed>(_onResumed);
  }

  final RecordingService _service;

  Future<void> _onStarted(RecordingStarted event, Emitter<RecordingState> emit) async {
    try {
      await _service.startRecording();
      emit(const RecordingState.recording(Duration.zero));
      
      await for (final duration in _service.durationStream) {
        if (state is RecordingInProgress) {
          emit(RecordingState.recording(duration));
        }
      }
    } catch (e) {
      emit(RecordingState.error(e.toString()));
    }
  }

  Future<void> _onStopped(RecordingStopped event, Emitter<RecordingState> emit) async {
    final recording = await _service.stopRecording();
    emit(RecordingState.completed(recording));
  }

  // ... 其他事件处理
}
```

## Clean Architecture

### 分层结构

```
┌─────────────────────────────────────┐
│     Presentation Layer (UI)         │
│  - Widgets                          │
│  - Pages                            │
│  - State Notifiers / BLoCs          │
├─────────────────────────────────────┤
│       Domain Layer (Business)       │
│  - Entities                         │
│  - Use Cases                        │
│  - Repository Interfaces            │
├─────────────────────────────────────┤
│         Data Layer                  │
│  - Repository Implementations       │
│  - Data Sources (Remote/Local)      │
│  - DTOs / Models                    │
└─────────────────────────────────────┘

依赖规则：内层不能依赖外层
```

### 目录结构

```
lib/
├── core/                    # 核心工具
│   ├── error/
│   ├── usecases/
│   └── utils/
├── features/
│   └── recording/
│       ├── data/
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/
│           ├── pages/
│           ├── widgets/
│           └── providers/
└── main.dart
```

## 依赖注入

### Riverpod 方式

```dart
// 服务注册
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: 'https://api.example.com'));
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(dioProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    ref.read(userRemoteDataSourceProvider),
    ref.read(userLocalDataSourceProvider),
  );
});

// 在 Notifier 中使用
class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier(this._authService);
  
  final AuthService _authService; // 通过构造函数注入
  
  Future<void> login(String email, String password) async {
    final user = await _authService.login(email, password);
    state = AuthState.authenticated(user);
  }
}

final authStateNotifierProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref.read(authServiceProvider));
});
```

## 另请参阅

- 通用模式：`common/patterns.md`
- Riverpod 规范：`RIVERPOD.md`
- 代码风格：`dart/coding-style.md`
