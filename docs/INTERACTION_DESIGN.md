# 畅记 App - 服务器端与客户端交互方案

## 一、方案概述

### 1.1 设计原则

| 原则 | 说明 |
|------|------|
| **最小化服务端** | 服务端只做登录、订阅管理、API Key 分发，不做 AI 处理 |
| **客户端自治** | AI 调用（转写/分析）完全在客户端完成，服务端不触碰用户数据 |
| **无状态服务** | 服务端不保存会话状态，全部通过 JWT Token 认证 |
| **防御性编程** | 客户端假设网络不可靠，所有操作都有降级方案 |

### 1.2 职责划分总览

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              客户端 (Flutter)                                 │
│                                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   录音/笔记    │  │   AI 转写/分析  │  │   登录/注册    │  │   订阅/付费    │    │
│  │   (本地存储)   │  │ (直调AI服务商) │  │  (调用云端API) │  │  (调用云端API) │    │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘    │
│         │                  │                  │                  │          │
│         └──────────────────┴──────────────────┴──────────────────┘          │
│                                    │                                        │
│                         ┌─────────────────┐                                 │
│                         │   本地 SQLite    │                                 │
│                         │  (Drift ORM)    │                                 │
│                         └─────────────────┘                                 │
│                                    │                                        │
│                         ┌─────────────────┐                                 │
│                         │   双模式路由层    │                                 │
│                         │ 自有API / 云端API │                                 │
│                         └─────────────────┘                                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                          │
                                          │ HTTPS (仅登录/订阅/API Key 获取)
                                          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         服务器端 (NestJS + PostgreSQL)                        │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         API Gateway (Nginx)                          │   │
│  │                    SSL终止 / 限流 / 反向代理 / 日志                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│        ┌───────────────────────────┼───────────────────────────┐            │
│        ▼                           ▼                           ▼            │
│  ┌─────────────┐            ┌─────────────┐            ┌─────────────┐     │
│  │  Auth模块    │            │ Subscription│            │  API Key    │     │
│  │  (登录注册)   │            │  (订阅管理)   │            │  (Key分发)   │     │
│  │             │            │             │            │             │     │
│  │ • 注册       │            │ • 套餐查询    │            │ • Key池管理   │     │
│  │ • 登录       │            │ • 购买套餐    │            │ • 分配Key    │     │
│  │ • 验证码     │            │ • 余量查询    │            │ • 轮换Key    │     │
│  │ • Token刷新  │            │ • 到期提醒    │            │ • 失效回收    │     │
│  │ • 密码重置   │            │ • 使用记录    │            │             │     │
│  └─────────────┘            └─────────────┘            └─────────────┘     │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      PostgreSQL (数据持久化)                          │   │
│  │                                                                     │   │
│  │  users │ subscriptions │ api_keys │ user_api_keys │ plans │ sms_logs │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      Redis (缓存/限流/会话)                           │   │
│  │                                                                     │   │
│  │  JWT黑名单 │ 短信验证码 │ 请求限流计数 │ API Key缓存 │ 热点数据缓存   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 二、服务器端核心功能

### 2.1 功能模块划分

| 模块 | 功能 | 数据表 | 优先级 |
|------|------|--------|--------|
| **Auth** | 注册、登录、Token、验证码、密码管理 | users | P0 |
| **Subscription** | 套餐管理、购买、余量、到期处理 | subscriptions, plans | P0 |
| **ApiKey** | API Key 池管理、分配、轮换、回收 | api_keys, user_api_keys | P0 |
| **Payment** | 订单创建、支付回调、对账 | orders | P1 |
| **Admin** | 运营后台（套餐配置、Key池监控） | - | P2 |

### 2.2 Auth 模块详细设计

#### 2.2.1 注册流程

```
客户端                              服务端
  │                                  │
  │  POST /api/v1/auth/register     │
  │  {phone, password, smsCode}     │
  │ ───────────────────────────────> │
  │                                  │
  │                                  │ 1. 验证短信验证码 (Redis)
  │                                  │ 2. 检查手机号是否已注册
  │                                  │ 3. bcrypt 加密密码
  │                                  │ 4. 创建用户记录
  │                                  │ 5. 生成 JWT Token 对
  │                                  │
  │  {accessToken, refreshToken,    │
  │   user}                         │
  │ <─────────────────────────────── │
  │                                  │
  │  本地存储 Token，进入首页         │
```

