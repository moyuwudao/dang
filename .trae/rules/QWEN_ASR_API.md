---
alwaysApply: false
globs: lib/**/asr/**, lib/**/transcription/**
description: 阿里云通义千问 ASR API 详细调用规范 - 严禁随意修改
---

# Qwen ASR API 调用规范

## 概述

本文档记录阿里云通义千问 ASR API（qwen3-asr-flash）的正确调用方式，**严禁随意修改**。

---

## API 信息

| 项目 | 值 |
|------|-----|
| **模型** | `qwen3-asr-flash` |
| **端点** | OpenAI 兼容模式 |
| **URL** | `https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions` |
| **认证** | `Authorization: Bearer <API_KEY>` |

---

## 请求格式

### 完整请求示例

```dart
final dio = Dio(
  BaseOptions(
    baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 60),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
  ),
);

final response = await dio.post(
  '/chat/completions',
  data: {
    'model': 'qwen3-asr-flash',
    'messages': [
      {
        'role': 'user',
        'content': [
          {
            'type': 'audio',
            'audio': 'data:audio/wav;base64,$base64Audio',
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
  },
);
```

### 请求体结构

```json
{
  "model": "qwen3-asr-flash",
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "audio",
          "audio": "data:audio/wav;base64,<BASE64_AUDIO_DATA>"
        }
      ]
    }
  ],
  "extra_body": {
    "asr_options": {
      "enable_itn": true,
      "language": "auto"
    }
  }
}
```

---

## 关键格式要求

### 1. URL 必须使用 OpenAI 兼容模式

| ✅ 正确 | ❌ 错误 |
|--------|--------|
| `https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions` | `https://dashscope.aliyuncs.com/api/v1/services/audio/asr/transcription` |

### 2. content 结构

```dart
// ✅ 正确
'content': [
  {
    'type': 'audio',
    'audio': 'data:audio/wav;base64,$base64Audio',
  }
]

// ❌ 错误：type 不能是 'audio_url'
'content': [
  {
    'type': 'audio_url',
    'audio_url': { 'url': '...' }
  }
]

// ❌ 错误：audio 不能是对象
'content': [
  {
    'type': 'audio',
    'audio': { 'data': '...', 'format': 'wav' }
  }
]
```

### 3. asr_options 必须放在 extra_body 中

```dart
// ✅ 正确
{
  'model': 'qwen3-asr-flash',
  'messages': [...],
  'extra_body': {
    'asr_options': {
      'enable_itn': true,
      'language': 'auto',
    },
  },
}

// ❌ 错误：asr_options 不能放在根级别
{
  'model': 'qwen3-asr-flash',
  'messages': [...],
  'asr_options': {
    'enable_itn': true,
    'language': 'auto',
  },
}
```

### 4. audio 必须是 data URI 字符串

```dart
// ✅ 正确
'audio': 'data:audio/wav;base64,$base64Audio'

// ❌ 错误：不能是对象
'audio': {
  'data': base64Audio,
  'format': 'wav',
}
```

---

## 响应格式

### 成功响应结构

```json
{
  "id": "chatcmpl-xxx",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "qwen3-asr-flash",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "转写的文本内容"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 0,
    "completion_tokens": 0,
    "total_tokens": 0
  }
}
```

### 解析代码

```dart
String text = '';
if (response.data is Map) {
  final data = response.data as Map;
  if (data.containsKey('choices') && (data['choices'] as List?)?.isNotEmpty == true) {
    final choices = data['choices'] as List;
    final firstChoice = choices[0] as Map;
    if (firstChoice.containsKey('message') && firstChoice['message'] is Map) {
      final message = firstChoice['message'] as Map;
      text = message['content'] ?? '';
    }
  }
}
```

---

## 完整代码参考

文件位置：`lib/core/services/transcription_service.dart`

方法：`_transcribeQwenAsrBytes`

**⚠️ 修改此方法前，必须先阅读本文档并确保格式正确！**

---

## 常见错误对照表

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| `url error, please check url` | URL 格式错误 | 使用 OpenAI 兼容端点 |
| `The provided URL does not appear to be valid` | 请求体格式错误 | 检查 content 结构 |
| `Input should be 'text', 'image', 'audio'` | type 值错误 | 使用 `type: 'audio'` |
| `Input should be a valid string` | audio 字段格式错误 | 使用 data URI 字符串 |

---

## 修改历史

| 日期 | 修改内容 | 结果 |
|-----|---------|------|
| 2026-05-16 | 初始版本，记录正确调用方式 | ✅ 转写成功 |

---

*本文档是 Qwen ASR API 调用的唯一权威参考，任何修改必须经过验证！*
