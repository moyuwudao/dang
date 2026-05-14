# 畅记 App - 技术架构设计（确认版）

## 决策确认

| 问题 | 决策 |
|------|------|
| 后端技术栈 | Node.js + NestJS（开发快、生态成熟、可扩展） |
| 数据库 | PostgreSQL（主库）+ Redis（缓存/队列） |
| 云服务商 | 阿里云（语音转录绑定） |
| 用户规模 | 初期 1K DAU，按 10K DAU 设计容量 |
| 模式支持 | **双模式**：不登录可用自有 API；登录后可用自有 API + 云服务 |
| 合规要求 | 需要 ICP 备案、等保测评、数据合规 |
| 商业化节奏 | 同步上线：免费版（自有 API）+ 付费云服务 |

---

## 一、整体架构

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              客户端层 (Flutter)                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   登录/注册    │  │   录音笔记    │  │   AI 分析    │  │   个人中心    │    │
│  │  (云端账户)    │  │  (本地优先)   │  │ (双模式路由)  │  │ (余额/套餐)   │    │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘    │
│         │                 │                  │               │              │
│         └─────────────────┴──────────────────┴───────────────┘              │
│                                    │                                        │
│                         ┌─────────────────┐                                 │
│                         │   本地 SQLite    │                                 │
│                         │  (Drift ORM)    │                                 │
│                         └─────────────────┘                                 │
│                                    │                                        │
│                         ┌─────────────────┐                                 │
│                         │   双模式路由层    │                                 │
│                         │ 自有API / 云端AI  │                                 │
│                         └─────────────────┘                                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                          │ HTTPS / WSS
                                          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           接入层 (阿里云)                                     │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  SLB (负载均衡)  →  ECS/容器服务 (NestJS API Gateway)                │   │
│  │  CDN (静态资源)  →  OSS (文件存储)                                    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                          │
        ┌─────────────────────────────────┼─────────────────────────────────┐
        ▼                                 ▼                                 ▼
┌───────────────┐              ┌───────────────┐              ┌───────────────┐
│   账户服务     │              │   同步服务     │              │   AI 代理服务  │
│  Auth Service │              │  Sync Service │              │  AI Proxy Svc │
│  (NestJS)     │              │  (NestJS)     │              │  (NestJS)     │
└───────────────┘              └───────────────┘              └───────────────┘
        │                                 │                                 │
        ▼                                 ▼                                 ▼
┌───────────────┐              ┌───────────────┐              ┌───────────────┐
│   计费服务     │              │   文件服务     │              │   消息队列     │
│ Billing Svc   │              │  File Service │              │  (RabbitMQ)   │
│  (NestJS)     │              │  (OSS封装)    │              │               │
└───────────────┘              └───────────────┘              └───────────────┘
        │                                 │                                 │
        └─────────────────────────────────┼─────────────────────────────────┘
                                          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           数据层 (阿里云)                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   RDS PostgreSQL │  │   Redis         │  │   OSS           │             │
│  │   (主从架构)      │  │   (缓存/会话)    │  │   (文件存储)     │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
└─────────────────────────────────────────────────────────────────────────────┘
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           第三方服务                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  阿里云语音   │  │  OpenAI     │  │  微信支付    │  │  支付宝      │        │
│  │  (ASR/NLS)   │  │  /DeepSeek  │  │  (JSAPI)    │  │  (手机网站)   │        │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 二、后端服务拆分（NestJS 微服务）

### 2.1 服务划分

| 服务 | 职责 | 端口 | 依赖 |
|------|------|------|------|
| `api-gateway` | 路由、鉴权、限流、日志 | 3000 | 所有服务 |
| `auth-service` | 注册、登录、Token、设备管理 | 3001 | PostgreSQL, Redis |
| `sync-service` | 数据同步、冲突解决、版本管理 | 3002 | PostgreSQL, Redis, OSS |
| `ai-proxy-service` | AI 调用代理、熔断、降级 | 3003 | Redis, 阿里云语音, OpenAI |
| `billing-service` | 计费、充值、套餐、订阅 | 3004 | PostgreSQL, Redis |
| `payment-service` | 支付对接、回调、对账 | 3005 | PostgreSQL, 微信/支付宝 |
| `notification-service` | 推送、短信、邮件 | 3006 | Redis, 阿里云短信 |