#### 2.2.2 登录流程

```
客户端                              服务端
  │                                  │
  │  POST /api/v1/auth/login        │
  │  {phone, password}              │
  │ ───────────────────────────────> │
  │                                  │
  │                                  │ 1. 查询用户
  │                                  │ 2. bcrypt 比对密码
  │                                  │ 3. 检查用户状态
  │                                  │ 4. 生成 JWT Token 对
  │                                  │
  │  {accessToken, refreshToken,    │
  │   user}                         │
  │ <─────────────────────────────── │
```

#### 2.2.3 Token 刷新流程

```
客户端                              服务端
  │                                  │
  │  POST /api/v1/auth/refresh      │
  │  {refreshToken}                 │
  │ ───────────────────────────────> │
  │                                  │
  │                                  │ 1. 验证 refreshToken 签名
  │                                  │ 2. 检查 Token 是否在黑名单
  │                                  │ 3. 将旧 refreshToken 加入黑名单
  │                                  │ 4. 生成新的 Token 对
  │                                  │
  │  {accessToken, refreshToken}    │
  │ <─────────────────────────────── │
```

### 2.3 Subscription 模块详细设计

#### 2.3.1 套餐模型

```typescript
interface Plan {
  id: string;              // 'free' | 'basic' | 'pro' | 'enterprise'
  name: string;            // 显示名称
  description: string;     // 描述
  priceCents: number;      // 价格（分）
  durationDays: number;    // 有效期（天）
  quotaType: string;       // 'transcription_minutes' | 'analysis_count' | 'unlimited'
  quotaValue: number;      // 额度值
  features: string[];      // 功能列表
}
```

#### 2.3.2 订阅状态查询

```
客户端                              服务端
  │                                  │
  │  GET /api/v1/subscription       │
  │  Authorization: Bearer {token}  │
  │ ───────────────────────────────> │
  │                                  │
  │                                  │ 1. JWT 验证
  │                                  │ 2. 查询用户订阅
  │                                  │ 3. 计算剩余额度
  │                                  │ 4. 检查是否到期
  │                                  │
  │  {plan, status, expiresAt,      │
  │   totalQuota, usedQuota,        │
  │   remainingQuota}               │
  │ <─────────────────────────────── │
```

#### 2.3.3 套餐购买流程

```
客户端                              服务端                              支付平台
  │                                  │                                    │
  │  POST /api/v1/orders            │                                    │
  │  {planId, paymentChannel}       │                                    │
  │ ───────────────────────────────> │                                    │
  │                                  │ 1. 创建订单（未支付）               │
  │                                  │ 2. 调用支付平台预下单               │
  │                                  │───────────────────────────────────>│
  │                                  │                                    │
  │                                  │                    {prepayId, params}
  │                                  │ <──────────────────────────────────│
  │                                  │                                    │
  │  {orderId, paymentParams}       │                                    │
  │ <─────────────────────────────── │                                    │
  │                                  │                                    │
  │  [用户完成支付]                    │                                    │
  │                                  │                                    │
  │                                  │         [支付平台回调]              │
  │                                  │ <──────────────────────────────────│
  │                                  │ 3. 验证签名                        │
  │                                  │ 4. 更新订单为已支付                 │
  │                                  │ 5. 创建/更新订阅                   │
  │                                  │ 6. 分配 API Key                    │
  │                                  │                                    │
  │  [推送通知 / 客户端轮询查询]        │                                    │
  │ <────────────────────────────────│                                    │
```

### 2.4 ApiKey 模块详细设计

#### 2.4.1 API Key 分配策略

```
┌─────────────────────────────────────────────────────────────┐
│                     API Key 池管理架构                        │
│                                                             │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐ │
│  │  Key Pool   │      │  Key Pool   │      │  Key Pool   │ │
│  │  (OpenAI)   │      │  (DeepSeek) │      │  (阿里云)    │ │
│  │             │      │             │      │             │ │
│  │ • key_001   │      │ • key_001   │      │ • key_001   │ │
│  │ • key_002   │      │ • key_002   │      │ • key_002   │ │
│  │ • key_003   │      │ • key_003   │      │ • key_003   │ │
│  │   ...       │      │   ...       │      │   ...       │ │
│  └──────┬──────┘      └──────┬──────┘      └──────┬──────┘ │
│         │                    │                    │        │
│         └────────────────────┼────────────────────┘        │
│                              ▼                              │
│                    ┌─────────────────┐                      │
│                    │   分配策略引擎    │                      │
│                    │                 │                      │
│                    │ 1. 按负载均衡    │                      │
│                    │ 2. 按用户套餐    │                      │
│                    │ 3. 按 Key 健康度 │                      │
│                    └─────────────────┘                      │
└─────────────────────────────────────────────────────────────┘
```

