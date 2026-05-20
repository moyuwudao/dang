---
alwaysApply: false
description: API 调用红线规则 - API 调用时绝对不能违反的强制要求
---

# API_RED_LINES.md - API 调用红线

## 核心理念

API 调用红线是**绝对不能违反**的 API 操作规则。
违反这些规则会导致：密钥泄露、API 调用失败、调试效率低下。

> **通用安全红线** → 详见 [RED_LINES.md](RED_LINES.md)
>
> **API 设计规范** → 详见 [API_DESIGN.md](API_DESIGN.md)
>
> **API 测试规范** → 详见 [API_TESTING.md](API_TESTING.md)

---

## 🔴 构建前强制检查

| 检查项 | 说明 | 验证方式 |
|-------|------|---------|
| 1. 本地测试通过 | 必须先本地测试，再构建 APK | `dart run` 或单元测试 |
| 2. API Key 未硬编码 | 代码中无明文密钥 | 搜索代码确认 |
| 3. 使用正确端点 | URL 不混淆文件转写和实时转写 | 对照 API 规范文档 |
| 4. 日志不泄露密钥 | 日志中无 API Key/token | 检查日志输出 |
| 5. 必先读 API 规范 | API 修改前必须查看对应规范 | 确认已阅读 |

---

## ❌ 绝对禁止

| 禁止行为 | 后果 |
|---------|------|
| 跳过本地测试直接构建 APK | 反复构建调试，效率低下 |
| 硬编码 API Key | 密钥泄露，安全风险 |
| 混淆文件转写和实时转写端点 | API 调用失败（404/401） |
| 在日志中打印 API Key/token | 密钥泄露 |
| 使用 HTTP（非 HTTPS） | 数据明文传输 |
| 修改 API 代码后不读对应规范 | 格式错误，调用失败 |
| 混淆认证方式（header vs query） | 认证失败（401） |

---

## ✅ 强制流程

```
API 代码修改
  ↓
1. 阅读对应 API 规范文档
   - 文件转写 → QWEN_ASR_API.md
   - 实时转写 → QWEN_REALTIME_ASR_API.md
  ↓
2. 本地测试验证
   - 使用 dart run 运行测试脚本
   - 或编写单元测试
  ↓
3. 确认测试通过
   - 检查响应格式正确
   - 检查无密钥泄露到日志
  ↓
4. 如有需要，构建 APK
   - 遵循 BUILD.md 构建流程
  ↓
完成
```

---

## 🔑 密钥安全红线

### 绝对不能做
- ❌ 在 `lib/` 代码中硬编码 API Key
- ❌ 在 `print()`/`debugPrint()` 中打印 API Key
- ❌ 在异常信息中包含 API Key
- ❌ 将密钥提交到 Git

### 正确做法
- ✅ API Key 通过环境变量或配置界面输入
- ✅ 运行时从安全存储读取
- ✅ 日志中使用脱敏显示：`sk-xxx...xxx`

---

## 🔗 端点红线

### 绝对不能混淆的端点

| 功能 | 正确端点 | 错误端点（禁止使用） |
|------|---------|-------------------|
| 文件转写 | `https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions` | `/api/v1/services/audio/asr/transcription` |
| 实时转写 | `wss://dashscope.aliyuncs.com/api-ws/v1/realtime` | `/compatible-mode/v1/realtime` |

### 绝对不能混淆的认证方式

| 功能 | 正确认证 | 错误认证 |
|------|---------|---------|
| 文件转写 | HTTP Header: `Authorization: Bearer sk-xxx` | URL Query 参数 |
| 实时转写 | WebSocket Header: `Authorization: bearer sk-xxx` | URL Query 参数 |

---

## 📋 常见 API 错误一览

| 错误类型 | 典型错误码/信息 | 参考案例 |
|---------|--------------|---------|
| URL 错误 | `url error, please check url` | [CASE-006](API_TROUBLESHOOTING.md#case-006) |
| 请求格式错误 | `The provided URL does not appear to be valid` | [CASE-008](API_TROUBLESHOOTING.md#case-008) |
| type 值错误 | `Input should be 'text', 'image', 'audio'` | [CASE-009](API_TROUBLESHOOTING.md#case-009) |
| audio 格式错误 | `Input should be a valid string` | [CASE-010](API_TROUBLESHOOTING.md#case-010) |
| WebSocket 404 | `HTTP status code: 404` | [CASE-015](API_TROUBLESHOOTING.md#case-015) |
| 认证 401 | `HTTP status code: 401` | [CASE-017](API_TROUBLESHOOTING.md#case-017) |

---

## 更新记录

| 日期 | 更新内容 |
|-----|---------|
| 2026-05-19 | 方案C新增：从实际案例中提炼 API 调用红线 |