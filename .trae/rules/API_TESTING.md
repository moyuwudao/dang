---
alwaysApply: false
globs: lib/**/api/**, test/**/api/**
description: API 测试规范 - 本地测试优先原则，确保 API 集成前验证通过
---

# API 测试规范

## 核心理念

**先本地测试，再构建 APK。**

任何 API 集成（尤其是 WebSocket、实时流等复杂 API）必须在本地验证通过后，才能构建 APK 进行真机测试。

---

## 测试流程

### 标准流程

```
┌─────────────────────────────────────────────────────────┐
│  1. 本地测试（Node.js/Python 脚本）                      │
│     - 验证 API 连接                                       │
│     - 验证认证方式                                        │
│     - 验证请求/响应格式                                   │
│     - 验证数据解析                                        │
└─────────────────────────────────────────────────────────┘
                            ↓
                    【测试通过？】
                            ↓
                    ┌───────┴───────┐
                    ↓               ↓
                  是               否
                    ↓               ↓
┌─────────────────────────┐   ┌─────────────────────────┐
│  2. 修复问题并重新测试    │   │  2. 调试并修复问题        │
│  - 修改 Dart 代码        │   │  - 查看错误日志           │
│  - 同步到 WSL            │   │  - 对比文档和实际行为      │
│  - 构建 APK              │   │  - 调整参数/格式          │
│  - 真机测试              │   │  - 重新本地测试           │
└─────────────────────────┘   └─────────────────────────┘
```

### 为什么先本地测试？

| 问题 | 本地测试 | 直接构建 APK |
|-----|---------|-------------|
| 调试速度 | 秒级 | 分钟级（构建+安装） |
| 日志查看 | 直接输出到终端 | 需要连接日志工具 |
| 问题定位 | 快速定位 API 问题 | 难以区分是 API 问题还是 APP 问题 |
| 迭代成本 | 低 | 高（每次都要构建） |
| 网络环境 | 可控 | 受移动网络影响 |

---

## 测试工具

### 推荐工具

| 工具 | 适用场景 | 优点 |
|-----|---------|------|
| **Node.js + ws** | WebSocket API | 快速、易调试、JSON 处理方便 |
| **Python + websockets** | WebSocket API | 简洁、适合数据流处理 |
| **curl** | REST API | 简单、无需安装 |
| **Postman** | REST API | 图形界面、易于分享 |

### 项目内置测试脚本

项目已提供以下测试脚本：

```
dang/
├── test_websocket.js          # Node.js WebSocket 测试（OpenAI 协议）
├── test_websocket_qwen.js     # Node.js WebSocket 测试（Qwen 协议）
└── test_websocket_openai.js   # Node.js WebSocket 测试（简化版）
```

**使用方式**：
```bash
# 安装依赖
npm install ws

# 运行测试
node test_websocket_openai.js
```

---

## 测试检查清单

### WebSocket API 测试

- [ ] **连接测试**
  - [ ] WebSocket URL 是否正确（wss:// 而非 https://）
  - [ ] 端点路径是否正确
  - [ ] 认证方式是否正确（Headers vs Query 参数）

- [ ] **握手测试**
  - [ ] 是否能收到 `session.created`
  - [ ] `session.update` 是否能收到 `session.updated`
  - [ ] 参数格式是否正确

- [ ] **数据传输测试**
  - [ ] 音频数据格式是否正确（PCM 16kHz 16bit mono）
  - [ ] 数据块大小是否正确（640 bytes / 20ms）
  - [ ] 发送频率是否正确（每 20ms 一块）

- [ ] **结果接收测试**
  - [ ] 是否能收到实时转写结果
  - [ ] 结果格式是否正确
  - [ ] 完整文本和增量文本是否区分正确

- [ ] **错误处理测试**
  - [ ] 网络中断时 behavior
  - [ ] 错误响应格式
  - [ ] 超时处理

### REST API 测试

- [ ] **请求测试**
  - [ ] URL 是否正确
  - [ ] HTTP 方法是否正确
  - [ ] Headers 是否完整
  - [ ] 请求体格式是否正确

- [ ] **响应测试**
  - [ ] HTTP 状态码是否正确
  - [ ] 响应体格式是否正确
  - [ ] 错误响应处理

---

## 测试脚本模板

### WebSocket 测试脚本模板

```javascript
const WebSocket = require('ws');
const fs = require('fs');

const API_KEY = "your-api-key";
const WS_URL = "wss://api.example.com/realtime";
const AUDIO_FILE = "path/to/audio.wav";

function readWavFile(filePath) {
    const buffer = fs.readFileSync(filePath);
    return buffer.slice(44); // Skip WAV header
}

async function testWebSocket() {
    console.log("=".repeat(60));
    console.log("WebSocket API 测试");
    console.log("=".repeat(60));
    
    const audioData = readWavFile(AUDIO_FILE);
    console.log(`音频数据大小: ${audioData.length} bytes`);
    
    const ws = new WebSocket(WS_URL, {
        headers: { "Authorization": `Bearer ${API_KEY}` }
    });
    
    return new Promise((resolve, reject) => {
        let sessionCreated = false;
        let transcript = "";
        
        ws.on('open', () => {
            console.log("✓ WebSocket 连接成功");
        });
        
        ws.on('message', (data) => {
            const message = JSON.parse(data.toString());
            console.log(`收到事件: ${message.type}`);
            
            switch (message.type) {
                case 'session.created':
                    console.log("✓ session.created");
                    sessionCreated = true;
                    // 发送 session.update
                    ws.send(JSON.stringify({
                        type: 'session.update',
                        session: { /* 参数 */ }
                    }));
                    break;
                    
                case 'session.updated':
                    console.log("✓ session.updated");
                    // 开始发送音频
                    sendAudio(ws, audioData);
                    break;
                    
                case 'result':
                    transcript += message.text || '';
                    console.log(`📝 转写: ${message.text}`);
                    break;
                    
                case 'error':
                    console.error(`❌ 错误: ${message.error}`);
                    reject(new Error(message.error));
                    break;
            }
        });
        
        ws.on('error', (error) => reject(error));
        ws.on('close', () => resolve(transcript));
        
        setTimeout(() => {
            if (!sessionCreated) {
                ws.close();
                reject(new Error('Timeout'));
            }
        }, 10000);
    });
}

