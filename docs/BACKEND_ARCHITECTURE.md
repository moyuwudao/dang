# 畅记云后端管理系统架构文档

> **服务器**: 101.133.238.249 (changji)
> **用户**: admin
> **最后更新**: 2026-06-01
> **用途**: 后端架构全景图、模块说明、部署路径速查

---

## 一、架构总览

```
┌──────────────────────────────────────────────────────────────┐
│                     NestJS 后端服务 (API)                     │
│                     changji-api (PM2)                         │
│                     PID: 525081 | Status: online              │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   Auth   │  │ Subscription│  │ ApiKey   │  │  Admin   │   │
│  │  (认证)   │  │  (订阅计费) │  │ (密钥管理)│  │ (管理后台)│   │
│  ├──────────┤  ├──────────┤  ├──────────┤  ├──────────┤   │
│  │JWT Guard │  │Plan/Token│  │Key CRUD  │  │用户管理   │   │
│  │SMS验证码 │  │计费系统   │  │限流拦截器 │  │订阅管理   │   │
│  │User实体  │  │充值记录   │  │多Provider│  │API密钥审计│   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Payment │  │    AI    │  │  Monitor │  │  Redis   │   │
│  │  (支付)   │  │ (AI路由)  │  │  (监控)   │  │  (缓存)   │   │
│  ├──────────┤  ├──────────┤  ├──────────┤  ├──────────┤   │
│  │微信支付   │  │多Provider│  │指标采集   │  │ioredis   │   │
│  │支付宝    │  │智能路由   │  │服务状态   │  │连接池    │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              PostgreSQL  +  TypeORM                   │   │
│  │  User | ApiKey | Subscription | Plan | RechargeRecord │   │
│  │  ApiUsageLog | TokenPricing | AuditLog                │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 二、核心模块详解

### 2.1 AppModule (根模块)

**文件**: `server/src/app.module.ts`

```typescript
@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, envFilePath: '.env' }),
    TypeOrmModule.forRoot({ type: 'postgres', host: 'localhost', port: 5432, ... }),
    ScheduleModule.forRoot(),
    AuthModule,
    SubscriptionModule,
    ApiKeyModule,
    AdminModule,
    MonitorModule,
    RedisModule,
    AiModule,
    PaymentModule,
    PlanModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_INTERCEPTOR, useClass: ResponseInterceptor },
  ],
})
```

**全局配置**:
- `ConfigModule` — 全局环境变量
- `TypeOrmModule` — PostgreSQL 数据库连接
- `ScheduleModule` — 定时任务（Token计费结算）
- `JwtAuthGuard` — 全局 JWT 认证守卫
- `ResponseInterceptor` — 全局响应格式化拦截器

---

### 2.2 AuthModule (认证模块)

**文件**: `server/src/auth/`

| 文件 | 用途 |
|------|------|
| `auth.controller.ts` | 登录/注册/刷新Token接口 |
| `auth.service.ts` | JWT签发、Token验证 |
| `sms.service.ts` | 阿里云SMS验证码发送 |
| `user.entity.ts` | User实体（id, phone, role, passwordHash） |
| `jwt-auth.guard.ts` | JWT认证守卫 |
| `admin.guard.ts` | 管理员权限守卫 |

**核心流程**:
```
用户注册 → 发送SMS验证码 → 验证手机 → 创建User
用户登录 → 验证密码/SMS → 签发JWT → 返回Token
API请求 → JwtAuthGuard验证Token → 注入User到Request
```

---

### 2.3 SubscriptionModule (订阅计费核心)

**文件**: `server/src/subscription/`

**核心服务**:
| 服务 | 用途 |
|------|------|
| `subscription.service.ts` | 订阅CRUD、套餐管理 |
| `subscription-scheduler.service.ts` | 定时结算、过期检查 |
| `token-billing.service.ts` | Token计费系统（核心） |

**数据库实体**:
| 实体 | 表名 | 用途 |
|------|------|------|
| `Subscription` | subscriptions | 用户订阅记录 |
| `Plan` | plans | 套餐定义（免费/月付/年付） |
| `UserTokenBalance` | user_token_balances | 用户Token余额 |
| `RechargeRecord` | recharge_records | 充值记录 |
| `ApiUsageLog` | api_usage_logs | API调用日志 |
| `TokenPricing` | token_pricings | Token定价表 |
| `ApiConfig` | api_configs | API配置 |

**Token计费逻辑**:
```
用户发起AI请求 → AiService调用TokenBillingService
→ 查询UserTokenBalance
→ 扣除对应Token数量
→ 记录ApiUsageLog
→ 返回剩余余额
```

---

### 2.4 ApiKeyModule (API密钥管理)

**文件**: `server/src/api-key/`

**核心功能**:
- 多Provider密钥池管理（OpenAI/Anthropic/Gemini/DeepSeek/Grok/通义千问）
- 密钥加密存储（apiKeyEncrypted）
- 日配额/使用量追踪
- 健康状态检查
- 限流拦截器（rate-limit.interceptor.ts）

**实体关键字段**:
```typescript
@Entity('api_keys')
class ApiKey {
  provider: ApiKeyProvider;      // qwen/openai/anthropic/gemini/deepseek/grok
  status: ApiKeyStatus;          // active/inactive/expired/revoked
  dailyQuota: number;            // 日配额（默认1000）
  dailyUsage: number;            // 日使用量
  lastHealthCheckStatus: string; // healthy/unhealthy
  scopes: ApiKeyScope[];         // transcription/summary/chat/translation/all
}
```

---

### 2.5 AiModule (AI服务统一路由)

**文件**: `server/src/ai/`

**核心服务**: `AiRouterService`

**多Provider智能降级链**:
```
OpenAI → Anthropic → Gemini → Grok → DeepSeek → 通义千问
  ↓         ↓          ↓        ↓        ↓          ↓
