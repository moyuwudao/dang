---
alwaysApply: false
description: 实时转写技术架构分析与优化方案 - 架构梳理和性能优化建议
---

# 实时转写技术架构分析与优化方案

## 📊 一、现有技术架构总览

### 1.1 整体架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                        用户界面层                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              RecordingScreen (录音界面)                    │   │
│  │  - 实时转写开关 (Switch)                                  │   │
│  │  - 录音控制按钮                                           │   │
│  │  - 实时转写文本显示                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      状态管理层                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │         RecordingStateNotifier (Riverpod)                 │   │
│  │  - isRealtimeAvailable (是否可用)                         │   │
│  │  - isRealtimeEnabled (是否开启)                          │   │
│  │  - realtimeText (实时转写文本)                            │   │
│  │  + checkRealtimeAvailability()  【配置检查】              │   │
│  │  + toggleRealtime()              【开关切换】              │   │
│  │  + startRecording()               【启动录音】              │   │
│  │  + _startRealtimeTranscription()【启动实时转写】          │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      服务层                                      │
│  ┌──────────────────┐    ┌──────────────────┐                  │
│  │ RecordingService │    │ RealtimeTranscrip│                  │
│  │                  │    │ tionService      │                  │
│  │ - 音频采集       │    │                  │                  │
│  │ - 音频流输出     │───▶│ - WebSocket连接  │                  │
│  │ - WAV文件保存   │    │ - 音频发送       │                  │
│  │                  │    │ - 结果解析       │                  │
│  └──────────────────┘    └──────────────────┘                  │
│           │                         │                           │
│           ▼                         ▼                           │
│  ┌──────────────────┐    ┌──────────────────┐                  │
│  │ audioStream      │    │ HttpClient      │                  │
│  │ (Stream)         │    │ - API认证       │                  │
│  │                  │    │ - URL构建       │                  │
│  └──────────────────┘    │ - 签名计算       │                  │
│                         └──────────────────┘                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API层                                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Qwen 实时转写 WebSocket API                   │   │
│  │  URL: wss://dashscope.aliyuncs.com/realtime              │   │
│  │  认证: URL Query参数签名                                  │   │
│  │  音频: PCM 16kHz 16bit mono                              │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 核心组件职责

| 组件 | 文件位置 | 职责 | 关键方法 |
|------|---------|------|---------|
| **RecordingScreen** | `lib/features/recording/screens/recording_screen.dart` | UI展示和用户交互 | `initState()`, `_buildRealtimeToggle()` |
| **RecordingStateNotifier** | `lib/features/recording/providers/recording_provider.dart` | 状态管理和业务逻辑 | `checkRealtimeAvailability()`, `startRecording()`, `_startRealtimeTranscription()` |
| **RecordingService** | `lib/core/services/recording_service.dart` | 底层音频采集 | `startStream()`, `stopRecording()` |
| **RealtimeTranscriptionService** | `lib/core/services/realtime_transcription_service.dart` | WebSocket实时转写 | `transcribeRealtime()`, `_transcribeQwenRealtime()` |
| **HttpClient** | `lib/core/services/http_client.dart` | API认证和配置 | `configure()` |
| **AiModelConfig** | `lib/core/models/ai_model_config.dart` | 提供商配置 | `qwen`配置对象 |

### 1.3 数据流分析

```
录音开始
    │
    ▼
checkRealtimeAvailability()
    │
    ├─▶ 读取 MultiApiConfig
    │
    ├─▶ 读取 ApiConfig
    │
    └─▶ 配置 HttpClient ◀──────────────────┐
                                             │
RecordingService.startRecording()              │
    │                                        │
    ▼                                        │
_audioStreamController.add(data) ──────────────┤
    │                                        │
    ├─▶ 写入WAV文件                          │
    │                                        │
    └─▶ 音频流 ◀─────────────────────────────┤
              │                              │
              ▼                              │
_startRealtimeTranscription()                 │
    │                                        │
    ▼                                        │
RealtimeTranscriptionService.transcribeRealtime()
    │                                        │
    ├─▶ 构建Qwen WebSocket URL               │
    │                                        │
    ├─▶ 计算签名 (SHA256)                     │
    │                                        │
    ├─▶ 建立WebSocket连接 ◀──────────────────┤
    │                                        │
    ├─▶ 发送音频流                           │
    │                                        │
    └─▶ 接收转写结果 ◀───────────────────────┘
              │
              ▼
    UI显示实时文本
```

---

## 🔴 二、现有问题识别

### 2.1 问题清单

