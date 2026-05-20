---
alwaysApply: false
description: API 异常案例集锦 - 收集所有 API 调用问题及解决方案
---

# API_TROUBLESHOOTING.md - API 异常案例集锦

## 核心理念

这份文档收集所有 API 调用过程中遇到的异常案例及解决方案。

**使用方式**：
1. API 调用失败时，先查看本文档是否有匹配案例
2. 如果有，按文档方案修复
3. 如果没有，修复后补充到本文档

> **构建相关异常** → 详见 [BUILD_TROUBLESHOOTING.md](BUILD_TROUBLESHOOTING.md)
>
> **API 设计规范** → 详见 [API_DESIGN.md](API_DESIGN.md)
>
> **API 测试规范** → 详见 [API_TESTING.md](API_TESTING.md)

---

## 📋 案例索引

| 编号 | 问题类型 | 关键错误信息 | 状态 |
|-----|---------|------------|------|
| CASE-006 | Qwen ASR 转写失败 | `url error, please check url` | ✅ 已解决 |
| CASE-008 | Qwen ASR 请求体格式错误 | `The provided URL does not appear to be valid` | ✅ 已解决 |
| CASE-009 | Qwen ASR type 值错误 | `Input should be 'text', 'image', 'audio'` | ✅ 已解决 |
| CASE-010 | Qwen ASR audio 格式错误 | `Input should be a valid string` | ✅ 已解决 |
| CASE-011 | Qwen 实时转写未集成 | `实时转写功能正在开发中` | ✅ 已解决 |
| CASE-012 | WebSocket 连接失败 | `WebSocket connection failed` | ✅ 已解决 |
| CASE-013 | 音频格式错误 | 实时转写无输出 | ✅ 已解决 |
| CASE-014 | HttpClient 实例不匹配 | 实时转写不可用 | ✅ 已解决 |
| CASE-015 | WebSocket URL 端点错误 | `HTTP status code: 404` | ✅ 已解决 |
| CASE-016 | audioStream 返回 null | 实时转写无法启动 | ✅ 已解决 |
| CASE-017 | WebSocket 认证方式错误 | `HTTP status code: 404/401` | ✅ 已解决 |
| CASE-018 | WebSocket 协议不匹配 | 连接成功但无转写结果 | ✅ 已解决 |
| CASE-019 | 缺少 response.create 事件 | session.updated 后无转写结果 | ✅ 已解决 |
| CASE-020 | 实时转写成功 | 完整成功案例 | ✅ 2026-05-18 验证通过 |

---

## 🔴 CASE-006: Qwen ASR 转写失败（URL 错误）

### 问题现象
```
[22:40:17.627] [I/Transcription] Qwen ASR ERROR: Response status=400, data={request_id: xxx, code: InvalidParameter, message: url error, please check url！}
```

### 根本原因
阿里云通义千问 ASR API 的 URL 和请求格式已变更，旧的专用格式不再支持：
- 旧 URL：`https://dashscope.aliyuncs.com/api/v1/services/audio/asr/transcription`
- 旧格式：`{model, input: {audio, format}, parameters: {...}}`

### 解决方案
修改 `lib/core/services/transcription_service.dart` 中的 `_transcribeQwenAsrBytes` 方法：

1. **更新 URL**：改用 OpenAI 兼容格式
   ```dart
   // 旧：baseUrl = 'https://dashscope.aliyuncs.com'
   // 新：baseUrl = 'https://dashscope.aliyuncs.com/compatible-mode/v1'
   // 旧：endpoint = '/api/v1/services/audio/asr/transcription'  
   // 新：endpoint = '/chat/completions'
   ```

2. **更新请求格式**：
   ```dart
   data: {
     'model': asrModel,
     'messages': [
       {
         'role': 'user',
         'content': [
           {
             'type': 'input_audio',
             'input_audio': {
               'data': base64Audio,
               'format': audioFormat,
             }
           }
         ]
       }
     ],
     'asr_options': {
       'enable_itn': true,
       'language': 'auto',
     },
   }
   ```

3. **更新响应解析**：
   ```dart
   if (data.containsKey('choices') && (data['choices'] as List?)?.isNotEmpty == true) {
     final choices = data['choices'] as List;
     final firstChoice = choices[0] as Map;
     if (firstChoice.containsKey('message') && firstChoice['message'] is Map) {
       final message = firstChoice['message'] as Map;
       text = message['content'] ?? '';
     }
   }
   ```

### 验证方法
1. 配置 Qwen API Key
2. 录制一段音频并触发转写
3. 检查日志是否显示成功转写结果

---

## 🔴 CASE-008: Qwen ASR 请求体格式错误

### 问题现象
URL 正确，但返回 400 错误：
```
[00:18:31.160] [I/Transcription] Qwen ASR ERROR: Response status=400, data={error: {message: <400> InternalError.Algo.InvalidParameter: The provided URL does not appear to be valid. Ensure it is correctly formatted., type: invalid_request_error, param: null, code: invalid_parameter_error}, ...}
```

