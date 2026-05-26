---
alwaysApply: false
description: 通义听悟实时转写实现方案 - 记录技术实现细节和踩坑经验
---

# 通义听悟实时转写实现方案

## 概述

本文档记录通义听悟（Tingwu）实时转写的完整实现方案，包括技术选型、实现细节、遇到的问题及解决方案。

**重要结论**：通义听悟实时转写效果不如通义千问（Qwen）实时转写，建议：
- **实时转写**：使用通义千问（效果好、速度快、支持流式中间结果）
- **离线转写**：使用通义听悟（支持说话人分离、摘要、待办提取等高级功能）

---

## 技术架构

### 1. 实时转写流程

```
用户录音
  ↓
1. 创建实时会议（CreateTask API）
   PUT /openapi/tingwu/v2/tasks?type=realtime
   返回：MeetingId, MeetingJoinUrl(WebSocket地址), Token
  ↓
2. 连接 WebSocket
   wss://tingwu-realtime-cn-beijing.aliyuncs.com/api/ws/v1?mc=...
   Headers: Authorization: Bearer {Token}
  ↓
3. 发送 StartTranscription 指令（NLS协议）
   {
     "header": {
       "appkey": "{AppKey}",
       "message_id": "{32位十六进制UUID}",
       "task_id": "{32位十六进制UUID}",
       "namespace": "SpeechTranscriber",
       "name": "StartTranscription"
     },
     "payload": {
       "format": "pcm",
       "sample_rate": 16000,
       "enable_intermediate_result": true,
       "enable_punctuation_prediction": true,
       "enable_inverse_text_normalization": true
     }
   }
  ↓
4. 发送音频数据（二进制帧）
   直接发送 PCM 数据，无需 WAV 头部
  ↓
5. 接收转写结果
   - TranscriptionStarted: 转写开始
   - SentenceBegin: 句子开始
   - TranscriptionResultChanged: 中间结果（如启用）
   - SentenceEnd: 句子结束（包含最终文本）
   - TranscriptionCompleted: 转写完成
  ↓
6. 发送 StopTranscription 指令结束
```

### 2. 认证方式

**阿里云 V2 ROA 签名**（创建会议时使用）：
- AccessKey ID + AccessKey Secret
- HMAC-SHA1 签名算法
- 需要设置 x-acs-* 系列头部

**Token 认证**（WebSocket 连接时使用）：
- 从 CreateTask 返回的 Token
- 通过 Authorization: Bearer {Token} 头部传递

---

## 关键实现细节

### 1. 签名算法（V2 ROA）

```dart
String signRequest(String method, String path, {String? body, Map<String, String>? queryParams}) {
  final now = getGmtTime();
  final nonce = generateNonce();
  final contentType = 'application/json';
  final contentMd5 = body != null ? base64Encode(md5(body)) : '';
  
  // 签名字符串格式：
  // {Method}\n{Content-Type}\n{Content-MD5}\n{Content-Type}\n{Date}\n{CanonicalizedHeaders}{CanonicalizedResource}
  // 注意：GET 请求时第四个字段（Content-Type）为空
  
  final stringToSign = body != null
      ? '$method\n$contentType\n$contentMd5\n$contentType\n$now\n$canonicalizedHeaders$canonicalizedResource'
      : '$method\n$contentType\n$contentMd5\n\n$now\n$canonicalizedHeaders$canonicalizedResource';
  
  final signature = base64Encode(hmacSha1(accessKeySecret, stringToSign));
  return 'acs $accessKeyId:$signature';
}
```

### 2. ID 生成规则

**task_id 和 message_id**：
- 格式：32 位十六进制字符串（不含连字符）
- 错误示例：`a3b9d01f-9370-4d97-bc37-c54b16ea150f`（含连字符，会报 Invalid task id）
- 正确示例：`802738f37fb24459bbe7b241210e19b8`
- 生成方式：`Uuid().v4().replaceAll('-', '')`

### 3. 音频数据格式

**录音配置**：
```dart
RecordConfig(
  encoder: AudioEncoder.pcm16bits,
  sampleRate: 16000,
  numChannels: 1,
  autoGain: true,
  echoCancel: true,
  noiseSuppress: true,
)
```