#### 2.4.2 Key 分配流程

```
客户端                              服务端
  │                                  │
  │  GET /api/v1/api-key            │
  │  Authorization: Bearer {token}  │
  │ ───────────────────────────────> │
  │                                  │
  │                                  │ 1. JWT 验证
  │                                  │ 2. 查询用户订阅状态
  │                                  │ 3. 检查额度是否充足
  │                                  │ 4. 从 Key 池分配可用 Key
  │                                  │ 5. 记录分配日志
  │                                  │
  │  {provider, apiKey, model,      │
  │   expiresAt}                    │
  │ <─────────────────────────────── │
  │                                  │
  │  客户端使用该 Key 直接调用 AI    │
```

#### 2.4.3 Key 安全设计

| 安全措施 | 说明 |
|---------|------|
| **加密存储** | Key 在数据库中用 AES-256-GCM 加密 |
| **定期轮换** | 每个 Key 有最大使用次数，达到后自动回收分配新 Key |
| **异常检测** | 监控 Key 的使用频率，异常时自动禁用 |
| **最小权限** | Key 仅配置必要的 API 权限（如仅转写权限） |
| **过期机制** | 分配的 Key 有过期时间（如 1 小时），过期后需重新获取 |

---

## 三、客户端交互逻辑

### 3.1 应用启动流程

```
┌─────────────┐
│   App启动    │
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│ 1. 初始化本地数据库 │
│    (SQLite/Drift) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────┐
│ 2. 检查本地Token  │────>│ Token存在?   │
└─────────────────┘     └──────┬──────┘
                               │
                    ┌──────────┴──────────┐
                    │ 是                   │ 否
                    ▼                     ▼
           ┌─────────────┐        ┌─────────────┐
           │ 3. 验证Token  │        │ 显示登录页   │
           │   (静默刷新)  │        │ 或游客模式   │
           └──────┬──────┘        └─────────────┘
                  │
         ┌────────┴────────┐
         │ 有效              │ 无效/过期
         ▼                 ▼
┌─────────────┐    ┌─────────────┐
│ 4. 获取订阅  │    │ 清除Token   │
│   状态      │    │ 显示登录页   │
│   + API Key │    │             │
└──────┬──────┘    └─────────────┘
       │
       ▼
┌─────────────┐
│ 5. 进入首页  │
│   (根据订阅  │
│   状态展示)  │
└─────────────┘
```

### 3.2 双模式 AI 调用流程

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          AI 功能调用流程                                  │
│                                                                         │
│  用户点击「开始转写」                                                      │
│       │                                                                 │
│       ▼                                                                 │
│  ┌─────────────┐                                                        │
│  │ 检查用户登录状态 │                                                     │
│  └──────┬──────┘                                                        │
│         │                                                               │
│    ┌────┴────┐                                                          │
│    │ 已登录   │ 未登录                                                   │
│    ▼         ▼                                                          │
│ ┌────────┐  ┌─────────────┐                                             │
│ │获取云端  │  │ 检查本地API  │                                             │
│ │API Key  │  │ 配置是否存在  │                                             │
│ └────┬───┘  └──────┬──────┘                                             │
│      │             │                                                    │
│      │        ┌────┴────┐                                               │
│      │        │ 有配置   │ 无配置                                        │
│      │        ▼         ▼                                               │
│      │   ┌────────┐  ┌─────────────┐                                   │
│      │   │使用本地  │  │ 提示：请登录  │                                   │
│      │   │API Key  │  │ 或配置API Key│                                   │
│      │   └────┬───┘  └─────────────┘                                   │
│      │        │                                                         │
│      └────────┴────────┐                                                │
│                        ▼                                                │
│              ┌─────────────────┐                                        │
│              │ 客户端直接调用AI  │                                        │
│              │ (OpenAI/阿里云等)│                                        │
│              └─────────────────┘                                        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.3 用户界面交互逻辑

#### 3.3.1 登录/注册页面