### 2.2 通信方式
- **同步**：HTTP REST / gRPC（服务间调用）
- **异步**：RabbitMQ（事件驱动：支付成功、额度预警、同步触发）

### 2.3 共享模块（NestJS Library）
```
libs/
├── shared/                 # 公共工具
│   ├── decorators/         # 自定义装饰器
│   ├── filters/            # 异常过滤器
│   ├── guards/             # 鉴权守卫
│   ├── interceptors/       # 拦截器
│   └── pipes/              # 校验管道
├── database/               # 数据库模块
│   ├── entities/           # TypeORM 实体
│   ├── migrations/         # 迁移脚本
│   └── database.module.ts
├── config/                 # 配置管理
│   └── configuration.ts
└── logger/                 # 日志模块
    └── logger.module.ts
```

---

## 三、数据库设计（PostgreSQL）

### 3.1 ER 关系图

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│    users    │◄──────┤  user_balances│      │subscriptions│
│  (用户表)    │       │  (余额表)     │      │  (订阅表)    │
└─────────────┘       └─────────────┘       └─────────────┘
        │
        │ 1:N
        ▼
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│   devices   │       │  transactions│      │    orders   │
│  (设备表)    │       │  (交易流水)   │      │  (订单表)    │
└─────────────┘       └─────────────┘       └─────────────┘
        │
        │ 1:N
        ▼
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│ sync_records│       │  api_usage   │      │ package_usage│
│  (同步记录)  │       │  (API用量)   │      │  (套餐用量)   │
└─────────────┘       └─────────────┘       └─────────────┘
```

### 3.2 核心表结构

#### users（用户表）
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) UNIQUE,
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255),
    nickname VARCHAR(50) DEFAULT '用户',
    avatar_url TEXT,
    auth_provider VARCHAR(20) NOT NULL DEFAULT 'phone', -- phone, email, wechat, apple
    third_party_openid VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'active', -- active, suspended, deleted
    device_limit INT NOT NULL DEFAULT 3,
    free_transcription_minutes INT NOT NULL DEFAULT 30, -- 每月免费转写分钟数
    free_analysis_count INT NOT NULL DEFAULT 10, -- 每月免费分析次数
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_login_at TIMESTAMPTZ
);

CREATE INDEX idx_users_phone ON users(phone) WHERE phone IS NOT NULL;
CREATE INDEX idx_users_email ON users(email) WHERE email IS NOT NULL;
CREATE INDEX idx_users_third_party ON users(auth_provider, third_party_openid);
```

#### user_balances（用户余额表）
```sql
CREATE TABLE user_balances (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    balance_cents INT NOT NULL DEFAULT 0, -- 充值余额（分）
    total_recharged_cents INT NOT NULL DEFAULT 0, -- 累计充值
    total_consumed_cents INT NOT NULL DEFAULT 0, -- 累计消费
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

#### subscriptions（订阅表）
```sql
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan VARCHAR(20) NOT NULL, -- free, pro, team
    status VARCHAR(20) NOT NULL DEFAULT 'active', -- active, cancelled, expired
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    auto_renew BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status, expires_at);
```

#### transactions（交易流水表）
```sql
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(30) NOT NULL, -- recharge, consume, refund, bonus, subscription_renewal
    amount_cents INT NOT NULL, -- 正数收入，负数支出
    balance_after_cents INT NOT NULL,
    description TEXT NOT NULL,
    related_id VARCHAR(100), -- 关联订单ID或API调用ID
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_transactions_user ON transactions(user_id, created_at DESC);
CREATE INDEX idx_transactions_type ON transactions(type, created_at DESC);
```

#### orders（订单表）
```sql
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    order_no VARCHAR(32) NOT NULL UNIQUE, -- CJ202501011200000001
    product_type VARCHAR(20) NOT NULL, -- package, subscription, recharge
    product_id VARCHAR(50) NOT NULL, -- 产品标识
    product_name VARCHAR(100) NOT NULL,
    amount_cents INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, paid, cancelled, refunded
    payment_channel VARCHAR(20), -- wechat, alipay
    payment_time TIMESTAMPTZ,
    third_party_order_no VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_user ON orders(user_id, created_at DESC);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_third_party ON orders(third_party_order_no);