gpt-3.5  claude-3  gemini   grok   deepseek   qwen-plus
```

**路由策略**:
1. 用户指定 provider → 优先使用该 provider 的可用 Key
2. Key 不可用 + fallbackEnabled → 自动切换到降级链中的下一个
3. 未指定 provider → 按降级链选择使用率最低的可用 Key

**选择算法**:
```typescript
keys.sort((a, b) => {
  const usageA = a.dailyUsage / (a.dailyQuota || 1);
  const usageB = b.dailyUsage / (b.dailyQuota || 1);
  return usageA - usageB;
})[0]; // 选择使用率最低的Key
```

**支持的Provider**:
| Provider | 默认模型 | Base URL |
|---------|---------|---------|
| OpenAI | gpt-3.5-turbo | api.openai.com |
| Anthropic | claude-3-haiku | api.anthropic.com |
| Gemini | gemini-pro | generativelanguage.googleapis.com |
| Grok | grok-beta | api.x.ai |
| DeepSeek | deepseek-chat | api.deepseek.com |
| 通义千问 | qwen-plus | dashscope.aliyuncs.com |

---

### 2.6 PaymentModule (支付模块)

**文件**: `server/src/payment/`

| 服务 | 用途 |
|------|------|
| `wechat-pay.service.ts` | 微信支付对接 |
| `alipay.service.ts` | 支付宝对接 |
| `payment.service.ts` | 支付订单处理 |
| `payment.controller.ts` | 支付回调接口 |

---

### 2.7 AdminModule (管理后台API)

**文件**: `server/src/admin/`

| 文件 | 用途 |
|------|------|
| `admin.controller.ts` | 用户/订阅/订单/统计接口 |
| `admin.service.ts` | 管理后台业务逻辑 |
| `audit.service.ts` | 审计日志服务 |
| `audit.interceptor.ts` | 操作审计拦截器 |
| `audit-log.entity.ts` | 审计日志实体 |

**权限**: 需要 `AdminGuard`（role === 'admin'）

---

### 2.8 MonitorModule (监控模块)

**文件**: `server/src/monitor/`

| 文件 | 用途 |
|------|------|
| `monitor.controller.ts` | 系统状态/API统计接口 |
| `monitor.service.ts` | 数据采集 |
| `metrics.service.ts` | 指标计算 |

---

### 2.9 RedisModule (缓存模块)

**文件**: `server/src/redis/`

```typescript
RedisModule.forRoot({
  type: 'single',
  url: `redis://:${process.env.REDIS_PASSWORD}@localhost:6379`,
})
```

---

## 三、数据库实体关系图

```
┌──────────────┐     ┌─────────────────┐     ┌──────────────┐
│    User      │────▶│   Subscription  │────▶│     Plan     │
│  (用户表)     │     │   (订阅表)       │     │   (套餐表)    │
├──────────────┤     ├─────────────────┤     ├──────────────┤
│ id (PK)      │     │ id (PK)         │     │ id (PK)      │
│ phone        │     │ userId (FK)     │     │ name         │
│ role         │     │ planId (FK)     │     │ description  │
│ passwordHash │     │ status          │     │ price        │
└──────────────┘     │ expiresAt       │     │ tokenQuota   │
       │             └─────────────────┘     └──────────────┘
       │
       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ApiKey        │    │ RechargeRecord  │    │ ApiUsageLog     │
