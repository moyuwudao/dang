---
alwaysApply: false
description: 通义听悟离线转写方案 - 基于TOS转存的实现架构
---

# 通义听悟离线转写方案

## 概述

本文档定义通义听悟（Tingwu）离线转写的实现方案，解决**本地录音文件如何提交给通义听悟进行离线转写**的问题。

**核心约束**：原则上不建立服务器中转，如需可以通过 TOS（对象存储）转存。

---

## 方案对比

### 方案 A：阿里云 OSS/TOS 直传（推荐）

**流程**：
```
App 录音文件
  ↓
1. 上传至阿里云 OSS/TOS（App 直传）
   - 使用阿里云 STS 临时凭证
   - 或预签名 URL 上传
  ↓
2. 获取文件公网 URL
  ↓
3. 调用通义听悟 CreateTask API
   PUT /openapi/tingwu/v2/tasks?type=offline
   Body: { "Input": { "FileUrl": "https://xxx.oss-cn-beijing.aliyuncs.com/xxx.wav" } }
  ↓
4. 轮询 QueryTask 等待完成
  ↓
5. 下载转写结果（JSON）
```

**优点**：
- 无需自建服务器
- 阿里云生态内网传输，速度快
- 安全性高（STS 临时凭证）
- 成本低（OSS 存储 + 听悟调用）

**缺点**：
- 需要配置 OSS/TOS 存储桶
- 需要处理 STS 凭证刷新

**适用场景**：✅ 推荐，符合"不建服务器"原则

---

### 方案 B：自建服务器中转（不推荐）

**流程**：
```
App 录音文件
  ↓
1. 上传至自建服务器
  ↓
2. 服务器转发到通义听悟
  ↓
3. 服务器轮询结果
  ↓
4. 返回给 App
```

**优点**：
- 可以隐藏阿里云凭证
- 可以做更多后端处理

**缺点**：
- 需要维护服务器
- 带宽成本
- 单点故障

**适用场景**：❌ 不符合"不建服务器"原则，仅在需要复杂后端处理时考虑

---

### 方案 C：DashScope 文件上传（已验证）

**流程**：
```
App 录音文件
  ↓
1. Base64 编码上传至 DashScope 文件服务
   POST https://dashscope.aliyuncs.com/api/v1/files
   Body: { "model": "qwen3-asr-flash-filetrans", "file": "data:audio/wav;base64,xxx" }
  ↓
2. 获取 file_url
  ↓
3. 提交异步转写任务
   POST https://dashscope.aliyuncs.com/api/v1/services/audio/asr/transcription
   Body: { "input": { "file_url": "xxx" } }
  ↓
4. 轮询任务状态
   GET https://dashscope.aliyuncs.com/api/v1/tasks/{task_id}
```

**优点**：
- 已有完整实现（见 transcription_service.dart）
- 使用 Bearer Token 认证，简单
- 支持大文件（通过 filetrans 模型）

**缺点**：
- 这是 Qwen ASR，不是通义听悟
- 不支持说话人分离、摘要等高级功能

**适用场景**：普通转写，不需要会议纪要功能

---

## 推荐方案：方案 A（OSS 直传 + 听悟离线）

### 架构图

```
┌─────────────┐         ┌──────────────┐         ┌──────────────┐
│   App       │ ──────→ │ 阿里云 OSS   │ ──────→ │ 通义听悟 API │
│ (录音文件)   │  直传   │ (临时存储)   │  FileUrl │ (离线转写)   │
└─────────────┘         └──────────────┘         └──────────────┘
       ↑                                              │
       │                                              ↓
       │                                       ┌──────────────┐
       └───────────────────────────────────────│ 转写结果 JSON │
              轮询查询 / 下载结果                │ (含说话人分离)│
                                               └──────────────┘
```

### 实现步骤

#### 1. 阿里云 OSS 配置

**需要的阿里云资源**：
- OSS Bucket（存储桶）
- RAM 用户（用于生成 STS 临时凭证）
- RAM 角色（授权 OSS 访问权限）

**权限策略**（RAM 角色）：
```json
{
  "Version": "1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "oss:PutObject",
        "oss:GetObject"
      ],
      "Resource": [
        "acs:oss:*:*:your-bucket/recordings/*"
      ]
    }
  ]
}
```

#### 2. App 端实现

**A. 获取 STS 临时凭证**

```dart
// 方式 1：App 直接调用阿里云 STS API（需要 AccessKey）
// 方式 2：通过你的后端服务获取（更安全，但需要服务器）
// 方式 3：使用长期有效的 AccessKey（简单但安全性较低）

// 推荐方式 1 的简化版：在 App 中配置 AccessKey，直接调用 STS
// 注意：AccessKey 应存储在 flutter_secure_storage 中
```

**B. 上传文件到 OSS**