```dart
// 页面状态机
enum AuthPageState {
  phoneInput,      // 输入手机号
  smsCodeInput,    // 输入验证码
  passwordInput,   // 设置/输入密码
  loading,         // 加载中
  error,           // 错误提示
}

// 交互流程
class AuthPageLogic {
  // 1. 输入手机号 → 点击「获取验证码」
  // 2. 倒计时 60s，调用 POST /api/v1/auth/send-sms-code
  // 3. 输入验证码 → 自动验证或点击「下一步」
  // 4. 新用户：设置密码 → 注册 → 登录
  // 5. 老用户：输入密码 → 登录
  // 6. 保存 Token → 跳转首页
}
```

#### 3.3.2 订阅/套餐页面

```dart
// 页面结构
class SubscriptionPage {
  // 顶部：当前订阅状态卡片
  //   - 套餐名称、到期时间、剩余额度进度条
  //
  // 中部：套餐列表
  //   - 免费版（当前使用）
  //   - 基础版 ¥9.9/月
  //   - 专业版 ¥29/月
  //   - 每个卡片显示：价格、额度、功能列表、购买按钮
  //
  // 底部：使用记录入口
}

// 购买流程
class PurchaseFlow {
  // 1. 点击「购买」→ 创建订单 POST /api/v1/orders
  // 2. 调起微信支付/支付宝
  // 3. 支付完成 → 轮询订单状态 / 接收推送
  // 4. 支付成功 → 刷新订阅状态 → 显示成功提示
}
```

#### 3.3.3 设置页面 - 账户与安全

```dart
class AccountSettingsPage {
  // 已登录状态：
  //   - 头像/昵称（可编辑）
  //   - 手机号（已绑定）
  //   - 当前套餐（点击跳转订阅页）
  //   - 剩余额度显示
  //   - 退出登录
  //
  // 未登录状态：
  //   - 「登录/注册」按钮
  //   - 「使用自有 API Key」选项
}
```

### 3.4 本地状态管理

```dart
// 核心状态类
class AppState {
  // 认证状态
  final AuthState auth;
  
  // 订阅状态
  final SubscriptionState subscription;
  
  // AI 服务模式
  final AiServiceMode aiMode;  // local / cloud
  
  // 本地 API 配置
  final LocalApiConfig? localConfig;
  
  // 云端 API Key 缓存
  final CloudApiKey? cloudApiKey;
}

// 状态持久化（SharedPreferences + 安全存储）
class StatePersistence {
  // 普通数据：SharedPreferences
  //   - 用户偏好、主题设置
  
  // 敏感数据：flutter_secure_storage
  //   - accessToken、refreshToken
  //   - 本地 API Key（加密）
  //   - 云端 API Key（加密，有过期时间）
}
```

---

## 四、交互控制机制

### 4.1 请求/响应协议规范

#### 4.1.1 统一请求格式

```typescript
// HTTP 请求头
{
  "Content-Type": "application/json",
  "Authorization": "Bearer {accessToken}",
  "X-Request-ID": "uuid-v4",           // 请求追踪ID
  "X-Device-ID": "device-uuid",        // 设备标识
  "X-App-Version": "1.2.3",            // App版本
  "X-Platform": "android|ios",         // 平台
}

// 请求体（POST/PUT）
{
  // 业务数据
}
```

#### 4.1.2 统一响应格式

```typescript
// 成功响应
{
  "code": 200,
  "message": "success",
  "data": { ... },
  "timestamp": 1715587200000,
  "requestId": "uuid-v4"
}

// 错误响应
{
  "code": 4001,           // 业务错误码
  "message": "验证码错误", // 用户可读错误信息
  "data": null,
  "timestamp": 1715587200000,
  "requestId": "uuid-v4"
}

// 分页响应
{
  "code": 200,
  "message": "success",
  "data": {
    "list": [ ... ],
    "pagination": {
      "page": 1,
      "pageSize": 20,
      "total": 100,
      "hasMore": true
    }
  }
}
```

#### 4.1.3 业务错误码定义

| 错误码 | 含义 | 客户端处理 |
|--------|------|-----------|
| 200 | 成功 | - |
| 400 | 请求参数错误 | 提示用户检查输入 |
| 401 | Token 无效或过期 | 跳转登录页/静默刷新 |
| 403 | 权限不足 | 提示升级套餐 |
| 404 | 资源不存在 | 友好提示 |
| 429 | 请求过于频繁 | 提示稍后再试 |
| 500 | 服务器内部错误 | 提示服务端异常 |
| 4001 | 验证码错误 | 提示重新输入 |
| 4002 | 手机号已注册 | 提示直接登录 |
| 4003 | 密码错误 | 提示重新输入/找回密码 |
| 4004 | 套餐已过期 | 提示续费 |
| 4005 | 额度不足 | 提示购买套餐 |
| 4006 | API Key 池耗尽 | 提示稍后重试 |