### 根本原因
1. `asr_options` 是非 OpenAI 标准参数，需要放在 `extra_body` 中
2. 音频数据需要使用 **data URI 格式**：`data:audio/wav;base64,<base64>`
3. `type` 应使用 `audio_url` 而不是 `input_audio`

### 解决方案
```dart
final dataUri = 'data:audio/$audioFormat;base64,$base64Audio';

data: {
  'model': asrModel,
  'messages': [
    {
      'role': 'user',
      'content': [
        {
          'type': 'audio_url',
          'audio_url': {
            'url': dataUri,
          }
        }
      ]
    }
  ],
  'extra_body': {
    'asr_options': {
      'enable_itn': true,
      'language': 'auto',
    },
  },
}
```

---

## 🔴 CASE-009: Qwen ASR type 值错误

### 问题现象
```
Response status=500, data={error: {message: 3 validation errors for MultiModalMessage
content.list[union[str,function-after[post_check(), MultiModalItem]]].0.function-after[post_check(), MultiModalItem].type 
  Input should be 'text', 'image', 'audio', 'video' or 'image_hw' [type=literal_error, input_value='audio_url', input_type=str]
```

### 根本原因
`type` 字段值错误：`'audio_url'` → 应为 `'audio'`

### 解决方案
```dart
// 正确格式
{
  'type': 'audio',
  'audio': {
    'data': base64Audio,
    'format': audioFormat,
  }
}
```

---

## 🔴 CASE-010: Qwen ASR audio 格式错误

### 问题现象
```
Response status=500, data={error: {message: 3 validation errors for MultiModalMessage
content.list[...].audio Input should be a valid string [type=string_type, input_value={'data': '...', 'format': 'wav'}, input_type=dict]
```

### 根本原因
`audio` 字段应该是字符串（data URI），而不是对象。

### 解决方案
```dart
// 正确格式
{
  'type': 'audio',
  'audio': 'data:audio/$audioFormat;base64,$base64Audio',
}
```

---

## 🔴 CASE-011: Qwen 实时转写未集成

### 问题现象
- 录音界面显示"实时转写功能正在开发中"
- 开启实时转写后没有任何输出

### 根本原因
`TranscriptionService.startRealtimeTranscription()` 方法只是占位符，没有真正调用 `RealtimeTranscriptionService`。

### 解决方案
修改 `lib/core/services/transcription_service.dart`，将实时转写委托给 `_realtimeTranscriptionService.transcribeRealtime()`。

---

## 🔴 CASE-012: WebSocket URL 协议错误

### 问题现象
```
[E/Realtime] WebSocketException: Unsupported URL scheme 'https'
```

### 根本原因
WebSocket 连接必须使用 `wss://` 协议，但代码中从 `config.baseUrl`（`https://...`）直接拼接 URL。

### 解决方案
将 `https://` 替换为 `wss://`：
```dart
final wsBaseUrl = config.baseUrl.replaceFirst('https://', 'wss://');
```

---

## 🔴 CASE-013: 音频格式错误导致实时转写无输出

### 问题现象
- WebSocket 连接成功
- 没有收到任何转写文本

### 根本原因
音频配置不符合要求：
- ❌ WAV 文件格式
- ❌ MP3/压缩格式
- ❌ 采样率不是 16kHz
- ❌ 声道数不是 1 (mono)

### 解决方案
```dart
const recordConfig = RecordConfig(
  encoder: AudioEncoder.pcm16bits,
  sampleRate: 16000,
  numChannels: 1,
);
```

---

## 🔴 CASE-014: HttpClient 实例不匹配导致实时转写不可用

### 问题现象
- 配置了实时转写 API Key
- 开启实时转写并录音，没有实时转写输出
- 录音结束后调用了文件转写

### 根本原因
依赖注入的 HttpClient 实例不匹配：
- `sharedHttpClientProvider` → 独立的 HttpClient（已配置）
- `TranscriptionService._realtimeTranscriptionService` → 另一个独立的 HttpClient（未配置）

### 解决方案
在 `recording_provider.dart` 中创建专用的 `recordingRealtimeServiceProvider`，确保共享同一个 `sharedHttpClient`。

---

## 🔴 CASE-015: WebSocket URL 端点路径错误（404）

### 问题现象
```
[E/Realtime] WebSocketChannelException: WebSocketException: Connection to '.../compatible-mode/v1/realtime?...' was not upgraded to websocket, HTTP status code: 404
```

### 根本原因
混淆了文件转写端点和实时转写 WebSocket 端点：

| 功能 | 端点 |
|------|------|
| 文件转写 | `https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions` |
| 实时转写 | `wss://dashscope.aliyuncs.com/api-ws/v1/realtime` |

### 解决方案
WebSocket 端点是固定的，不应从 `config.baseUrl` 派生：
```dart
String _buildQwenWsUrl() {
  return 'wss://dashscope.aliyuncs.com/api-ws/v1/realtime';
}
```

---

## 🔴 CASE-016: audioStream getter 返回 null

### 问题现象
- 实时转写开关已开启
- 点击录音按钮后没有实时转写输出