```

#### api_usage（API 用量表）
```sql
CREATE TABLE api_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    function_type VARCHAR(30) NOT NULL, -- transcription, analysis, image, tool
    provider VARCHAR(30) NOT NULL, -- aliyun_asr, openai, deepseek
    input_length INT, -- 输入字符数/token数
    output_length INT, -- 输出字符数/token数
    duration_seconds INT, -- 音频时长（转写用）
    cost_cents INT NOT NULL, -- 本次调用成本（分）
    source VARCHAR(20) NOT NULL DEFAULT 'cloud', -- cloud(云端), local(自有API)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_api_usage_user ON api_usage(user_id, created_at DESC);
CREATE INDEX idx_api_usage_function ON api_usage(function_type, created_at DESC);
CREATE INDEX idx_api_usage_created ON api_usage(created_at);
```

#### sync_records（同步记录表）
```sql
CREATE TABLE sync_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(100) NOT NULL,
    table_name VARCHAR(50) NOT NULL, -- records, tool_outputs
    local_id VARCHAR(100) NOT NULL, -- 客户端本地ID
    cloud_id VARCHAR(100), -- 服务端分配ID
    operation VARCHAR(10) NOT NULL, -- create, update, delete
    data_hash VARCHAR(64) NOT NULL, -- SHA256 of data
    data JSONB, -- 完整数据快照
    synced_at TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, success, conflict, failed
    conflict_resolution VARCHAR(20), -- client_wins, server_wins, merged
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sync_records_user ON sync_records(user_id, table_name);
CREATE INDEX idx_sync_records_status ON sync_records(status, synced_at);
CREATE INDEX idx_sync_records_device ON sync_records(device_id, created_at DESC);
```

#### devices（设备表）
```sql
CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(100) NOT NULL,
    device_name VARCHAR(100),
    device_type VARCHAR(20), -- android, ios, windows, macos, linux
    push_token TEXT,
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, device_id)
);

CREATE INDEX idx_devices_user ON devices(user_id);
CREATE INDEX idx_devices_active ON devices(last_active_at);
```

---

## 四、API 设计（RESTful）

### 4.1 认证相关

```
POST   /api/v1/auth/register          # 注册（手机/邮箱）
POST   /api/v1/auth/login             # 登录（密码）
POST   /api/v1/auth/login-sms         # 快捷登录（验证码）
POST   /api/v1/auth/refresh           # 刷新 Token
POST   /api/v1/auth/logout            # 登出
POST   /api/v1/auth/forgot-password   # 忘记密码
POST   /api/v1/auth/reset-password    # 重置密码
POST   /api/v1/auth/send-sms-code     # 发送验证码
GET    /api/v1/auth/me                # 获取当前用户信息
PUT    /api/v1/auth/profile           # 更新用户资料
```

### 4.2 云服务相关

```
POST   /api/v1/sync/push              # 推送本地变更
POST   /api/v1/sync/pull              # 拉取云端变更
POST   /api/v1/sync/resolve-conflict  # 解决冲突
GET    /api/v1/sync/status            # 获取同步状态

POST   /api/v1/ai/transcribe         # 语音转写（云端代理）
POST   /api/v1/ai/analyze            # AI 分析（云端代理）
POST   /api/v1/ai/ocr                # 图像识别（云端代理）
POST   /api/v1/ai/tool               # 工作台工具（云端代理）
GET    /api/v1/ai/usage              # 获取 AI 用量统计
```

### 4.3 计费相关

```
GET    /api/v1/billing/balance        # 获取余额
GET    /api/v1/billing/transactions   # 获取交易流水
GET    /api/v1/billing/packages       # 获取可购买套餐
GET    /api/v1/billing/subscription   # 获取当前订阅
POST   /api/v1/billing/order          # 创建订单
GET    /api/v1/billing/order/:id      # 查询订单
POST   /api/v1/billing/order/:id/cancel  # 取消订单