│  (API密钥池)     │    │   (充值记录)     │    │  (API使用日志)   │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ id (PK)         │    │ id (PK)         │    │ id (PK)         │
│ provider        │    │ userId (FK)     │    │ userId (FK)     │
│ apiKeyEncrypted │    │ amount          │    │ provider        │
│ status          │    │ paymentMethod   │    │ model           │
│ dailyQuota      │    │ status          │    │ promptTokens    │
│ dailyUsage      │    │ createdAt       │    │ completionTokens│
└─────────────────┘    └─────────────────┘    │ tokenConsumed   │
                                              │ costYuan        │
                                              └─────────────────┘
                                                       ▲
                                                       │
                                              ┌────────┘
                                              │
                                       ┌──────────────┐
                                       │ UserTokenBalance│
                                       │ (用户Token余额)  │
                                       ├──────────────┤
                                       │ userId (FK)  │
                                       │ balance      │
                                       │ freeTokens   │
                                       └──────────────┘
                                              ▲
                                              │
                                       ┌──────────────┐
                                       │ TokenPricing │
                                       │  (Token定价)  │
                                       ├──────────────┤
                                       │ provider     │
                                       │ model        │
                                       │ pricePer1K   │
                                       └──────────────┘
```

---

## 四、部署路径速查

### 4.1 服务器路径

| 用途 | 路径 | 说明 |
|------|------|------|
| 项目根目录 | `/home/admin/` | SSH 登录后默认目录 |
| 后端源码 | `/home/admin/dang/server/` | NestJS 源代码 |
| 后端编译产物 | `/home/admin/dang/server/dist/` | `npm run build` 输出 |
| 实际运行目录 | `/opt/changji-cloud/api/` | PM2 cwd 配置 |
| PM2 日志 | `/home/admin/.pm2/logs/` | changji-api-error.log / out.log |
| 环境变量 | `/opt/changji-cloud/api/.env` | DB/Redis/API Key 密码 |
| PM2 配置 | `/opt/changji-cloud/api/ecosystem.config.js` | 进程管理配置 |
| 部署脚本 | `/home/admin/deploy-server.sh` | 一键部署脚本 |

### 4.2 部署脚本 (deploy-server.sh)

```bash
#!/bin/bash
# 1. 停止服务
pm2 stop changji-api

# 2. 同步编译产物到运行目录
rsync -avz --delete /home/admin/dang/server/dist/ /opt/changji-cloud/api/dist/