| 问题ID | 问题描述 | 影响程度 | 根因分析 |
|--------|---------|---------|---------|
| **P1** | `checkRealtimeAvailability()` 未被调用 | 🔴 致命 | `initState`中的`addPostFrameCallback`可能未执行 |
| **P2** | 实时转写开关状态不正确 | 🔴 致命 | `isRealtimeAvailable`始终为false |
| **P3** | `isConfigured`检查失败 | 🟠 严重 | `HttpClient`实例不匹配 |
| **P4** | WebSocket连接失败 | 🟠 严重 | URL/签名计算错误 |
| **P5** | 音频格式不匹配 | 🟡 中等 | 发送了非PCM格式数据 |

### 2.2 根因分析图

```
┌─────────────────────────────────────────────────────────────────┐
│                    问题：实时转写不工作                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  问题链：                                                         │
│                                                                  │
│  1. 用户日志中无 "[Realtime]" 前缀日志                            │
│     ↓                                                            │
│  2. checkRealtimeAvailability() 未执行                            │
│     ↓                                                            │
│  3. isRealtimeAvailable = false                                   │
│     ↓                                                            │
│  4. 实时转写开关被禁用                                            │
│     ↓                                                            │
│  5. 用户无法开启实时转写                                          │
│     ↓                                                            │
│  6. 录音结束后走文件转写                                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.3 潜在技术瓶颈

| 瓶颈 | 描述 | 影响 | 优化方向 |
|------|------|------|---------|
| **异步初始化** | `initState`中的异步调用可能未执行 | 开关状态不正确 | 确保异步完成后再渲染UI |
| **依赖注入** | 多个独立的HttpClient实例 | API配置不生效 | 统一使用sharedHttpClient |
| **异常处理** | 异步方法中的异常被吞掉 | 问题难以定位 | 增加详细的try-catch日志 |
| **音频格式** | WAV vs PCM 格式混淆 | 转写失败 | 明确区分音频格式 |

---

## 🎯 三、优化策略与实施步骤

### 3.1 短期优化（立即修复）

#### 🔧 P1修复：确保checkRealtimeAvailability()被执行

**问题**：`initState`中的`addPostFrameCallback`可能在Widget未挂载时执行

**解决方案A**：使用`Future.microtask`
```dart
@override
void initState() {
  super.initState();
  // 使用microtask确保在下一帧执行
  Future.microtask(() {
    ref.read(recordingStateProvider.notifier).checkRealtimeAvailability();
  });
}
```

**解决方案B**：使用`WidgetsBinding.instance.addPostFrameCallback`
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      ref.read(recordingStateProvider.notifier).checkRealtimeAvailability();
    }
  });
}
```

**推荐**：方案B，增加`mounted`检查

---

#### 🔧 P2修复：录音时重新检查配置

**问题**：只依赖初始检查，可能因为异步未完成而失败

**解决方案**：在`startRecording()`开始时重新检查配置
```dart
Future<void> startRecording() async {
  try {
    // 1. 检查麦克风权限
    final hasPermission = await _recordingService.hasPermission();
    if (!hasPermission) {
      state = state.copyWith(error: '需要麦克风权限');
      return;
    }

    // 2. 【关键】重新检查实时转写配置
    final realtimeAvailable = await checkRealtimeAvailability();
    debugPrint('[Realtime]录音开始时检查结果: $realtimeAvailable');

    // 3. 如果配置存在，强制设置isRealtimeEnabled = true
    if (realtimeAvailable) {
      state = state.copyWith(isRealtimeEnabled: true);
    }

    // 4. 开始录音
    final path = await _recordingService.startRecording();
    // ...
  }
}
```

---

#### 🔧 P3修复：统一HttpClient实例

**问题**：多个独立的HttpClient实例导致配置不生效

**解决方案**：
```dart
// 在 recording_provider.dart 中
final recordingRealtimeServiceProvider = Provider<RealtimeTranscriptionService>((ref) {
  // 使用同一个 sharedHttpClient 实例
  final sharedClient = ref.watch(sharedHttpClientProvider);
  return RealtimeTranscriptionService(httpClient: sharedClient);
});
```

---

### 3.2 中期优化（功能完善）

#### 📦 音频格式验证器

**目标**：确保发送正确格式的音频

```dart
class AudioFormatValidator {
  static const int expectedSampleRate = 16000;
  static const int expectedBitsPerSample = 16;
  static const int expectedChannels = 1;
  static const int expectedBytesPerChunk = 640; // 20ms @ 16kHz

  static bool validateChunk(List<int> chunk) {
    if (chunk.length != expectedBytesPerChunk) {
      debugPrint('[Audio] Invalid chunk size: ${chunk.length}, expected: $expectedBytesPerChunk');
      return false;
    }
    return true;
  }

  static String getFormatInfo() {
    return 'PCM ${expectedSampleRate}Hz ${expectedBitsPerSample}bit ${expectedChannels}ch';
  }
}
```