POST   /api/v1/payment/wechat/prepay  # 微信支付预下单
POST   /api/v1/payment/alipay/prepay  # 支付宝预下单
POST   /api/v1/payment/notify/wechat  # 微信支付回调
POST   /api/v1/payment/notify/alipay  # 支付宝回调
```

### 4.4 请求/响应规范

```typescript
// 统一响应格式
interface ApiResponse<T> {
  code: number;        // 业务状态码
  message: string;     // 提示信息
  data: T;             // 数据
  timestamp: number;   // 时间戳
  requestId: string;   // 请求追踪ID
}

// 认证头
Authorization: Bearer <JWT_TOKEN>

// 分页参数
?page=1&pageSize=20

// 分页响应
interface PaginatedResponse<T> {
  list: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}
```

---

## 五、双模式路由设计

### 5.1 核心逻辑

```dart
enum AiServiceMode {
  local,    // 使用用户自配置的 API Key
  cloud,    // 使用云端 AI 代理（需登录）
}

class AiServiceRouter {
  final Ref ref;
  
  AiServiceRouter(this.ref);
  
  /// 获取当前有效的 AI 服务模式
  Future<AiServiceMode> getEffectiveMode() async {
    final user = await ref.read(authProvider.future);
    final hasLocalConfig = await _hasLocalApiConfig();
    
    if (user != null) {
      // 已登录：优先使用云端（如果用户选择）
      final userPreference = await _getUserModePreference();
      if (userPreference == AiServiceMode.cloud) {
        // 检查用户是否有额度
        final hasQuota = await _checkUserQuota();
        if (hasQuota) return AiServiceMode.cloud;
      }
    }
    
    // 未登录 或 选择本地模式 或 云端无额度
    if (hasLocalConfig) return AiServiceMode.local;
    
    // 无任何可用模式
    throw NoAiServiceAvailableException();
  }
  
  /// 统一调用入口
  Future<String> callAi({
    required AiFunctionType function,
    required dynamic input,
    required AiServiceMode? preferredMode,
  }) async {
    final mode = preferredMode ?? await getEffectiveMode();
    
    switch (mode) {
      case AiServiceMode.local:
        return _callLocalAi(function, input);
      case AiServiceMode.cloud:
        return _callCloudAi(function, input);
    }
  }
}
```

### 5.2 用户配置持久化

```dart
// 存储用户选择的模式偏好
enum UserAiPreference {
  auto,      // 自动选择（登录用云端，未登录用本地）
  localOnly, // 始终使用本地 API
  cloudOnly, // 始终使用云端（未登录时提示登录）
}