# 3. 重启服务
pm2 restart changji-api

# 4. 检查状态
pm2 status changji-api
```

### 4.3 PM2 配置 (ecosystem.config.js)

```javascript
module.exports = {
  apps: [{
    name: 'changji-api',
    script: './dist/src/main.js',
    cwd: '/opt/changji-cloud/api',
    env: {
      NODE_ENV: 'production',
      REDIS_HOST: 'localhost',
      REDIS_PORT: 6379,
      REDIS_PASSWORD: 'Redis123456',
    },
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    error_file: '/home/admin/.pm2/logs/changji-api-error.log',
    out_file: '/home/admin/.pm2/logs/changji-api-out.log',
  }],
};
```

---

## 五、服务状态

### 5.1 PM2 进程状态

```
┌────┬─────────────┬──────────┬─────────┬────────┬────────┬──────────┐
│ id │ name        │ pid      │ uptime  │ status │ cpu    │ mem      │
├────┼─────────────┼──────────┼─────────┼────────┼────────┼──────────┤
│ 0  │ changji-api │ 525081   │ online  │ online │ 200%   │ 70.5MB   │
└────┴─────────────┴──────────┴─────────┴────────┴────────┴──────────┘
```

| 指标 | 值 |
|------|-----|
| 状态 | `online` ✅ |
| PID | `525081` |
| 内存 | `70.5MB` |
| CPU | `200%` |
| 用户 | `admin` |

### 5.2 监听端口

| 端口 | 服务 | 状态 |
|------|------|------|
| 3000 | NestJS API | 运行中 ✅ |

### 5.3 软件版本

| 软件 | 版本 |
|------|------|
| Node.js | v20.20.2 |
| npm | 10.8.2 |
| PM2 | 7.0.1 |
| NestJS | 10.x |
| TypeORM | 0.3.x |
| PostgreSQL | 14.x |
| Redis | 6.x |

---

## 六、管理后台 (admin/)

### 6.1 技术栈

- **框架**: Next.js + NextUI + TailwindCSS
- **部署方式**: 静态导出 (`next export`)
- **部署路径**: `/var/www/html/admin/`

### 6.2 页面结构

| 页面 | 路径 | 用途 |
|------|------|------|
| 登录页 | `/login` | 管理员登录 |
| 仪表盘 | `/dashboard` | 数据总览 |
| 用户管理 | `/users` | 用户列表/管理 |
| 订阅管理 | `/subscriptions` | 套餐/订阅管理 |
| API密钥 | `/api-keys` | 密钥池管理 |
| API策略 | `/api-policies` | 策略配置 |
| 收入统计 | `/revenue` | 充值/收入数据 |
| 数据分析 | `/analytics` | 使用统计 |
| 系统监控 | `/monitor` | 服务状态 |
| 服务器监控 | `/server-monitor` | 服务器资源 |
| 系统设置 | `/settings` | 配置管理 |

### 6.3 API 服务层

**文件**: `admin/services/api.ts` (67 symbols)

---

## 七、相关文档

| 文档 | 路径 | 用途 |
|------|------|------|
| 服务器目录结构 | [SERVER_DIRECTORY.md](SERVER_DIRECTORY.md) | 目录树、文件清单 |
| 部署规范 | [.trae/rules/SERVER_DEPLOY.md](../.trae/rules/SERVER_DEPLOY.md) | 部署流程、已知问题 |
| 运维规范 | [.trae/rules/SERVER_OPS.md](../.trae/rules/SERVER_OPS.md) | 日常检查、日志管理 |
| API 规范 | [.trae/rules/SERVER_API.md](../.trae/rules/SERVER_API.md) | 接口说明 |
| 安全红线 | [.trae/rules/RED_LINES.md](../.trae/rules/RED_LINES.md) | 禁止操作 |

---

*本文件由 AI 自动维护，每次部署后应更新服务状态和路径信息。*