**重要**：`record` 插件的 `startStream` 返回的是 **裸 PCM 数据**，不需要跳过 WAV 头部。

**发送方式**：
```dart
// 直接发送二进制帧
channel.sink.add(Uint8List.fromList(chunk));
```

### 4. WebSocket 消息处理

**事件类型**：
| 事件名 | 说明 | 是否包含文本 |
|-------|------|------------|
| TranscriptionStarted | 转写开始 | 否 |
| SentenceBegin | 句子开始 | 否 |
| TranscriptionResultChanged | 中间结果 | 是（payload.result） |
| SentenceEnd | 句子结束 | 是（payload.result） |
| TranscriptionCompleted | 转写完成 | 否 |
| TaskFailed | 任务失败 | 否（header.status_text） |

**心跳机制**：
- 不需要手动发送心跳包
- `web_socket_channel` 库会自动处理 WebSocket ping-pong
- 不要发送空数据（`Uint8List(0)`），会被当作音频帧导致 `Audio frame is null` 错误

---

## 遇到的问题及解决方案

### 问题 1：401 未授权

**原因**：使用了错误的认证方式（Bearer token）
**解决**：创建会议时使用阿里云 V2 ROA 签名，WebSocket 连接时使用返回的 Token

### 问题 2：404 API 不存在

**原因**：使用了旧的 API 路径 `/openapi/meeting-trans`
**解决**：改用新版 API 路径 `PUT /openapi/tingwu/v2/tasks?type=realtime`

### 问题 3：Invalid task id

**原因**：task_id 格式不对（含连字符或大写字母）
**解决**：使用 32 位小写十六进制字符串，不含连字符

### 问题 4：Audio frame is null

**原因**：发送了空的音频帧（`Uint8List(0)`）作为心跳包
**解决**：移除自定义心跳包，让 WebSocket 库自动处理 ping-pong

### 问题 5：IDLE_TIMEOUT

**原因**：音频数据被缓冲，发送延迟超过 10 秒
**解决**：直接发送音频数据，不要缓冲和检测 WAV 头部

### 问题 6：输出不及时、文字质量差

**原因**：通义听悟实时转写本身的设计限制
- 只在句子结束时返回结果（非流式）
- 识别准确率不如千问
**解决**：实时转写改用通义千问，通义听悟仅用于离线转写

---

## 代码文件

### 核心实现文件

| 文件 | 说明 |
|-----|------|
| [tingwu_service.dart](file:///d:\trae_projects\dang\lib\core\services\tingwu_service.dart) | 创建会议、离线转写任务 |
| [realtime_transcription_service.dart](file:///d:\trae_projects\dang\lib\core\services\realtime_transcription_service.dart) | 实时转写 WebSocket 连接 |
| [recording_service.dart](file:///d:\trae_projects\dang\lib\core\services\recording_service.dart) | 音频录制 |

### 关键类

```dart
// 会议信息
class TingwuMeetingInfo {
  final String meetingId;      // 会议 ID
  final String wsUrl;          // WebSocket 地址（MeetingJoinUrl）
  final String token;          // 认证 Token
  final String? realtimeDataId; // 实时数据 ID
}
```

---

## 配置参数

### API 配置

| 参数 | 说明 | 示例 |
|-----|------|------|
| AccessKey ID | 阿里云访问密钥 ID | \${ALIBABA_CLOUD_ACCESS_KEY_ID} |
| AccessKey Secret | 阿里云访问密钥 Secret | \${ALIBABA_CLOUD_ACCESS_KEY_SECRET} |
| AppKey | 通义听悟应用密钥 | UFtTh4CAQxxhNdEC |

### 实时转写参数

| 参数 | 说明 | 默认值 |
|-----|------|-------|
| format | 音频格式 | pcm |
| sample_rate | 采样率 | 16000 |
| enable_intermediate_result | 启用中间结果 | true |
| enable_punctuation_prediction | 启用标点预测 | true |
| enable_inverse_text_normalization | 启用逆文本规范化 | true |
| disfluency_removal | 去除语气词 | true |

---

## 更新记录

| 日期 | 更新内容 |
|-----|---------|
| 2026-05-21 | 初始版本 - 记录通义听悟实时转写完整实现方案 |