### 4.2 数据验证规则

#### 4.2.1 服务端验证

```typescript
// 注册请求验证
interface RegisterDto {
  phone: string;      // 必填，正则: ^1[3-9]\d{9}$
  password: string;   // 必填，长度 8-20，包含字母+数字
  smsCode: string;    // 必填，长度 6，纯数字
}

// 登录请求验证
interface LoginDto {
  phone: string;      // 必填
  password: string;   // 必填
}

// 订单创建验证
interface CreateOrderDto {
  planId: string;     // 必填，必须在 plans 表中存在
  paymentChannel: string;  // 必填，enum: ['wechat', 'alipay']
}
```

#### 4.2.2 客户端验证

```dart
// 手机号验证
bool isValidPhone(String phone) {
  return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
}

// 密码验证
bool isValidPassword(String password) {
  return password.length >= 8 &&
         password.length <= 20 &&
         RegExp(r'[A-Za-z]').hasMatch(password) &&
         RegExp(r'[0-9]').hasMatch(password);
}

// 验证码验证
bool isValidSmsCode(String code) {
  return RegExp(r'^\d{6}$').hasMatch(code);
}
```

### 4.3 错误处理流程

#### 4.3.1 服务端错误处理

```typescript
// 全局异常过滤器
@Catch()
class GlobalExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse();
    
    let status = 500;
    let code = 500;
    let message = '服务器内部错误';
    
    if (exception instanceof HttpException) {
      status = exception.getStatus();
      code = exception.getCode();
      message = exception.getMessage();
    }
    
    // 记录错误日志
    logger.error({
      requestId: ctx.getRequest().headers['x-request-id'],
      error: exception,
      stack: exception instanceof Error ? exception.stack : undefined,
    });
    
    // 返回统一格式
    response.status(status).json({
      code,
      message,
      data: null,
      timestamp: Date.now(),
      requestId: ctx.getRequest().headers['x-request-id'],
    });
  }
}
```

#### 4.3.2 客户端错误处理

```dart
// 统一错误处理
class ApiErrorHandler {
  static void handle(DioException error) {
    switch (error.response?.statusCode) {
      case 401:
        // Token 过期，尝试刷新
        _tryRefreshToken();
        break;
      case 403:
        // 权限不足，提示升级
        showUpgradeDialog();
        break;
      case 429:
        // 限流，提示稍后再试
        showToast('操作太频繁，请稍后再试');
        break;
      case 500:
        // 服务端错误
        showToast('服务器繁忙，请稍后重试');
        break;
      default:
        // 业务错误码
        final code = error.response?.data['code'];
        final message = error.response?.data['message'];
        _handleBusinessError(code, message);
    }
  }
  
  static void _handleBusinessError(int? code, String? message) {
    switch (code) {
      case 4001: showToast('验证码错误'); break;
      case 4002: showToast('手机号已注册，请直接登录'); break;
      case 4003: showToast('密码错误'); break;
      case 4004: showToast('套餐已过期，请续费'); break;
      case 4005: showToast('额度不足，请购买套餐'); break;
      default: showToast(message ?? '操作失败');
    }
  }
}
```

### 4.4 状态同步机制

#### 4.4.1 订阅状态同步

```dart
// 同步策略：
// 1. App 启动时同步一次
// 2. 每次进入订阅页面时同步
// 3. 支付完成后强制同步
// 4. 后台轮询（每 5 分钟，仅当 App 在前台）

class SubscriptionSync {
  Timer? _pollingTimer;
  
  void startPolling() {
    // 立即同步一次
    _sync();
    
    // 每 5 分钟同步
    _pollingTimer = Timer.periodic(Duration(minutes: 5), (_) => _sync());
  }
  
  Future<void> _sync() async {
    try {
      final subscription = await api.getSubscription();
      // 更新本地状态
      state.subscription = subscription;
      
      // 检查关键状态变化
      if (subscription.isExpired) {
        // 套餐过期，切换为免费版
        eventBus.emit(SubscriptionExpiredEvent());
      }
      
      if (subscription.remainingQuota < 10) {
        // 额度不足预警
        eventBus.emit(QuotaWarningEvent(remaining: subscription.remainingQuota));
      }
    } catch (e) {
      // 同步失败，使用本地缓存（允许短暂不一致）
      logger.w('Subscription sync failed: $e');
    }
  }
}
```