```dart
import 'package:aliyun_oss_flutter/aliyun_oss_flutter.dart';

// 初始化 OSS 客户端
final ossClient = AliyunOssClient(
  accessKeyId: stsCredentials.accessKeyId,
  accessKeySecret: stsCredentials.accessKeySecret,
  securityToken: stsCredentials.securityToken,
  endpoint: 'oss-cn-beijing.aliyuncs.com',
  bucketName: 'your-bucket',
);

// 上传文件
final objectKey = 'recordings/${DateTime.now().millisecondsSinceEpoch}.wav';
final result = await ossClient.putObject(
  objectKey: objectKey,
  filePath: audioFilePath,
);

// 获取公网 URL（带过期时间）
final fileUrl = ossClient.getSignedUrl(objectKey, expireSeconds: 3600);
```

**C. 提交听悟离线任务**

```dart
// 使用现有的 tingwu_service.dart
final taskId = await tingwuService.submitTask(
  fileUrl: fileUrl,
  enableDiarization: true,      // 说话人分离
  enableSummarization: true,    // 全文摘要
  enableTodo: true,             // 待办提取
  enableKeywords: true,         // 关键词提取
);

// 等待完成
final result = await tingwuService.waitForResult(taskId);
```

#### 3. 结果解析

**转写结果结构**：
```json
{
  "TaskId": "xxx",
  "TaskStatus": "SUCCESS",
  "Result": {
    "Transcription": {
      "Segments": [
        {
          "SpeakerId": 1,
          "Text": "今天我们要讨论一下项目进度",
          "StartTime": 0,
          "EndTime": 5000
        }
      ]
    },
    "Summarization": {
      "Results": [
        { "Type": "Paragraph", "Content": "会议讨论了项目进度..." },
        { "Type": "Conversational", "Content": "对话式摘要..." },
        { "Type": "QuestionsAnswering", "Content": "问答摘要..." },
        { "Type": "Chapter", "Content": "章节速览..." }
      ]
    },
    "MeetingAssistance": {
      "Results": [
        { "Type": "Actions", "Content": "待办事项列表..." },
        { "Type": "KeyInformation", "Content": "关键信息..." }
      ]
    }
  }
}
```

---

## 替代方案：预签名 URL 上传

如果不使用 STS，可以使用**预签名 URL**方式：

### 流程

```
1. 你在阿里云控制台或本地生成预签名 URL
   （需要 AccessKey Secret，不能在 App 中做）

2. 将预签名 URL 配置到 App 中

3. App 使用 PUT 请求直接上传文件到该 URL

4. 获取文件 URL 提交给听悟
```

### 局限性

- 预签名 URL 有有效期限制
- 需要定期更新 URL
- 不如 STS 灵活

---

## 安全考虑

### 凭证管理

| 方案 | 安全性 | 复杂度 | 推荐度 |
|-----|-------|-------|-------|
| App 内嵌 AccessKey | 低 | 低 | ❌ 不推荐 |
| STS 临时凭证 | 高 | 中 | ✅ 推荐 |
| 后端代理获取 STS | 最高 | 高 | ✅ 最佳（需要服务器）|

### 文件访问控制

- OSS Bucket 设置为**私有**
- 使用**签名 URL**访问文件
- 文件上传后设置**自动过期删除**（如 7 天后删除）

---

## 成本估算

| 项目 | 费用 | 说明 |
|-----|------|------|
| OSS 存储 | ~0.12元/GB/月 | 标准存储 |
| OSS 流量 | ~0.50元/GB | 外网流出 |
| 听悟转写 | ~0.50元/小时 | 按音频时长计费 |
| STS 调用 | 免费 | |

**示例**：1 小时录音
- 存储：~10MB，约 0.001 元
- 流量：~10MB，约 0.005 元
- 转写：1 小时，约 0.50 元
- **总计：约 0.51 元/小时录音**

---

## 实现优先级

### 第一阶段：最小可行方案（MVP）

1. 在 App 中配置阿里云 AccessKey（短期方案）
2. 使用 OSS SDK 上传文件
3. 调用听悟离线转写
4. 解析并展示结果

### 第二阶段：安全优化

1. 实现 STS 临时凭证获取
2. 凭证自动刷新机制
3. 文件自动清理

### 第三阶段：体验优化

1. 上传进度显示
2. 转写进度实时推送
3. 结果缓存

---

## 相关代码文件

| 文件 | 说明 |
|-----|------|
| [tingwu_service.dart](file:///d:\trae_projects\dang\lib\core\services\tingwu_service.dart) | 通义听悟服务（已有离线任务提交、查询、等待） |
| [transcription_service.dart](file:///d:\trae_projects\dang\lib\core\services\transcription_service.dart) | 转写服务（已有 transcribeTingwu 方法） |
| [http_client.dart](file:///d:\trae_projects\dang\lib\core\services\http_client.dart) | HTTP 客户端（已配置 AccessKey/Secret/AppKey） |

---

## 更新记录

| 日期 | 更新内容 |
|-----|---------|
| 2026-05-21 | 初始版本 - 定义通义听悟离线转写方案，推荐 OSS 直传 |