### 根本原因
`RecordingService.audioStream` getter 中有错误的条件判断，当没有 listener 时返回 null。

### 解决方案
移除 `hasListener` 检查，只判断 controller 是否已关闭：
```dart
Stream<List<int>>? get audioStream => !_audioStreamController.isClosed
    ? _audioStreamController.stream
    : null;
```

---

## 🔴 CASE-017: WebSocket 认证方式错误（404/401）

### 问题现象
即使 URL 端点正确，仍然返回 404 或 401。

### 根本原因
认证方式错误：

| 功能 | 认证方式 |
|------|---------|
| 文件转写 | API Key in HTTP header: `Authorization: Bearer sk-xxx` |
| 实时转写 | API Key in WebSocket headers: `Authorization: bearer apiKey` |

### 解决方案
```dart
final channel = IOWebSocketChannel.connect(
  Uri.parse('wss://dashscope.aliyuncs.com/api-ws/v1/realtime'),
  headers: {
    'Authorization': 'bearer $apiKey',
  },
);
```

---

## 🔴 CASE-018: WebSocket 协议不匹配（OpenAI vs Fun-ASR）

### 问题现象
- WebSocket 连接成功
- 收到 `session.created` 事件
- 发送 `session.update` 后没有收到 `session.updated`
- 没有收到任何转写结果

### 根本原因
Qwen-Omni-Realtime 使用 OpenAI Realtime API 协议，不是 Fun-ASR 协议。

### 解决方案
使用 OpenAI Realtime API 协议：
```dart
final sessionUpdate = {
  'type': 'session.update',
  'session': {
    'modalities': ['text'],
    'input_audio_format': 'pcm',
    'output_audio_format': 'pcm',
    'voice': 'Chelsie',
    'turn_detection': {
      'type': 'server_vad',
      'threshold': 0.5,
      'silence_duration_ms': 800,
    },
  },
};

// 使用 Base64 编码发送音频
final appendMessage = {
  'type': 'input_audio_buffer.append',
  'audio': base64Encode(audioChunk),
};
```

---

## 🔴 CASE-019: 缺少 response.create 事件导致无转写结果

### 问题现象
- WebSocket 连接成功
- 收到 `session.updated`
- 音频数据正在发送
- 但没有收到任何转写结果

### 根本原因
OpenAI Realtime API 需要在 `session.updated` 后发送 `response.create` 事件来触发服务器处理音频。

### 解决方案
```dart
case 'session.updated':
  sessionConfigured = true;
  onStatusChange?.call('connected', '已连接，开始发送音频...');
  
  final responseCreate = {
    'event_id': 'event_${DateTime.now().millisecondsSinceEpoch}',
    'type': 'response.create',
    'response': {
      'modalities': ['text'],
    },
  };
  channel.sink.add(jsonEncode(responseCreate));
  break;
```

### 关键流程
```
1. 连接 WebSocket → 2. session.created → 3. session.update
→ 4. session.updated → 5. response.create → 6. 发送音频
→ 7. 转写结果 → 8. input_audio_buffer.commit
```

---

## ✅ CASE-020: 实时转写成功（2026-05-18 验证通过）

### 成功现象
- WebSocket 连接成功
- 收到 `session.created` 和 `session.updated`
- 音频发送后自动触发 VAD 检测
- 持续收到转写结果：`conversation.item.input_audio_transcription.text`
- 最终结果：`conversation.item.input_audio_transcription.completed`
- UI 实时显示完整转写文本

### 成功配置
```dart
const wsUrl = 'wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=qwen3-asr-flash-realtime';

headers: {
  'Authorization': 'bearer $apiKey',
}

final sessionUpdate = {
  'event_id': 'event_${DateTime.now().millisecondsSinceEpoch}_update',
  'type': 'session.update',
  'session': {
    'modalities': ['text'],
    'input_audio_format': 'pcm',
  },
};
```

### 关键成功因素
1. 正确的模型名称：`qwen3-asr-flash-realtime`
2. 正确的认证方式：WebSocket Headers (`Authorization: bearer apiKey`)
3. 正确的端点：`wss://dashscope.aliyuncs.com/api-ws/v1/realtime`
4. 正确的协议：OpenAI Realtime API 协议
5. 不需要发送 `conversation.item.create`：音频自动触发 VAD 检测
6. 不需要发送 `response.create`：音频发送后自动处理
7. 使用 `text` 字段显示完整文本

---

## 📖 使用指南

### API 调用失败时

1. **查看错误日志**，找到关键错误信息
2. **对照案例索引**，查找匹配的案例编号
3. **按案例方案修复**
4. **本地测试验证**（参考 [API_TESTING.md](API_TESTING.md)）

### 发现新案例时

1. 按格式添加新案例（编号递增）
2. 包含：问题现象、根本原因、解决方案、验证方法
3. 更新案例索引表

---

## 更新记录

| 日期 | 更新内容 |
|-----|---------|
| 2026-05-19 | 方案C重构：从 BUILD_TROUBLESHOOTING.md 拆分出 API 案例，独立管理 |