#### 4.4.2 API Key 同步

```dart
// API Key 缓存策略：
// 1. 获取后缓存到安全存储
// 2. 设置过期时间（如 1 小时）
// 3. 过期前自动刷新
// 4. Key 失效时（服务端返回 401）立即刷新

class ApiKeyManager {
  static const Duration _keyValidDuration = Duration(hours: 1);
  
  Future<CloudApiKey> getValidKey() async {
    // 检查缓存
    final cached = await _getCachedKey();
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      return cached;
    }
    
    // 缓存无效，从服务端获取
    final key = await api.getApiKey();
    await _cacheKey(key);
    return key;
  }
  
  Future<void> refreshKey() async {
    await _clearCache();
    await getValidKey();
  }
}
```

### 4.5 权限控制策略

#### 4.5.1 服务端权限控制

```typescript
// JWT 守卫
@Injectable()
class JwtAuthGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const token = this.extractTokenFromHeader(request);
    
    if (!token) {
      throw new UnauthorizedException('Token 不存在');
    }
    
    try {
      const payload = jwt.verify(token, process.env.JWT_SECRET);
      request.user = payload;
      return true;
    } catch {
      throw new UnauthorizedException('Token 无效或已过期');
    }
  }
}

// 订阅权限守卫
@Injectable()
class SubscriptionGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    
    // 查询用户订阅
    const subscription = await this.subscriptionService.findByUserId(user.id);
    
    // 检查订阅是否有效
    if (!subscription || subscription.status !== 'active') {
      throw new ForbiddenException('订阅已过期');
    }
    
    // 检查额度
    if (subscription.remainingQuota <= 0) {
      throw new ForbiddenException('额度不足');
    }
    
    // 将订阅信息附加到请求
    request.subscription = subscription;
    return true;
  }
}

// 使用示例
@Controller('api/v1')
export class ApiKeyController {
  @Get('api-key')
  @UseGuards(JwtAuthGuard, SubscriptionGuard)
  async getApiKey(@Req() req) {
    // 只有登录且订阅有效的用户才能获取 API Key
    return this.apiKeyService.assignKey(req.user.id, req.subscription);
  }
}
```

#### 4.5.2 客户端权限控制

```dart
// 权限检查
class PermissionChecker {
  // 检查是否可以使用 AI 功能
  static Future<bool> canUseAi() async {
    final auth = state.auth;
    final subscription = state.subscription;
    
    // 已登录 + 订阅有效
    if (auth.isLoggedIn && subscription.isActive) {
      return subscription.remainingQuota > 0;
    }
    
    // 未登录，检查本地 API 配置
    if (!auth.isLoggedIn) {
      return state.localConfig != null;
    }
    
    return false;
  }
  
  // 检查是否可以使用高级功能
  static bool canUseAdvancedFeatures() {
    final subscription = state.subscription;
    return subscription.planId == 'pro' || subscription.planId == 'enterprise';
  }
}

// UI 权限控制
class FeatureGate extends StatelessWidget {
  final String feature;
  final Widget child;
  final Widget? fallback;
  
  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final canAccess = PermissionChecker.canAccess(feature);
      
      if (canAccess) return child;
      
      return fallback ?? UpgradePrompt(feature: feature);
    });
  }
}
```

---

## 五、安全机制

### 5.1 传输安全

| 措施 | 实现 |
|------|------|
| HTTPS | 全站 TLS 1.2+，HSTS 头部 |
| 证书固定 | 客户端内置服务端证书公钥指纹 |
| 请求签名 | 敏感接口增加 HMAC-SHA256 签名 |

### 5.2 认证安全

| 措施 | 实现 |
|------|------|
| JWT | Access Token 15分钟 + Refresh Token 7天 |
| Token 存储 | Access Token 内存，Refresh Token Keychain |
| 设备绑定 | 登录时记录设备指纹 |
| 异常检测 | 异地登录触发二次验证 |

### 5.3 数据安全

