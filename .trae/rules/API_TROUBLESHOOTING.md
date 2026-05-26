---
alwaysApply: false
globs: lib/**/api/**, lib/**/service/**
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
| CASE-021 | Admin API 返回 404 | `Cannot GET /api/v1/admin/stats` | ✅ 已解决 |
| CASE-022 | NestJS 服务循环崩溃 | `EADDRINUSE: address already in use :::3000` | ✅ 已解决 |
| CASE-023 | 数据库列不存在 | `column Plan.xxx does not exist` | ✅ 已解决 |
| CASE-024 | TypeORM 外键约束失败 | `foreign key constraint cannot be implemented` | ✅ 已解决 |
| CASE-025 | JWT Token 缺少 role 字段 | 登录成功但提示"需要管理员权限" | ✅ 已解决 |
| CASE-026 | API 返回格式不一致 | 前端报错 `xxx.map is not a function` | ✅ 已解决 |
| CASE-027 | 分页响应格式不匹配 | 前端期望 `items` 但后端返回 `users` | ✅ 已解决 |
| CASE-028 | Monitor API 数据格式错误 | 服务列表返回对象而非数组 | ✅ 已解决 |

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

## 🔴 CASE-021: Admin/Monitor API 返回 404

### 问题现象
- NestJS 服务启动日志显示 `AdminController {/api/v1/admin}` 已加载
- 但访问 `/api/v1/admin/stats` 返回 `404 Not Found`
- PM2 日志显示服务不断重启

### 根本原因
**JwtAuthGuard 依赖缺失**：`AdminModule` 和 `MonitorModule` 使用了 `JwtAuthGuard`，但 `AuthModule` 没有导出 `JwtModule`，导致 `JwtService` 无法解析。

错误信息：
```
Nest can't resolve dependencies of the JwtAuthGuard (?).
Please make sure that the argument JwtService at index [0] is available
in the MonitorModule context.
```

### 解决方案
1. **在 AuthModule 中导出 JwtModule**：
   ```typescript
   @Module({
     imports: [JwtModule.register({...})],
     exports: [AuthService, JwtModule], // 添加 JwtModule
   })
   export class AuthModule {}
   ```

2. **在 AdminModule/MonitorModule 中导入 AuthModule**：
   ```typescript
   @Module({
     imports: [TypeOrmModule.forFeature([...]), AuthModule],
   })
   export class AdminModule {}
   ```

3. **避免循环依赖**：如果 `AuthModule` 已导入 `SubscriptionModule`，则 `SubscriptionModule` 不应再导入 `AuthModule`，而是直接导入 `JwtModule`：
   ```typescript
   @Module({
     imports: [
       TypeOrmModule.forFeature([...]),
       JwtModule.register({
         secret: process.env.JWT_SECRET || 'changji_jwt_secret_change_me',
         signOptions: { expiresIn: '15m' },
       }),
     ],
   })
   export class SubscriptionModule {}
   ```

### 验证方法
```bash
curl -s http://127.0.0.1:3000/api/v1/admin/stats
# 预期返回 401 Unauthorized（路由已注册，需要认证）
```

---

## 🔴 CASE-022: NestJS 服务循环崩溃（端口冲突）

### 问题现象
- PM2 显示服务 `restart` 次数不断增加（2000+ 次）
- 错误日志：`EADDRINUSE: address already in use :::3000`
- 服务启动后立即崩溃，然后 PM2 自动重启，形成死循环

### 根本原因
**服务器上有两个 PM2 实例在竞争端口**：
- `root` 用户的 PM2 运行 `/opt/changji-cloud/api/dist/main.js`
- `admin` 用户的 PM2 运行 `/home/admin/dang/server/dist/main.js`

当 admin 的服务启动时，端口 3000 已被 root 的服务占用，导致启动失败。PM2 检测到失败后自动重启，形成循环。

### 解决方案
1. **检查所有用户的 PM2 进程**：
   ```bash
   # 检查当前用户的 PM2
   pm2 list
   
   # 检查 root 用户的 PM2
   sudo env PATH=/usr/bin:/usr/local/bin pm2 list
   ```

2. **停止并删除冲突的 PM2 进程**：
   ```bash
   # 停止 root 用户的 changji-api
   sudo env PATH=/usr/bin:/usr/local/bin pm2 stop changji-api
   sudo env PATH=/usr/bin:/usr/local/bin pm2 delete changji-api
   
   # 停止 admin 用户的 changji-api
   pm2 stop changji-api
   pm2 delete changji-api
   ```

3. **释放端口**：
   ```bash
   sudo killall -9 node  # 极端情况下使用
   # 或
   sudo fuser -k 3000/tcp
   ```

4. **重新启动服务**：
   ```bash
   cd /home/admin/dang/server && pm2 start dist/main.js --name changji-api && pm2 save
   ```

### 验证方法
```bash
pm2 list
# 预期：只有一个 changji-api 进程，status 为 online，restart 为 0

ss -tlnp | grep 3000
# 预期：只有一个进程监听 3000 端口
```

---

## 🔴 CASE-023: 数据库列不存在（TypeORM schema 不同步）

### 问题现象
- API 返回 500 Internal Server Error
- 错误日志：`QueryFailedError: column Plan.isRecommended does not exist`
- 或 `column Plan.features does not exist`、`column Plan.quotaType does not exist`

### 根本原因
**实体定义与数据库 schema 不一致**：
- 代码中 `Plan` 实体添加了新字段（`isRecommended`、`features`、`quotaType`、`quotaValue`）
- 但数据库 `plans` 表中没有这些列
- `synchronize: false` 导致 TypeORM 不会自动创建新列

### 解决方案

**方案 A：手动添加缺失的列（推荐用于生产环境）**
```sql
# ⚠️ 仅手动使用（交互式 psql，AI 执行会永久阻塞）
sudo -u postgres psql -d appdb

-- 添加缺失的列
ALTER TABLE plans ADD COLUMN features TEXT[] DEFAULT ARRAY[]::TEXT[];
ALTER TABLE plans ADD COLUMN isRecommended BOOLEAN DEFAULT false;
ALTER TABLE plans ADD COLUMN quotaType VARCHAR(50);
ALTER TABLE plans ADD COLUMN quotaValue INTEGER DEFAULT 0;

# ✅ AI/脚本使用（非交互式）
PGOPTIONS="-c statement_timeout=30000" sudo -u postgres psql -d appdb -c "ALTER TABLE plans ADD COLUMN IF NOT EXISTS features TEXT[] DEFAULT ARRAY[]::TEXT[]; ALTER TABLE plans ADD COLUMN IF NOT EXISTS isRecommended BOOLEAN DEFAULT false; ALTER TABLE plans ADD COLUMN IF NOT EXISTS quotaType VARCHAR(50); ALTER TABLE plans ADD COLUMN IF NOT EXISTS quotaValue INTEGER DEFAULT 0;"
```

**方案 B：临时开启 synchronize（仅用于开发环境）**
```typescript
// app.module.ts
TypeOrmModule.forRoot({
  ...
  synchronize: true, // 临时开启，自动同步 schema
})
```

**注意**：开启 `synchronize: true` 可能导致外键约束错误（见 CASE-024），需要同时修复实体关系定义。

### 验证方法
```sql
-- 检查列是否已添加
SELECT column_name FROM information_schema.columns WHERE table_name = 'plans';
```

---

## 🔴 CASE-024: TypeORM 外键约束无法创建

### 问题现象
- 开启 `synchronize: true` 后服务无法启动
- 错误日志：`foreign key constraint "FK_xxx" cannot be implemented`
- 服务不断重启

### 根本原因
**OneToOne 关系的 `@JoinColumn` 配置错误**：
```typescript
// ❌ 错误：在 User 实体中配置 @JoinColumn，且 name 指向主键列
@Entity('users')
export class User {
  @OneToOne(() => UserBalance, balance => balance.user)
  @JoinColumn({ name: 'id', referencedColumnName: 'userId' }) // 错误！
  balance: UserBalance;
}
```

问题：
1. `@JoinColumn` 应该放在关系的**拥有方**（即存储外键的表）
2. `name: 'id'` 试图将主键列同时作为外键，这是不允许的

### 解决方案
```typescript
// ✅ 正确：在 UserBalance 实体中配置 @JoinColumn
@Entity('users')
export class User {
  @OneToOne(() => UserBalance, balance => balance.user)
  balance: UserBalance; // 不配置 @JoinColumn
}

@Entity('user_balances')
export class UserBalance {
  @PrimaryColumn()
  userId: string;

  @OneToOne(() => User, user => user.balance)
  @JoinColumn({ name: 'userId' }) // 正确：在拥有方配置
  user: User;
}
```

### 验证方法
```bash
# 重启服务后检查是否还有外键约束错误
cat /home/admin/.pm2/logs/changji-api-error.log | grep -i "foreign key"
# 预期：无输出
```

---

## 🔴 CASE-025: JWT Token 缺少 role 字段导致权限验证失败

### 问题现象
- 使用管理员账户登录成功
- 访问管理页面时提示"需要管理员权限"
- 登录返回的 token 看起来正常
- AdminGuard 验证失败

### 根本原因
**JWT payload 中缺少 role 字段**：
- 前端 AdminGuard 从 token 中解码 `user.role` 判断是否为管理员
- 但 `AuthService.login()` 生成 token 时，只包含了 `sub` 和 `phone`
- 导致 `user.role` 为 `undefined`，权限验证失败

```typescript
// ❌ 错误：payload 中缺少 role
const payload = { sub: user.id, phone: user.phone };

// ✅ 正确：包含 role
const payload = { sub: user.id, phone: user.phone, role: user.role };
```

### 解决方案
修改 `server/src/auth/auth.service.ts` 中的 `login()` 方法，在 JWT payload 中添加 `role`：

```typescript
async login(loginDto: LoginDto) {
  // ... 验证用户 ...
  
  const payload = {
    sub: user.id,
    phone: user.phone,
    role: user.role, // 添加这一行
  };
  
  const accessToken = this.jwtService.sign(payload);
  
  return {
    code: 200,
    message: '登录成功',
    data: {
      accessToken,
      refreshToken,
      user: { id: user.id, phone: user.phone, role: user.role },
    },
  };
}
```

### 验证方法
1. 使用管理员账户重新登录
2. 复制返回的 accessToken，在 [jwt.io](https://jwt.io) 解码
3. 确认 payload 中包含 `role` 字段且值为 `"admin"`
4. 访问管理页面，应该可以正常进入

---

## 🔴 CASE-026: API 返回格式不一致导致前端 `map` 错误

### 问题现象
- 前端页面加载时提示 `xxx.map is not a function`
- 控制台错误：`Cannot read properties of undefined (reading 'map')`
- 不同 API 返回格式不统一

### 根本原因
**API 返回格式混乱**：
- 有的 API 直接返回数据：`[{...}, {...}]`
- 有的 API 包装一层：`{ users: [{...}, {...}] }`
- 有的 API 包装在 `data` 中：`{ code: 200, message: 'success', data: [{...}] }`
- 前端期望统一的格式，但后端实现不统一

**问题类型**：
1. **Auth API**：Service 已返回包装格式，Controller 又包装了一层 → 双重包装
2. **Subscription API**：同上，双重包装
3. **Admin API**：Service 没包装，Controller 包装 → 格式正确
4. **Monitor API**：没有包装 → 缺少 `{ code, message, data }`

### 解决方案
**统一 API 返回格式为 `{ code, message, data }`**：

1. **AuthController**：直接返回 Service 结果，不要重复包装
   ```typescript
   async login(@Body() dto: LoginDto) {
     return this.authService.login(dto); // Service 已返回 { code, message, data }
   }
   ```

2. **SubscriptionController**：同上，直接返回 Service 结果
   ```typescript
   async getPlans(@Query('type') type?: string) {
     return this.subscriptionService.getPlans(type);
   }
   ```

3. **AdminController**：保持不变，已正确包装
   ```typescript
   async getStats() {
     const data = await this.adminService.getStats();
     return { code: 200, message: 'success', data };
   }
   ```

4. **MonitorController**：添加包装
   ```typescript
   async getSystemInfo() {
     const data = await this.monitorService.getSystemInfo();
     return { code: 200, message: 'success', data };
   }
   ```

### 验证方法
```bash
# 测试所有 API 返回格式
curl -s http://101.133.238.249/api/v1/auth/login -H "Content-Type: application/json" -d '{"phone":"18682092379","password":"Hu123456"}'
# 预期返回：{ "code": 200, "message": "登录成功", "data": { ... } }

curl -s http://101.133.238.249/api/v1/subscription/plans
# 预期返回：{ "code": 200, "message": "success", "data": [ ... ] }

curl -s http://101.133.238.249/api/v1/admin/stats -H "Authorization: Bearer $TOKEN"
# 预期返回：{ "code": 200, "message": "success", "data": { ... } }
```

---

## 🔴 CASE-027: 分页响应格式不匹配导致前端错误

### 问题现象
- 用户管理页面无法加载
- 控制台错误：`items.map is not a function` 或 `Cannot read properties of undefined (reading 'map')`
- API 返回状态码 200 但数据格式不对

### 根本原因
**分页 API 字段名不匹配**：
- 前端类型定义期望 `items` 字段：
  ```typescript
  interface PaginationResponse<T> {
    items: T[];
    total: number;
    page: number;
    totalPages: number;
  }
  ```
- 后端返回的字段名不统一：
  - 用户列表：`{ users: [...], total: ... }`
  - 订阅列表：`{ subscriptions: [...], total: ... }`
  - 充值记录：`{ records: [...], total: ... }`

### 解决方案
**统一所有分页 API 使用 `items` 字段**：

修改 `server/src/admin/admin.service.ts`：
```typescript
async getUsers(page = 1, limit = 20, search?: string) {
  // ... 查询数据库 ...
  
  return {
    items: users.map(u => ({ ... })), // 从 users 改为 items
    total,
    page,
    totalPages: Math.ceil(total / limit),
  };
}

async getSubscriptions(page = 1, limit = 20, status?: string) {
  // ... 查询数据库 ...
  
  return {
    items: subscriptions.map(s => ({ ... })), // 从 subscriptions 改为 items
    total,
    page,
    totalPages: Math.ceil(total / limit),
  };
}

async getRechargeRecords(page = 1, limit = 20) {
  // ... 查询数据库 ...
  
  return {
    items: records.map(r => ({ ... })), // 从 records 改为 items
    total,
    page,
    totalPages: Math.ceil(total / limit),
  };
}
```

### 验证方法
```bash
curl -s http://101.133.238.249/api/v1/admin/users -H "Authorization: Bearer $TOKEN"
# 预期返回：{ "code": 200, "message": "success", "data": { "items": [...], "total": ... } }

curl -s http://101.133.238.249/api/v1/admin/subscriptions -H "Authorization: Bearer $TOKEN"
# 预期返回：{ "code": 200, "message": "success", "data": { "items": [...], "total": ... } }
```

---

## 🔴 CASE-028: Monitor API 数据格式错误导致前端崩溃

### 问题现象
- 服务器监控页面无法加载
- 控制台错误：`services.map is not a function`
- 或 `Cannot read properties of undefined (reading 'map')`

### 根本原因
**Monitor Service 直接返回 Agent 的原始数据**：
- Agent 返回的服务列表是对象格式：`{ "changji-api": { ... }, "other": { ... } }`
- 前端期望的是数组格式：`[{ name: "changji-api", status: "active", ... }, ...]`

**Agent 原始返回**：
```json
{
  "services": {
    "changji-api": { "status": "active" },
    "nginx": { "status": "active" }
  }
}
```

**前端期望**：
```json
{
  "code": 200,
  "message": "success",
  "data": [
    { "name": "changji-api", "status": "active", "active": true },
    { "name": "nginx", "status": "active", "active": true }
  ]
}
```

### 解决方案
修改 `server/src/monitor/monitor.service.ts`，转换数据格式：

```typescript
async getSystemInfo() {
  const data = await this.agentRequest('/info');
  
  // 解析内存信息（支持 Gi、Mi、G、M 等单位）
  const memoryMatch = data.memory?.match(/Mem:\s+(\d+\.?\d*)(\w+)\s+(\d+\.?\d*)(\w+)\s+(\d+\.?\d*)(\w+)/);
  let memory = { total: 0, used: 0, free: 0, usagePercent: 0 };
  
  if (memoryMatch) {
    const total = this.parseSize(memoryMatch[1], memoryMatch[2]);
    const used = this.parseSize(memoryMatch[3], memoryMatch[4]);
    memory = {
      total,
      used,
      free: this.parseSize(memoryMatch[5], memoryMatch[6]),
      usagePercent: total > 0 ? (used / total) * 100 : 0,
    };
  }
  
  // 解析磁盘信息
  let disk = { total: 0, used: 0, free: 0, usagePercent: 0 };
  const diskLines = data.disk?.split('\n').filter(line => line.trim());
  if (diskLines?.length > 1) {
    const rootLine = diskLines.find(line => line.includes('/dev/vda3')) || diskLines[1];
    const diskMatch = rootLine?.match(/(\d+\.?\d*)(\w+)\s+(\d+\.?\d*)(\w+)\s+(\d+\.?\d*)(\w+)\s+(\d+)%/);
    if (diskMatch) {
      disk = {
        total: this.parseSize(diskMatch[1], diskMatch[2]),
        used: this.parseSize(diskMatch[3], diskMatch[4]),
        free: this.parseSize(diskMatch[5], diskMatch[6]),
        usagePercent: parseInt(diskMatch[7], 10),
      };
    }
  }
  
  // 解析负载和 CPU
  const loadMatch = data.load?.match(/load average:\s+(\d+\.?\d*),\s+(\d+\.?\d*),\s+(\d+\.?\d*)/);
  const load = loadMatch ? [parseFloat(loadMatch[1]), parseFloat(loadMatch[2]), parseFloat(loadMatch[3])] : [0, 0, 0];
  const cpu = {
    usage: (load[0] / parseInt(data.cpu_cores || '1', 10)) * 100,
    cores: parseInt(data.cpu_cores || '1', 10),
    model: 'Intel Xeon',
  };
  
  // 解析运行时间
  let uptime = 0;
  const uptimeMatch = data.load?.match(/up\s+(\d+)\s+days?/);
  const hoursMatch = data.load?.match(/up\s+(?:\d+\s+days?,\s+)?(\d+):(\d+)/);
  if (uptimeMatch) uptime += parseInt(uptimeMatch[1], 10) * 86400;
  if (hoursMatch) uptime += parseInt(hoursMatch[1], 10) * 3600 + parseInt(hoursMatch[2], 10) * 60;
  
  return {
    hostname: 'changji-server',
    platform: 'linux',
    uptime,
    cpu,
    memory,
    disk,
    load,
    timestamp: data.timestamp,
  };
}

async getServices() {
  const data = await this.agentRequest('/services');
  const services = data.services || {};
  
  // 转换对象为数组
  return Object.entries(services).map(([name, info]: [string, any]) => ({
    name,
    status: info.status,
    active: info.status === 'active',
  }));
}

// 单位解析函数
private parseSize(value: string, unit: string): number {
  const num = parseFloat(value);
  const units = { 
    'B': 1, 'K': 1024, 'KB': 1024,
    'M': 1024*1024, 'MB': 1024*1024, 'MI': 1024*1024, 'MIB': 1024*1024,
    'G': 1024*1024*1024, 'GB': 1024*1024*1024, 'GI': 1024*1024*1024, 'GIB': 1024*1024*1024,
    'T': 1024*1024*1024*1024, 'TB': 1024*1024*1024*1024 
  };
  const multiplier = units[unit.toUpperCase()] || 1;
  return Math.floor(num * multiplier);
}
```

同时确保 `MonitorController` 正确包装：
```typescript
async getSystemInfo() {
  const data = await this.monitorService.getSystemInfo();
  return { code: 200, message: 'success', data };
}

async getServices() {
  const data = await this.monitorService.getServices();
  return { code: 200, message: 'success', data };
}
```

### 验证方法
```bash
curl -s http://101.133.238.249/api/v1/monitor/services -H "Authorization: Bearer $TOKEN"
# 预期返回：{ "code": 200, "message": "success", "data": [ { "name": "...", "status": "...", "active": true }, ... ] }
```

---

## 更新记录

| 日期 | 更新内容 |
|-----|---------|
| 2026-05-19 | 方案C重构：从 BUILD_TROUBLESHOOTING.md 拆分出 API 案例，独立管理 |
| 2026-05-22 | 新增 CASE-021~024：Admin API 404、NestJS 循环崩溃、数据库列缺失、TypeORM 外键约束失败 |
| 2026-05-22 | 新增 CASE-025~028：JWT role 缺失、API 格式不一致、分页字段不匹配、Monitor 数据格式错误 |
| 2026-05-25 | 安全修复：交互式 psql 加警告标记并提供 AI 安全替代；SQL 语句加 statement_timeout |