// SharedPreferences keys
const String KEY_AI_PREFERENCE = 'ai_service_preference';
const String KEY_LAST_CLOUD_TOKEN = 'cloud_auth_token';
const String KEY_CLOUD_REFRESH_TOKEN = 'cloud_refresh_token';
```

---

## 六、安全设计

### 6.1 认证安全
- JWT Token：Access Token（15分钟）+ Refresh Token（7天）
- Token 存储：Access Token 内存，Refresh Token Keychain/Keystore
- 设备绑定：登录时记录设备指纹，异常设备需二次验证
- 短信限流：同一手机号 1分钟1条，1小时5条，1天10条

### 6.2 数据安全
- 传输加密：全站 HTTPS，TLS 1.3
- 存储加密：
  - 密码：bcrypt (cost=12)
  - 手机号/邮箱：AES-256-GCM 加密存储
  - 第三方 OpenID：AES-256-GCM 加密存储
- 数据库连接：SSL 连接 + 最小权限原则

### 6.3 API 安全
- 限流：IP 级 100/min，用户级 1000/min
- 防重放：请求时间戳校验 ±5分钟
- 签名：敏感接口增加 HMAC-SHA256 签名
- CORS：严格白名单

### 6.4 支付安全
- 支付回调：IP 白名单 + 签名验证
- 金额校验：回调金额与订单金额严格比对
- 幂等处理：同一订单号只处理一次
- 敏感信息：支付密钥仅服务端持有

---

## 七、阿里云资源配置

### 7.1 基础资源

| 资源 | 规格 | 数量 | 用途 |
|------|------|------|------|
| ECS | 2核4G | 2台 | 应用服务器 |
| RDS PostgreSQL | 2核4G 100G SSD | 1实例 | 主数据库 |
| Redis | 1G 主从 | 1实例 | 缓存/会话 |
| OSS | 标准存储 | 1Bucket | 文件存储 |
| SLB | 按量计费 | 1个 | 负载均衡 |
| CDN | 按流量 | 1个 | 静态加速 |

### 7.2 阿里云语音服务
- **产品**：智能语音交互（NLS）
- **能力**：
  - 一句话识别（短音频）
  - 实时语音识别（WebSocket 流式）
  - 录音文件识别（长音频异步）
- **计费**：按调用时长，约 ¥0.018-0.036/分钟

### 7.3 预估月成本（1K DAU）

| 项目 | 预估月费用 |
|------|-----------|
| ECS (2台) | ¥300 |
| RDS PostgreSQL | ¥400 |
| Redis | ¥150 |
| OSS (100G) | ¥50 |
| SLB + CDN | ¥100 |
| 阿里云语音（30000分钟） | ¥540 |
| OpenAI API（文本分析） | ¥300 |
| **基础设施合计** | **¥1840** |
| **AI 调用成本** | **¥840** |
| **总计** | **¥2680** |

---

## 八、合规方案

### 8.1 ICP 备案
- 购买阿里云域名 + 服务器
- 提交备案申请（约 7-20 工作日）
- 备案完成后方可上线付费功能

### 8.2 等保测评
- 建议等级：等保二级（用户信息 < 10万）
- 测评内容：物理安全、网络安全、主机安全、应用安全、数据安全
- 周期：首次测评 2-3 个月，每年复测

### 8.3 隐私合规
- 隐私政策：明确数据收集范围、用途、存储期限
- 用户协议：服务条款、付费规则、退款政策
- 数据删除：用户注销后 30 天内删除所有数据
- 数据导出：提供数据导出功能

### 8.4 支付合规
- 使用正规支付服务商（微信/支付宝官方渠道）
- 不触碰用户支付敏感信息
- 完整订单/交易记录保存 5 年

---

## 九、部署架构

### 9.1 容器化（Docker + Docker Compose）

```yaml
# docker-compose.yml
version: '3.8'
services:
  api-gateway:
    build: ./services/api-gateway
    ports:
      - "3000:3000"
    depends_on:
      - redis
      - rabbitmq

  auth-service:
    build: ./services/auth-service
    ports:
      - "3001:3001"
    depends_on:
      - postgres
      - redis

  ai-proxy-service:
    build: ./services/ai-proxy-service
    ports:
      - "3003:3003"
    depends_on:
      - redis
      - rabbitmq

  billing-service:
    build: ./services/billing-service
    ports:
      - "3004:3004"
    depends_on:
      - postgres
      - redis

  payment-service:
    build: ./services/payment-service
    ports:
      - "3005:3005"
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:16-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: changji
      POSTGRES_USER: changji
      POSTGRES_PASSWORD: ${DB_PASSWORD}

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

  rabbitmq:
    image: rabbitmq:3-management-alpine
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq

volumes:
  postgres_data:
  redis_data:
  rabbitmq_data:
```

### 9.2 CI/CD 流程

```
代码提交 → GitHub Actions → 单元测试 → 构建镜像 → 推送阿里云镜像仓库
                                                      ↓
                                            部署到测试环境 → 集成测试
                                                      ↓
                                            部署到生产环境（蓝绿部署）