---

#### 📦 连接状态管理器

**目标**：更好的WebSocket连接管理

```dart
class ConnectionState {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration connectionTimeout = Duration(seconds: 10);
}

Future<void> connectWithRetry() async {
  for (int attempt = 1; attempt <= ConnectionState.maxRetries; attempt++) {
    try {
      debugPrint('[Realtime] 连接尝试 $attempt/${ConnectionState.maxRetries}');
      await _connect();
      return;
    } catch (e) {
      debugPrint('[Realtime] 连接失败: $e');
      if (attempt < ConnectionState.maxRetries) {
        await Future.delayed(ConnectionState.retryDelay);
      }
    }
  }
  throw Exception('连接失败，已重试${ConnectionState.maxRetries}次');
}
```

---

### 3.3 长期优化（架构升级）

#### 📊 性能监控

```dart
class TranscriptionMetrics {
  DateTime? connectionStartTime;
  DateTime? firstResultTime;
  DateTime? lastResultTime;
  int totalAudioChunks = 0;
  int totalResults = 0;

  void recordConnection() {
    connectionStartTime = DateTime.now();
  }

  void recordResult() {
    lastResultTime = DateTime.now();
    totalResults++;
    if (firstResultTime == null) {
      firstResultTime = DateTime.now();
    }
  }

  Duration? get latency {
    if (firstResultTime == null || connectionStartTime == null) return null;
    return firstResultTime!.difference(connectionStartTime!);
  }
}
```

---

#### 📊 日志分级系统

```dart
enum LogLevel { debug, info, warning, error }

class RealtimeLogger {
  static void log(LogLevel level, String message, {Map<String, dynamic>? data}) {
    final timestamp = DateTime.now().toIso8601String();
    final prefix = '[${level.name.toUpperCase()}]';
    final dataStr = data != null ? ' $data' : '';

    debugPrint('$timestamp $prefix [Realtime] $message$dataStr');
  }

  static void debug(String message) => log(LogLevel.debug, message);
  static void info(String message) => log(LogLevel.info, message);
  static void warning(String message) => log(LogLevel.warning, message);
  static void error(String message, [Object? error]) => log(LogLevel.error, message, data: {'error': error});
}
```

---

## 📋 四、实施步骤（第一阶段）

### 步骤1：修复P1和P2（优先级：🔴）

**文件**：`lib/features/recording/screens/recording_screen.dart`

```dart
@override
void initState() {
  super.initState();
  // 确保在Widget挂载后检查配置
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      ref.read(recordingStateProvider.notifier).checkRealtimeAvailability();
    }
  });
}
```

**文件**：`lib/features/recording/providers/recording_provider.dart`

```dart
Future<void> startRecording() async {
  try {
    final hasPermission = await _recordingService.hasPermission();
    if (!hasPermission) {
      state = state.copyWith(error: '需要麦克风权限');
      return;
    }

    // 【新增】重新检查实时转写配置
    final realtimeAvailable = await checkRealtimeAvailability();
    debugPrint('[Realtime] startRecording检查: isAvailable=$realtimeAvailable');

    // 【修改】开始录音前设置状态
    state = state.copyWith(
      isRecording: true,
      isPaused: false,
      duration: Duration.zero,
      amplitudes: const [],
      currentRecordingPath: null,
      error: null,
      isTranscribing: false,
      transcriptionProgress: null,
      realtimeText: null,
      isRealtimeEnabled: realtimeAvailable, // 根据配置自动设置
    );

    final path = await _recordingService.startRecording();
    state = state.copyWith(currentRecordingPath: path);

    // 监听振幅
    _amplitudeSubscription = _recordingService.amplitudeStream.listen((amplitudes) {
      state = state.copyWith(amplitudes: amplitudes);
    });

    // 监听时长
    _durationSubscription = _recordingService.durationStream.listen((duration) {
      state = state.copyWith(duration: duration);
    });

    // 【修改】如果配置存在，自动启动实时转写
    if (realtimeAvailable) {
      debugPrint('[Realtime] 自动启动实时转写');
      _startRealtimeTranscription();
    } else {
      debugPrint('[Realtime] 实时转写不可用，跳过');
    }
  } catch (e) {
    state = state.copyWith(error: '开始录音失败: $e');
  }
}
```

---