function sendAudio(ws, audioData) {
    const chunkSize = 640;
    let index = 0;
    
    const interval = setInterval(() => {
        if (index >= audioData.length) {
            clearInterval(interval);
            console.log("✓ 音频发送完成");
            return;
        }
        
        const chunk = audioData.slice(index, index + chunkSize);
        ws.send(chunk.toString('base64'));
        index += chunkSize;
    }, 20);
}

testWebSocket()
    .then(result => {
        console.log("\n测试完成，转写结果:", result);
        process.exit(0);
    })
    .catch(error => {
        console.error("\n测试失败:", error.message);
        process.exit(1);
    });
```

---

## 成功案例：Qwen 实时转写测试

### 测试背景

**时间**：2026-05-18
**API**：Qwen 实时转写 WebSocket API
**问题**：APP 端实时转写无输出

### 测试过程

1. **第一轮测试**：使用错误的协议（Qwen 自定义协议）
   - 结果：服务器返回 `session.created`，但后续报错
   - 发现：端点实际支持 OpenAI Realtime API 协议

2. **第二轮测试**：使用 OpenAI 协议，但发送了 `conversation.item.create`
   - 结果：报错 `The input messages do not contain elements with the role of user`
   - 发现：不需要发送 `conversation.item.create`

3. **第三轮测试**：简化流程，只发送音频
   - 结果：✅ **成功！** 持续收到转写结果

### 关键发现

| 发现 | 说明 |
|-----|------|
**不需要 `conversation.item.create`** | 音频自动触发 VAD 检测和转写 |
**不需要 `response.create`** | 音频发送后自动处理 |
**使用 `text` 字段** | `text` 包含完整历史文本，`stash` 包含当前增量 |
**模型名称** | `qwen3-asr-flash-realtime` |

### 测试代码

详见项目文件：
- [test_websocket_openai.js](file:///d:/trae_projects/dang/test_websocket_openai.js)

---

## 常见错误

### 错误1：未进行本地测试直接构建 APK

**现象**：构建 APK 后发现 API 不工作，需要反复构建
**原因**：跳过了本地验证步骤
**解决**：严格按照"先本地测试，再构建 APK"流程

### 错误2：本地测试通过但 APP 端失败

**现象**：Node.js 测试成功，但 Flutter APP 失败
**原因**：Dart 代码实现与测试脚本不一致
**解决**：对比测试脚本和 Dart 代码，确保逻辑一致

### 错误3：测试数据与真实数据不一致

**现象**：使用测试音频成功，但真实录音失败
**原因**：音频格式、采样率等不一致
**解决**：使用真实录音文件进行测试

---

## 规则要求

### 强制要求

1. **任何 API 集成必须先本地测试**
   - WebSocket API：使用 Node.js/Python 脚本测试
   - REST API：使用 curl/Postman 测试

2. **本地测试通过标准**
   - 连接成功
   - 认证成功
   - 数据发送/接收正常
   - 结果解析正确

3. **测试通过后才能构建 APK**
   - 修改代码 → 本地测试 → 通过 → 构建 APK
   - 修改代码 → 本地测试 → 失败 → 修复 → 重新测试

### 推荐实践

1. **保存测试脚本**
   - 将测试脚本保存到项目目录
   - 命名规范：`test_<api_name>.js` 或 `test_<api_name>.py`

2. **记录测试结果**
   - 在 API 规范文档中记录测试结果
   - 更新 BUILD_TROUBLESHOOTING.md 添加案例

3. **使用真实数据测试**
   - 使用真实录音文件而非测试数据
   - 模拟真实使用场景

---

## 验证方法

### 本地测试验证

```bash
# 1. 运行测试脚本
# 设 30 秒超时保护
timeout 30 node test_websocket.js

# 2. 检查输出
# 应该看到：
# - ✓ WebSocket 连接成功
# - ✓ session.created
# - ✓ session.updated
# - 📝 转写结果（持续输出）
# - 测试完成

# 3. 如果没有转写结果，检查：
# - 音频数据是否正确发送
# - 事件处理是否正确
# - 错误日志
```

### APK 测试验证

```bash
# 1. 构建 APK
# 按照 BUILD.md 规则构建

# 2. 安装并测试
# - 开启实时转写
# - 开始录音
# - 检查日志输出

# 3. 对比本地测试和 APK 测试日志
# 确保行为一致
```

---

## 更新记录

| 日期 | 更新内容 | 更新人 |
|-----|---------|-------|
| 2026-05-18 | 初始版本，基于 Qwen 实时转写测试经验 | AI |
| 2026-05-25 | 安全修复：node test_websocket.js 加 timeout 30 命令层保护 | AI |

---

*记住：先本地测试，再构建 APK。这是避免反复构建、快速定位问题的关键。*