```

---

## 十、监控与运维

### 10.1 监控指标
- 应用：QPS、响应时间、错误率
- 业务：日活、付费转化、API 调用量
- 资源：CPU、内存、磁盘、网络
- 告警：错误率 > 1%、响应时间 > 2s、磁盘 > 80%

### 10.2 日志方案
- 应用日志：结构化 JSON 输出
- 收集：阿里云 SLS / ELK
- 保留：30 天在线，90 天归档
- 敏感信息脱敏

### 10.3 备份策略
- 数据库：每日全量备份 + 实时 WAL 归档
- 文件：OSS 多 AZ 冗余
- 备份保留：30 天

---

## 十一、客户端改造计划

### 11.1 新增模块

```
lib/
├── features/
│   ├── auth/                    # 新增：账户认证
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── forgot_password_screen.dart
│   │   │   └── profile_screen.dart
│   │   └── services/
│   │       └── auth_service.dart
│   ├── billing/                 # 新增：充值付费
│   │   ├── providers/
│   │   │   └── billing_provider.dart
│   │   ├── screens/
│   │   │   ├── wallet_screen.dart
│   │   │   ├── package_store_screen.dart
│   │   │   ├── subscription_screen.dart
│   │   │   └── transaction_history_screen.dart
│   │   └── services/
│   │       └── billing_service.dart
│   └── cloud/                   # 新增：云服务
│       ├── providers/
│       │   └── cloud_sync_provider.dart
│       ├── services/
│       │   ├── cloud_sync_service.dart
│       │   └── cloud_ai_service.dart
│       └── widgets/
│           └── sync_status_widget.dart
├── core/
│   ├── models/
│   │   ├── user_model.dart      # 新增
│   │   ├── balance_model.dart   # 新增
│   │   └── subscription_model.dart # 新增
│   └── services/
│       └── ai_router_service.dart # 新增：双模式路由
└── data/
    └── database/
        └── migrations/          # 新增：云端相关迁移
```

### 11.2 现有模块改造

| 模块 | 改造内容 |
|------|---------|
| `settings_screen.dart` | 新增「账户与安全」Tab，整合登录/余额/套餐 |
| `api_service.dart` | 增加云端 AI 调用分支 |
| `transcription_service.dart` | 通过 AiRouter 选择本地/云端转写 |
| `ai_summary_service.dart` | 通过 AiRouter 选择本地/云端分析 |
| `app_router.dart` | 新增登录/注册/付费路由 |
| `main.dart` | 启动时检查登录状态，初始化双模式路由 |

### 11.3 新增依赖

```yaml
dependencies:
  # 保持现有依赖...
  
  # 新增：云端服务
  firebase_messaging: ^15.0.0      # 推送通知（可选）
  local_auth: ^2.2.0               # 生物识别登录
  crypto: ^3.0.3                   # 加密（已有 pointycastle）
  
  # 支付 SDK（由支付服务处理，客户端只需调后端接口）
  # 无需直接引入微信/支付宝 SDK
```

---

## 十二、实施里程碑

### Phase 1：基础设施（Week 1-2）
- [ ] 阿里云资源购买与配置
- [ ] 域名购买与 ICP 备案启动
- [ ] NestJS 项目脚手架搭建
- [ ] PostgreSQL + Redis 部署
- [ ] CI/CD 流水线配置

### Phase 2：账户服务（Week 2-3）
- [ ] 用户注册/登录/找回密码
- [ ] JWT 认证体系
- [ ] 设备管理
- [ ] 短信验证码（阿里云短信）

### Phase 3：AI 代理服务（Week 3-4）
- [ ] 阿里云语音转录对接
- [ ] OpenAI/DeepSeek 代理对接
- [ ] 熔断降级机制
- [ ] 客户端双模式路由

### Phase 4：计费系统（Week 4-5）
- [ ] 余额系统
- [ ] 套餐管理
- [ ] 订阅管理
- [ ] 用量计量

### Phase 5：支付对接（Week 5-6）
- [ ] 微信支付对接
- [ ] 支付宝对接
- [ ] 支付回调处理
- [ ] 订单管理

### Phase 6：客户端改造（Week 3-6，与后端并行）
- [ ] 登录/注册页面
- [ ] 个人中心/账户管理
- [ ] 余额/套餐/订阅页面
- [ ] 双模式 AI 路由
- [ ] 云端同步功能

### Phase 7：测试与上线（Week 7-8）
- [ ] 集成测试
- [ ] 压力测试
- [ ] 安全审计
- [ ] 灰度发布
- [ ] 全量上线

---

*文档版本：v1.0*
*更新日期：2026-05-13*
*状态：待实施*