| 措施 | 实现 |
|------|------|
| 密码存储 | bcrypt (cost=12) |
| API Key 存储 | AES-256-GCM 加密 |
| 手机号存储 | 加密存储，日志脱敏 |
| 本地数据 | 敏感数据加密后存储 |

### 5.4 限流策略

```typescript
// 服务端限流
const rateLimits = {
  'auth.register': { windowMs: 60 * 60 * 1000, max: 5 },      // 每小时 5 次
  'auth.login': { windowMs: 15 * 60 * 1000, max: 10 },        // 每 15 分钟 10 次
  'auth.smsCode': { windowMs: 60 * 1000, max: 1 },            // 每分钟 1 次
  'apiKey.get': { windowMs: 60 * 1000, max: 10 },             // 每分钟 10 次
  'default': { windowMs: 60 * 1000, max: 100 },               // 默认每分钟 100 次
};
```

---

## 六、接口清单

### 6.1 Auth 接口

| 方法 | 路径 | 认证 | 说明 |
|------|------|------|------|
| POST | /api/v1/auth/register | 否 | 注册 |
| POST | /api/v1/auth/login | 否 | 登录（密码） |
| POST | /api/v1/auth/login-sms | 否 | 快捷登录（验证码） |
| POST | /api/v1/auth/refresh | 否 | 刷新 Token |
| POST | /api/v1/auth/logout | 是 | 登出 |
| POST | /api/v1/auth/forgot-password | 否 | 忘记密码 |
| POST | /api/v1/auth/reset-password | 否 | 重置密码 |
| POST | /api/v1/auth/send-sms-code | 否 | 发送验证码 |
| GET | /api/v1/auth/me | 是 | 获取当前用户 |
| PUT | /api/v1/auth/profile | 是 | 更新用户资料 |

### 6.2 Subscription 接口

| 方法 | 路径 | 认证 | 说明 |
|------|------|------|------|
| GET | /api/v1/subscription | 是 | 获取当前订阅 |
| GET | /api/v1/plans | 否 | 获取套餐列表 |
| GET | /api/v1/plans/:id | 否 | 获取套餐详情 |
| GET | /api/v1/usage | 是 | 获取使用记录 |

### 6.3 ApiKey 接口

| 方法 | 路径 | 认证 | 说明 |
|------|------|------|------|
| GET | /api/v1/api-key | 是 | 获取 API Key |
| POST | /api/v1/api-key/refresh | 是 | 刷新 API Key |

### 6.4 Payment 接口

| 方法 | 路径 | 认证 | 说明 |
|------|------|------|------|
| POST | /api/v1/orders | 是 | 创建订单 |
| GET | /api/v1/orders/:id | 是 | 查询订单 |
| POST | /api/v1/orders/:id/cancel | 是 | 取消订单 |
| POST | /api/v1/payment/wechat/prepay | 是 | 微信支付预下单 |
| POST | /api/v1/payment/alipay/prepay | 是 | 支付宝预下单 |
| POST | /api/v1/payment/notify/wechat | 否 | 微信支付回调 |
| POST | /api/v1/payment/notify/alipay | 否 | 支付宝回调 |

---

## 七、客户端-服务端交互时序图

### 7.1 完整登录 + 使用 AI 流程

```
用户       客户端                    服务端              AI服务商
 │          │                         │                   │
 │          │  1. 输入手机号+密码      │                   │
 │          │────────────────────────>│                   │
 │          │                         │                   │
 │          │  2. 返回 JWT Token      │                   │
 │          │<────────────────────────│                   │
 │          │                         │                   │
 │          │  3. 获取订阅状态         │                   │
 │          │────────────────────────>│                   │
 │          │                         │                   │
 │          │  4. 返回订阅信息         │                   │
 │          │<────────────────────────│                   │
 │          │                         │                   │
 │  点击录音 │                         │                   │
 │          │                         │                   │
 │          │  5. 获取 API Key        │                   │
 │          │────────────────────────>│                   │
 │          │                         │                   │
 │          │  6. 返回 API Key        │                   │
 │          │<────────────────────────│                   │
 │          │                         │                   │
 │          │  7. 本地录音             │                   │
 │          │─────────────────────────┼──────────────────>│
 │          │                         │                   │
 │          │  8. 返回转写结果         │                   │
 │          │<────────────────────────┼───────────────────│
 │          │                         │                   │
 │  查看结果 │                         │                   │
```

---

*文档版本：v1.0*
*更新日期：2026-05-13*
*状态：待确认*
