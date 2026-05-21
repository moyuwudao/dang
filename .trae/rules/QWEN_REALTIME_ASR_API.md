---
alwaysApply: false
globs: lib/**/asr/**, lib/**/transcription/**, lib/**/realtime/**
description: 阿里云通义千问实时转写 WebSocket API 规范 - 严禁随意修改
---

# Qwen 实时转写 WebSocket API 规范

## 概述

本文档记录阿里云通义千问实时转写 WebSocket API 的正确调用方式，**严禁随意修改**。

**重要更新（2026-05-17）**：经过实际测试和官方文档确认，之前的端点和认证方式有误，已修正。

---

## API 信息

| 项目 | 值 |
|------|-----|
| **协议** | WebSocket |
| **URL** | `wss://dashscope.aliyuncs.com/api-ws/v1/realtime` |
| **认证** | WebSocket Headers (`Authorization: bearer apiKey`) |
| **模型** | `qwen3-asr-flash-realtime` |
| **音频格式** | PCM (16kHz, 16bit, mono) |

---

## 认证方式

### 正确的认证方式（Headers）

```dart
final channel = IOWebSocketChannel.connect(
  Uri.parse('wss://dashscope.aliyuncs.com/api-ws/v1/realtime'),
  headers: {
    'Authorization': 'bearer $apiKey',
  },
);
```

### ❌ 错误的认证方式（已废弃）

```dart
// 错误！URL Query 参数认证不适用于此端点
wss://dashscope.aliyuncs.com/realtime?api_key=xxx&timestamp=xxx&signature=xxx
```

### 关键区别

| 功能 | 端点 | 认证方式 |
|------|------|---------|
| 文件转写 | `https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions` | API Key in header |
| 实时转写 | `wss://dashscope.aliyuncs.com/api-ws/v1/realtime` | `Authorization: bearer apiKey` |

---

## 音频格式要求

### 必须满足的条件

| 参数 | 值 |
|------|-----|
| **采样率** | 16000 Hz |
| **位深度** | 16 bit |
| **声道数** | 1 (mono) |
| **编码格式** | PCM (原始字节) |
| **每帧大小** | 320 bytes (16000 * 16 / 8 * 0.02s = 640 samples × 2 bytes) |

### 音频参数配置

```dart
const recordConfig = RecordConfig(
  encoder: AudioEncoder.pcm16bits,  // PCM 16bit
  sampleRate: 16000,               // 16kHz
  numChannels: 1,                  // 单声道
);
```

### ⚠️ 关键注意事项

- ❌ **不要**发送 WAV 文件格式的数据
- ❌ **不要**发送 MP3 或其他压缩格式
- ✅ **必须**发送原始 PCM 字节数据
- ✅ 每个音频块大小应该是 640 bytes（16kHz × 16bit × 1ch × 20ms）

---

## 消息格式

### 1. 发送：run-task 指令（连接成功后必须发送）

```json
{
  "header": {
    "action": "run-task",
    "task_id": "32位随机字符串",
    "streaming": "duplex"
  },
  "payload": {
    "task_group": "audio",
    "task": "asr",
    "function": "recognition",
    "model": "qwen3-asr-flash-realtime",
    "parameters": {
      "sample_rate": 16000,
      "format": "pcm"
    },
    "input": {}
  }
}
```

### 2. 发送：音频数据

直接发送原始字节数据：

```dart
await for (final audioChunk in audioStream) {
  if (audioChunk.isNotEmpty) {
    channel.sink.add(audioChunk);  // 原始 PCM 字节
  }
}
```

### 3. 发送：finish-task 指令（音频发送完毕后发送）

```json
{
  "header": {
    "action": "finish-task",
    "task_id": "32位随机字符串",
    "streaming": "duplex"
  },
  "payload": {
    "input": {}
  }
}
```

### 4. 接收：转写结果

服务器返回 JSON 格式消息：

```json
{
  "header": {
    "event": "result-generated"
  },
  "payload": {
    "output": {
      "sentence": {
        "text": "转写的文本内容",
        "begin_time": 0,
        "end_time": 1200,
        "sentence_end": false
      }
    }
  }
}
```

### 事件类型

| event | 含义 |
|--------|------|
| `task-started` | 任务已启动，可以开始发送音频 |
| `result-generated` | 转写结果生成 |
| `task-finished` | 任务完成 |
| `task-failed` | 任务失败 |

---

## 响应解析代码

```dart
channel.stream.listen(
  (message) {
    final data = jsonDecode(message as String);
    final header = data['header'] as Map<String, dynamic>?;
    final event = header?['event'] as String?;

    switch (event) {
      case 'task-started':
        // 可以开始发送音频了
        break;

      case 'result-generated':
        final payload = data['payload'] as Map<String, dynamic>?;
        final output = payload?['output'] as Map<String, dynamic>?;
        final sentence = output?['sentence'] as Map<String, dynamic>?;
        if (sentence != null) {
          final text = sentence['text'] as String? ?? '';
          final isFinal = sentence['sentence_end'] as bool? ?? false;
          // 处理转写结果
        }
        break;

      case 'task-finished':
        // 转写完成
        break;

      case 'task-failed':
        final errorMsg = header?['error_message'] as String? ?? '未知错误';
        // 处理错误
        break;
    }
  },
  onError: (error) {
    // 处理连接错误
  },
  onDone: () {
    // 连接关闭
  },
);
```

---

## 完整流程图

```
1. 建立 WebSocket 连接（带 Authorization header）
   ↓
2. 等待服务器返回 task-started 事件
   ↓
3. 发送音频 PCM 数据（循环）
   ↓
4. 接收并解析 result-generated 事件
   ↓
5. 显示实时文本
   ↓
6. 音频发送完毕后发送 finish-task 指令
   ↓
7. 等待 task-finished 或 task-failed 事件
```

---

## ✅ 成功经验（2026-05-18 验证通过）

### 实际测试验证

使用 Node.js 测试脚本成功连接并获取实时转写结果：

```javascript
const WS_URL = "wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=qwen3-asr-flash-realtime";
const API_KEY = "sk-xxx";
```

**测试结果**：
- ✅ WebSocket 连接成功
- ✅ `session.created` 收到
- ✅ `session.updated` 收到
- ✅ 音频发送后自动触发 VAD 检测
- ✅ `conversation.item.input_audio_transcription.text` 持续返回转写结果
- ✅ `conversation.item.input_audio_transcription.completed` 返回最终完整文本

**关键发现**：
1. **不需要发送 `conversation.item.create`** - 音频会自动触发 VAD 检测和转写
2. **不需要发送 `response.create`** - 音频发送后会自动处理
3. **模型名称**：使用 `qwen3-asr-flash-realtime`（不是 `qwen-omni-turbo-realtime`）
4. **文本字段**：`text` 包含完整历史文本，`stash` 包含当前句子增量

### 正确的事件处理流程

```
1. 连接 WebSocket
   ↓
2. 收到 session.created
   ↓
3. 发送 session.update
   ↓
4. 收到 session.updated
   ↓
5. 【关键】开始发送音频数据 (input_audio_buffer.append)
   ↓
6. 自动触发 VAD 检测
   ↓
7. 收到 conversation.item.input_audio_transcription.text（实时结果）
   ↓
8. 收到 conversation.item.input_audio_transcription.completed（最终结果）
```

### 实时转写结果解析

```dart
case 'conversation.item.input_audio_transcription.text':
  // text: 完整转写文本（包含所有历史句子）
  // stash: 当前正在识别的句子片段
  final fullText = data['text'] as String? ?? '';
  final stash = data['stash'] as String? ?? '';
  
  if (fullText.isNotEmpty) {
    // 使用 fullText 显示完整文本
    controller.add(RealtimeTranscriptionResult(
      text: fullText,
      isFinal: false,
    ));
  }
  break;
```

---

## 常见错误对照表

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| `HTTP status code: 404` | WebSocket 端点 URL 错误 | 使用正确的端点 `wss://dashscope.aliyuncs.com/api-ws/v1/realtime` |
| `HTTP status code: 401` | 认证失败 | 检查 Authorization header 格式是否为 `bearer apiKey` |
| `WebSocket connection failed` | 网络问题 | 检查网络连接 |
| `task-failed` | 参数错误 | 检查 run-task 消息格式 |
| `Empty transcription result` | 音频格式不正确 | 确保发送 PCM 格式 |
| `The input messages do not contain elements with the role of user` | 错误发送了 conversation.item.create | **不要发送 conversation.item.create**，直接发送音频即可 |
| `Audio buffer is empty` | 发送了 response.create 但没有音频 | **不要发送 response.create**，音频会自动处理 |

---

## 修改历史

| 日期 | 修改内容 | 结果 |
|-----|---------|------|
| 2026-05-17 | 初始版本 | 端点错误 |
| 2026-05-17 | 修正端点和认证方式 | 待测试 |
| 2026-05-18 | 添加成功经验：完整测试验证通过 | ✅ 成功 |
| 2026-05-18 | 更新消息格式：不需要 conversation.item.create 和 response.create | ✅ 成功 |

---

*本文档是 Qwen 实时转写 WebSocket API 调用的唯一权威参考，任何修改必须经过验证！*
