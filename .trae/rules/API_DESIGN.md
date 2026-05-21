---
alwaysApply: false
globs: lib/**/api/**, lib/**/service/**, lib/**/repository/**
description: API 调用规范总纲 - 定义 API 文档索引和设计原则
---

# API 调用规范总纲

## 概述

本文档是 API 调用规范的**一级规则**，定义了不同 API 服务应参考的文档资源和整体设计原则。

---

## 两级规范体系

| 级别 | 作用 | 命名规范 |
|------|------|---------|
| **一级** | API 调用总纲、文档索引、设计原则 | `API_*.md` |
| **二级** | 具体 API 服务的详细规范、参数、错误处理 | `<API_NAME>_*.md` |

---

## API 文档索引

### 语音转写（ASR）

| API 服务 | Provider | 二级规范文档 | 状态 |
|---------|----------|------------|------|
| **阿里云通义千问** | `qwen` | [QWEN_ASR_API.md](QWEN_ASR_API.md) | ✅ 可用 |
| OpenAI Whisper | `openAI` | 待补充 | ⏳ 规划中 |
| 其他 ASR 服务 | - | 待补充 | ⏳ 规划中 |

### 实时转写（Realtime ASR）

| API 服务 | Provider | 二级规范文档 | 状态 |
|---------|----------|------------|------|
| **阿里云通义千问** | `qwen` | [QWEN_REALTIME_ASR_API.md](QWEN_REALTIME_ASR_API.md) | ✅ 可用 |
| 讯飞星火 | `spark` | 待补充 | ⏳ 规划中 |

### AI 对话

| API 服务 | Provider | 二级规范文档 | 状态 |
|---------|----------|------------|------|
| **阿里云通义千问** | `qwen` | [QWEN_CHAT_API.md](QWEN_CHAT_API.md) | ✅ 已有实现（无需创建） |
| OpenAI | `openAI` | 待补充 | ⏳ 规划中 |
| Claude | `claude` | 待补充 | ⏳ 规划中 |
| Gemini | `gemini` | 待补充 | ⏳ 规划中 |
| DeepSeek | `deepSeek` | 待补充 | ⏳ 规划中 |
| 智谱 GLM | `zhipu` | 待补充 | ⏳ 规划中 |
| Kimi | `kimi` | 待补充 | ⏳ 规划中 |
| 百度文心 | `ernie` | 待补充 | ⏳ 规划中 |
| 讯飞星火 | `spark` | 待补充 | ⏳ 规划中 |
| Grok | `grok` | 待补充 | ⏳ 规划中 |

### 其他服务

| API 服务 | Provider | 二级规范文档 | 状态 |
|---------|----------|------------|------|
| 文件存储 | - | 待补充 | ⏳ 规划中 |
| 用户认证 | - | 待补充 | ⏳ 规划中 |

---

## 现有 Provider 配置

项目已在 `lib/core/models/ai_model_config.dart` 中配置以下 Provider：

```dart
enum AiProvider {
  openAI,   // OpenAI GPT 系列
  claude,   // Anthropic Claude
  gemini,   // Google Gemini
  deepSeek, // DeepSeek
  qwen,     // 阿里云通义千问
  ernie,    // 百度文心一言
  zhipu,    // 智谱 GLM
  kimi,     // 月之暗面 Kimi
  spark,    // 讯飞星火
  grok,     // xAI Grok
  custom,   // 自定义 API
}
```

---

## 二级规范文档模板

新增 API 规范时，应创建独立的文档文件，包含以下章节：

```markdown
# <API 服务名称> <功能> 规范

## 概述
API 功能、版本、基础信息

## API 信息
- 端点 URL
- 认证方式
- 请求限制

## 请求格式
- 请求头
- 请求体结构
- 必填参数
- 可选参数

## 响应格式
- 成功响应
- 错误响应
- 解析代码

## 关键格式要求
- 格式要点 1
- 格式要点 2

## 错误处理
- 错误码对照表
- 重试策略

## 案例集锦
- 成功案例
- 失败案例及修复

## 修改记录
```

---

## 新增 API 规范流程

1. **确认需求**：确定要支持的 API 服务和使用场景
2. **查阅官方文档**：获取 API 规范、参数、限制
3. **创建二级文档**：按照模板创建 `<API_NAME>_*.md`
4. **更新索引**：在本文档中添加新 API 条目
5. **代码实现**：按照规范实现调用代码
6. **验证测试**：确保调用成功并记录案例

---

## API 设计原则

### 1. 错误处理原则

- 所有 API 调用必须捕获异常
- 记录完整的错误信息（状态码、错误消息、请求 ID）
- 根据错误类型决定是否重试

### 2. 日志记录原则

- 记录请求开始和结束
- 记录关键参数（URL、模型、文件大小）
- 记录响应状态和耗时
- **禁止记录**：API Key、完整音频数据

### 3. 安全性原则

- API Key 必须通过安全方式存储（环境变量或 flutter_secure_storage）
- 禁止在日志中暴露敏感信息
- 使用 HTTPS 进行所有 API 调用

### 4. 可扩展性原则

- 将不同 API 提供商封装为可替换的实现
- 使用接口/抽象类定义统一调用方式
- 便于后续添加新的 API 服务

---

## 代码架构参考

### HttpClient 配置 (`lib/core/services/http_client.dart`)

```dart
class HttpClient {
  // 配置不同 Provider 的请求头
  Map<String, String> _buildHeaders(AiModelConfig config, String apiKey) {
    switch (config.provider) {
      case AiProvider.openAI:
      case AiProvider.deepSeek:
      case AiProvider.qwen:
        // 使用 Bearer Token 认证
        return {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        };
      case AiProvider.claude:
        // 使用 x-api-key 认证
        return {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        };
      case AiProvider.gemini:
        // Gemini 使用特殊认证
        return { 'Content-Type': 'application/json' };
    }
  }
}
```

### 转写服务 (`lib/core/services/transcription_service.dart`

```dart
/// Qwen ASR API 调用
/// 参考: .trae/rules/QWEN_ASR_API.md
Future<String> _transcribeQwenAsrBytes(...) async {
  // OpenAI 兼容格式
  // URL: https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions
}
```

### 文本分析服务 (`lib/core/services/text_analysis_service.dart`

Qwen Chat API 使用 OpenAI 兼容格式，已有完整实现：

```dart
/// Qwen Chat API 调用（OpenAI 兼容格式
/// 参考: .trae/rules/QWEN_ASR_API.md（格式与 ASR 类似）
Future<String> _openAIStyleChat(...) async {
  // 使用 standard OpenAI chat format
  // Qwen 支持该格式
  // URL: https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions
  // 状态: ✅ 已验证可用
}
```

---

## 典型问题案例

已在 [BUILD_TROUBLESHOOTING.md](BUILD_TROUBLESHOOTING.md) 中记录：

| 编号 | 问题 | 涉及 API |
|-----|------|---------|
| CASE-006 ~ CASE-010 | Qwen ASR 调用格式错误 | qwen ASR |
| CASE-011 ~ CASE-013 | Qwen 实时转写 WebSocket 错误 | qwen 实时转写 |

---

## 修改记录

| 日期 | 修改内容 |
|-----|---------|
| 2026-05-16 | 初始版本，建立两级规范体系 |
| 2026-05-17 | 更新 Qwen Chat API 标记为已有实现 |
| 2026-05-17 | 添加 Qwen 实时转写 API 索引和文档 |

---

*本文档是 API 规范的一级入口，添加新 API 时必须更新本文档的索引。*