### 步骤2：添加详细日志（优先级：🟠）

**文件**：`lib/features/recording/providers/recording_provider.dart`

在每个关键步骤添加日志：
```dart
debugPrint('[Realtime] ============================================');
debugPrint('[Realtime] 检查配置: isRealtimeAvailable=${state.isRealtimeAvailable}');
debugPrint('[Realtime] 开关状态: isRealtimeEnabled=${state.isRealtimeEnabled}');
debugPrint('[Realtime] 配置检查结果: $result');
debugPrint('[Realtime] ============================================');
```

---

### 步骤3：添加音频格式验证（优先级：🟡）

**文件**：`lib/core/services/recording_service.dart`

```dart
_streamSubscription = audioStream.listen(
  (Uint8List data) {
    // 验证音频格式
    if (kDebugMode) {
      if (data.length != 640) {
        debugPrint('[Audio] 音频块大小异常: ${data.length} bytes (预期: 640 bytes)');
      }
    }

    _audioStreamController.add(data.toList());
    _fileSink?.add(data);
  },
  // ...
);
```

---

## 📊 五、测试计划

### 5.1 单元测试

| 测试用例 | 预期结果 | 测试方法 |
|---------|---------|---------|
| `checkRealtimeAvailability()` 正常配置 | 返回true | Mock ApiConfig |
| `checkRealtimeAvailability()` 无配置 | 返回false | Mock空配置 |
| `_buildQwenWsUrl()` URL格式 | 正确的签名URL | 验证URL格式 |
| `_buildQwenSignature()` 签名算法 | 正确的SHA256结果 | 对比已知值 |

### 5.2 集成测试

| 测试场景 | 预期结果 | 验证点 |
|---------|---------|-------|
| 配置实时转写 → 进入录音界面 | 开关可用 | `isRealtimeAvailable = true` |
| 点击录音按钮 | 自动启动实时转写 | WebSocket连接日志 |
| 说话 | 实时显示文本 | UI文本更新 |
| 停止录音 | 转写完成 | 最终文本保存 |

### 5.3 性能测试

| 指标 | 目标值 | 测量方法 |
|------|--------|---------|
| 首次转写延迟 | < 1秒 | 从录音开始到首次结果 |
| 转写吞吐量 | 实时 | 每秒处理音频量 |
| WebSocket连接成功率 | > 95% | 多次连接测试 |
| 内存占用 | < 100MB | Profiling工具 |

---

## ✅ 六、验收标准

### 6.1 功能验收

| 功能点 | 验收条件 | 测试方法 |
|-------|---------|---------|
| 配置检查 | 正确读取多API配置和单一配置 | 查看日志 |
| 开关状态 | 有配置时开关可用，无配置时禁用 | 手动测试 |
| 自动启动 | 有配置时录音自动启动实时转写 | 录音测试 |
| 实时显示 | 说话后<1秒显示文本 | 计时测试 |
| 结果保存 | 录音结束后保存转写结果 | 检查数据库 |

### 6.2 性能验收

| 指标 | 验收标准 | 测量工具 |
|------|---------|---------|
| 首次转写延迟 | < 1秒 | 日志计时 |
| 内存占用 | < 100MB | Android Profiler |
| APK大小增加 | < 5MB | 构建对比 |
| 崩溃率 | 0% | 多次测试 |

### 6.3 稳定性验收

| 场景 | 验收条件 |
|------|---------|
| 网络中断 | 自动重连或优雅降级 |
| 长时间录音 | 稳定运行>10分钟 |
| 配置变更 | 实时生效 |
| 后台切换 | 保持连接 |

---

## 📅 七、里程碑

| 阶段 | 时间 | 目标 | 验收条件 |
|------|------|------|---------|
| **Phase 1** | 立即 | 修复P1/P2，确保功能可用 | 能看到日志，能启动实时转写 |
| **Phase 2** | 1天 | 添加详细日志和异常处理 | 任何问题都能定位 |
| **Phase 3** | 2天 | 性能优化和稳定性增强 | 延迟<1秒，连接成功率>95% |
| **Phase 4** | 1周 | 完整测试和文档 | 满足所有验收标准 |

---

## 📞 联系方式与资源

- **规范文档**: [QWEN_REALTIME_ASR_API.md](QWEN_REALTIME_ASR_API.md)
- **错误集锦**: [BUILD_TROUBLESHOOTING.md](BUILD_TROUBLESHOOTING.md)
- **问题追踪**: REALTIME_TRANSCRIPTION_PLAN.md

---

*文档版本：1.0*
*创建时间：2026-05-17*
*最后更新：2026-05-17*
