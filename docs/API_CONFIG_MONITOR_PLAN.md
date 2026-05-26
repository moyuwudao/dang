# API 配置-传递-监控 完整方案

## 一、现状梳理

### 1.1 已有能力

| 模块 | 已有功能 | 状态 |
|------|---------|------|
| **API Key 池** | 7种Provider、加密存储、健康检查、日配额 | ✅ |
| **套餐系统** | 套餐CRUD、订阅管理、余额充值、API差异化配额 | ✅ |
| **认证体系** | JWT（Access/Refresh Token）、角色权限 | ✅ |
| **基础监控** | CPU/内存/磁盘、服务状态、日志查看 | ✅ |
| **管理后台** | 用户管理、套餐管理、API Key管理、仪表盘 | ✅ |
| **APP端** | 登录注册、套餐查看、订阅刷新 | ✅ |

### 1.2 缺失环节

| 模块 | 缺失功能 | 影响 |
|------|---------|------|
| **安全** | API Key管理接口未加认证 | 任何人可查看/修改Key |
| **安全** | 远程命令执行无白名单 | 服务器可被恶意操作 |
| **认证** | 前端无Token自动刷新 | 用户频繁被踢出 |
| **监控** | 无API调用量/性能监控 | 无法感知服务负载 |
| **监控** | 无业务指标监控 | 无法数据驱动决策 |
| **监控** | 无告警机制 | 异常无法及时通知 |
| **限流** | 限流数据仅存内存 | 重启后限流失效 |
| **支付** | 无微信/支付宝集成 | 充值需手动操作 |
| **自动化** | 无自动续费/过期提醒 | 用户体验差 |

---

## 二、完整方案设计

### 2.1 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                        用户层                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                │
│  │   APP    │  │ 管理后台  │  │  第三方   │                │
│  │ (Flutter)│  │ (Next.js)│  │  开发者   │                │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                │
└───────┼─────────────┼─────────────┼────────────────────────┘
        │             │             │
        ▼             ▼             ▼
┌─────────────────────────────────────────────────────────────┐
│                      API 网关层                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   认证网关    │  │   限流网关    │  │   路由网关    │     │
│  │ (JWT验证)    │  │ (Redis计数)  │  │ (负载均衡)   │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
└─────────┼─────────────────┼─────────────────┼──────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────┐
│                      业务服务层                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  Auth    │  │Subscription│  │ API Key  │  │  Admin   │  │
│  │ 服务     │  │  服务      │  │  服务    │  │  服务    │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
└─────────────────────────────────────────────────────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────┐
│                      数据存储层                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │PostgreSQL│  │  Redis   │  │  日志文件 │  │  对象存储 │  │
│  │(主数据库) │  │(缓存/计数)│  │(调用日志) │  │(备份)   │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
└─────────────────────────────────────────────────────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────┐
│                      监控告警层                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ 指标采集  │  │ 日志分析  │  │ 告警通知  │  │ 可视化   │  │
│  │(Prometheus)│  │(ELK/Loki)│  │(钉钉/邮件)│  │(Grafana) │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 三、核心模块设计

### 3.1 API 配置中心

**功能**：统一管理所有 API 的配置信息

#### 数据模型

```typescript
// API 配置表
interface ApiConfig {
  id: string;
  provider: string;           // qwen | openai | deepseek | ...
  name: string;               // 显示名称
  baseUrl: string;            // API 基础地址
  model: string;              // 默认模型
  maxTokens: number;          // 最大Token数
  timeout: number;            // 超时时间(秒)
  retryCount: number;         // 重试次数
  fallbackOrder: number;      // 降级优先级
  isEnabled: boolean;         // 是否启用
  costPer1kTokens: number;    // 每千Token成本(分)
  createdAt: Date;
  updatedAt: Date;
}

// API 密钥表（已有，扩展）
interface ApiKey {
  id: string;
  provider: string;
  apiKeyEncrypted: string;    // 加密存储
  apiSecretEncrypted: string; // 加密存储
  status: 'active' | 'inactive' | 'expired';
  dailyQuota: number;         // 日配额
  dailyUsage: number;         // 日已用
  rateLimitPerMin: number;    // 每分钟限制
  maxConcurrent: number;      // 最大并发
  lastUsedAt: Date;
  lastHealthCheck: Date;
  healthStatus: 'healthy' | 'unhealthy' | 'unknown';
}
```

#### 管理后台功能

| 功能 | 说明 |
|------|------|
| API 配置列表 | 查看所有 API 配置 |
| 添加/编辑 API | 配置 Provider、URL、模型、成本等 |
| 密钥管理 | 添加/删除/轮换 API Key |
| 健康检查 | 批量测试所有 API 连通性 |
| 成本统计 | 各 API 的实际调用成本 |

---

### 3.2 API 传递网关

**功能**：统一处理所有 API 请求的认证、限流、路由、降级

#### 流程设计

```
用户请求
    ↓
[1] 认证网关
    - 验证 JWT Token
    - 检查用户状态
    - 解析用户角色
    ↓
[2] 套餐权限检查
    - 查询用户当前订阅
    - 检查 API 使用权限
    - 计算配额消耗倍数
    ↓
[3] 限流网关
    - 检查用户级限流（Redis）
    - 检查 API Key 级限流
    - 检查全局限流
    ↓
[4] 路由网关
    - 根据策略选择 API Key
    - 负载均衡（轮询/权重）
    - 故障转移（自动切换）
    ↓
[5] 调用 API
    - 记录请求日志
    - 监控响应时间
    - 处理重试逻辑
    ↓
[6] 响应处理
    - 记录使用日志
    - 扣减配额
    - 返回结果
```

#### 限流策略

| 级别 | 维度 | 存储 | 说明 |
|------|------|------|------|
| 全局限流 | 整个系统 | Redis | 防止系统过载 |
| 用户限流 | 用户ID | Redis | 防止单个用户刷量 |
| API Key 限流 | Key ID | Redis | 防止单个 Key 超限 |
| 套餐限流 | 订阅ID | Redis | 根据套餐配额限制 |

#### 降级策略

```typescript
interface FallbackStrategy {
  // 优先级：高成本 → 低成本
  providers: ['openai', 'anthropic', 'gemini', 'deepseek', 'qwen'];
  
  // 触发条件
  triggers: {
    timeout: 10000,        // 10秒超时
    errorRate: 0.5,        // 错误率50%
    quotaExhausted: true,  // 配额耗尽
  };
  
  // 降级动作
  actions: {
    switchProvider: true,  // 切换提供商
    reduceQuality: true,   // 降低模型质量
    returnError: false,    // 直接返回错误
  };
}
```

---

### 3.3 API 监控中心

**功能**：全方位监控 API 调用情况，及时发现问题

#### 监控指标

| 类别 | 指标 | 采集方式 |
|------|------|---------|
| **性能** | 响应时间(P50/P95/P99) | 中间件记录 |
| **性能** | QPS/TPS | 实时计算 |
| **性能** | 错误率 | 状态码统计 |
| **性能** | 并发数 | 连接数监控 |
| **业务** | 日调用量 | 日志统计 |
| **业务** | 各 API 占比 | 按 Provider 分组 |
| **业务** | 用户活跃度 | UV/PV |
| **业务** | 收入/成本 | 充值消耗计算 |
| **资源** | CPU/内存/磁盘 | 系统采集 |
| **资源** | 数据库连接数 | PostgreSQL 统计 |
| **资源** | Redis 内存使用 | INFO 命令 |

#### 告警规则

| 规则 | 条件 | 通知方式 |
|------|------|---------|
| 服务宕机 | 5分钟无心跳 | 钉钉 + 邮件 |
| 错误率过高 | 错误率 > 10% | 钉钉 |
| 响应过慢 | P95 > 5秒 | 钉钉 |
| API Key 耗尽 | 日配额使用 > 80% | 钉钉 |
| 余额不足 | 用户余额 < 10元 | 站内信 |
| 系统资源 | CPU > 80% | 钉钉 |

#### 可视化仪表盘

```
┌─────────────────────────────────────────┐
│           API 监控仪表盘                 │
├─────────────────────────────────────────┤
│  ┌─────────┐ ┌─────────┐ ┌─────────┐  │
│  │ 日调用量 │ │ 错误率  │ │ 平均延迟 │  │
│  │  12.5K  │ │  0.5%   │ │  230ms  │  │
│  └─────────┘ └─────────┘ └─────────┘  │
├─────────────────────────────────────────┤
│  调用量趋势 (24小时)                    │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
├─────────────────────────────────────────┤
│  各 API 占比          │  错误分布       │
│  ████ OpenAI 45%      │  超时 60%      │
│  ███  DeepSeek 30%    │  500  30%      │
│  ██   Qwen 25%        │  429  10%      │
└─────────────────────────────────────────┘
```

---

## 四、API 调用完整链路（核心补充）

### 4.1 用户调用 API 的完整流程

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   用户发起   │     │   管理后台   │     │   后端网关   │     │   AI服务    │
│   语音转写   │────▶│  配置API策略 │────▶│  执行调用   │────▶│  返回结果   │
│   请求      │     │  (套餐绑定)  │     │  (计费扣减)  │     │            │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

### 4.2 详细调用链路

#### Step 1: 用户发起请求（APP端）

```dart
// APP 端调用示例
final response = await CloudApiService.instance.post(
  '/ai/transcribe',  // 语音转写接口
  data: {
    'audioUrl': 'https://xxx/recording.mp3',
    'provider': 'qwen',  // 指定或自动选择
  },
);
```

**请求头携带**：
- `Authorization: Bearer <JWT Token>`
- `Content-Type: application/json`

#### Step 2: 后端接收请求（API Gateway）

```typescript
// 中间件处理流程
async function apiGateway(req, res, next) {
  // 1. 认证
  const user = await jwtAuth(req);
  
  // 2. 获取用户订阅
  const subscription = await getUserSubscription(user.id);
  
  // 3. 检查API权限
  const canUse = await checkApiPermission(
    user.id, 
    req.body.provider, 
    req.body.model
  );
  if (!canUse.allowed) {
    return res.status(403).json({ error: canUse.reason });
  }
  
  // 4. 计算配额消耗
  const quotaCost = await calculateQuotaCost(
    user.id,
    req.body.provider,
    req.body.model,
    estimatedTokens  // 预估Token数
  );
  
  // 5. 检查余额/配额
  const hasQuota = await checkQuota(user.id, quotaCost);
  if (!hasQuota) {
    return res.status(402).json({ error: '配额不足，请充值' });
  }
  
  // 6. 选择最优API Key
  const apiKey = await selectOptimalApiKey(
    req.body.provider,
    req.body.model
  );
  
  // 7. 限流检查
  const rateLimitOk = await checkRateLimit(user.id, apiKey.id);
  if (!rateLimitOk) {
    return res.status(429).json({ error: '请求过于频繁' });
  }
  
  // 8. 调用AI服务
  const result = await callAiService(apiKey, req.body);
  
  // 9. 记录使用日志 & 扣减配额
  await recordUsageAndDeductQuota({
    userId: user.id,
    subscriptionId: subscription.id,
    apiKeyId: apiKey.id,
    provider: req.body.provider,
    model: result.model,
    promptTokens: result.usage.prompt_tokens,
    completionTokens: result.usage.completion_tokens,
    quotaConsumed: quotaCost,
    actualCost: result.cost,  // 实际成本
  });
  
  // 10. 返回结果
  res.json({
    code: 200,
    data: result.data,
    usage: {
      quotaConsumed: quotaCost,
      remainingQuota: subscription.balanceQuota - quotaCost,
    },
  });
}
```

### 4.3 费用计算逻辑

#### 4.3.1 计算公式

```
总费用 = 基础配额 × 消耗倍数 + 额外Token费用

其中：
- 基础配额：每次API调用固定消耗（默认1单位）
- 消耗倍数：根据套餐策略确定（如 OpenAI=5x）
- 额外Token费用：超出套餐包含Token数的部分
```

#### 4.3.2 计算示例

| 场景 | 用户套餐 | 调用API | 实际Token | 计算过程 | 消耗配额 |
|------|---------|---------|-----------|----------|----------|
| 基础调用 | 基础版(国产) | 通义千问 | 500 | 1 × 1.0 = 1 | 1单位 |
| 高级调用 | 标准版 | OpenAI GPT-4 | 1000 | 1 × 5.0 = 5 | 5单位 |
| 大文本 | 专业版 | Claude-3 | 5000 | 1 × 4.0 + (5000-1000)/1000×2 = 12 | 12单位 |
| 免费用户 | 免费版 | DeepSeek | 300 | 1 × 1.0 = 1 | 1单位 |
| 免费用户越权 | 免费版 | OpenAI | 100 | ❌ 不允许 | 拒绝调用 |

#### 4.3.3 代码实现

```typescript
// 费用计算服务
class BillingService {
  // 计算单次调用应消耗的配额
  async calculateQuotaCost(
    userId: string,
    provider: string,
    model: string,
    promptTokens: number,
    completionTokens: number,
  ): Promise<number> {
    // 1. 获取用户订阅
    const subscription = await this.getActiveSubscription(userId);
    
    // 2. 获取套餐API策略
    const policies = await this.planApiPolicyRepository.find({
      where: { planId: subscription.planId },
    });
    
    // 3. 查找匹配的策略
    const policy = policies.find(p => {
      if (p.provider !== provider && p.provider !== 'all') return false;
      if (!p.modelPattern) return true;
      const pattern = p.modelPattern.replace('*', '.*');
      return new RegExp(`^${pattern}$`).test(model);
    });
    
    const multiplier = policy ? policy.multiplier : 1;
    
    // 4. 计算基础消耗
    const baseCost = 1 * multiplier;
    
    // 5. 计算额外Token费用（如果套餐有包含Token数）
    const totalTokens = promptTokens + completionTokens;
    const includedTokens = subscription.plan.includedTokens || 0;
    const extraTokens = Math.max(0, totalTokens - includedTokens);
    const extraCost = (extraTokens / 1000) * (policy?.extraCostPer1k || 0);
    
    // 6. 总消耗（向上取整）
    const totalCost = Math.ceil(baseCost + extraCost);
    
    return totalCost;
  }
  
  // 扣减配额
  async deductQuota(
    userId: string,
    subscriptionId: string,
    amount: number,
  ): Promise<void> {
    // 使用Redis原子操作
    const key = `quota:${userId}`;
    const remaining = await this.redis.decrby(key, amount);
    
    if (remaining < 0) {
      // 回滚
      await this.redis.incrby(key, amount);
      throw new Error('配额不足');
    }
    
    // 异步更新数据库
    await this.subscriptionRepository.increment(
      { id: subscriptionId },
      'usedQuota',
      amount,
    );
  }
}
```

### 4.4 管理后台配置 → 用户调用的映射关系

#### 4.4.1 配置流程

```
管理员操作                          系统行为
───────────                        ─────────
1. 创建套餐 "专业版"
   ├─ 价格: ¥99/月
   ├─ 配额: 10000单位
   └─ API策略: 全部可用
                                     保存到 plans 表
                                     
2. 配置API策略
   ├─ 通义千问: 1x
   ├─ DeepSeek: 1x
   ├─ OpenAI: 5x
   └─ Anthropic: 4x
                                     保存到 plan_api_policies 表
                                     
3. 用户购买套餐
                                     创建 subscription 记录
                                     初始化 balance_quota = 10000
                                     
4. 用户调用API
                                     查询 subscription
                                     查询 plan_api_policies
                                     计算消耗配额
                                     扣减 balance_quota
```

#### 4.4.2 数据流图

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   plans     │◄───────│ plan_api_   │         │  api_keys   │
│  (套餐定义)  │         │  policies   │         │  (密钥池)   │
└──────┬──────┘         │ (API策略)   │         └──────┬──────┘
       │                └─────────────┘                │
       │                       ▲                       │
       │                       │                       │
       ▼                       │                       ▼
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│subscriptions│────────▶│   计费引擎   │◄────────│   路由选择   │
│  (用户订阅)  │         │             │         │             │
└─────────────┘         └──────┬──────┘         └─────────────┘
                               │
                               ▼
                        ┌─────────────┐
                        │ api_usage_  │
                        │    logs     │
                        │ (使用日志)   │
                        └─────────────┘
```

### 4.5 关键接口设计

#### 4.5.1 用户调用AI服务

```typescript
// POST /api/v1/ai/chat
// 请求体
{
  "messages": [
    { "role": "user", "content": "你好" }
  ],
  "provider": "qwen",        // 可选，不指定则自动选择
  "model": "qwen-plus",      // 可选
  "stream": false            // 是否流式返回
}

// 响应体
{
  "code": 200,
  "data": {
    "content": "你好！有什么可以帮助你的？",
    "model": "qwen-plus",
    "provider": "qwen"
  },
  "usage": {
    "promptTokens": 10,
    "completionTokens": 20,
    "totalTokens": 30,
    "quotaConsumed": 1,      // 实际消耗配额
    "remainingQuota": 9999   // 剩余配额
  }
}
```

#### 4.5.2 查询API使用记录

```typescript
// GET /api/v1/ai/usage?startDate=2026-05-01&endDate=2026-05-26
// 响应体
{
  "code": 200,
  "data": {
    "totalCalls": 150,
    "totalTokens": 45000,
    "totalQuotaConsumed": 230,
    "breakdown": [
      {
        "date": "2026-05-26",
        "calls": 50,
        "tokens": 15000,
        "quotaConsumed": 80,
        "provider": "qwen"
      }
    ]
  }
}
```

---

## 五、实施路线图

### Phase 1：安全加固（1周）

| 任务 | 说明 |
|------|------|
| 修复 API Key 接口认证 | 添加 JwtAuthGuard + AdminGuard |
| 限制远程命令执行 | 添加白名单，只允许只读命令 |
| Token 自动刷新 | 实现 Access Token 过期前自动刷新 |
| 敏感操作审计日志 | 记录所有管理员操作 |

### Phase 2：API 网关完善（2周）

| 任务 | 说明 |
|------|------|
| Redis 限流 | 替换内存限流，支持分布式 |
| 智能路由 | 根据成本/延迟自动选择最优 API |
| 降级机制 | 主 API 故障时自动切换 |
| 请求重试 | 失败时自动重试（带退避） |
| 统一响应格式 | 标准化成功/失败响应 |

### Phase 3：监控告警（2周）

| 任务 | 说明 |
|------|------|
| 指标采集 | 接入 Prometheus |
| 日志收集 | 接入 Loki/ELK |
| 告警通知 | 配置钉钉/邮件通知 |
| 可视化 | 部署 Grafana 仪表盘 |
| 业务监控 | 日活、收入、API 消耗趋势 |

### Phase 4：支付与自动化（2周）

| 任务 | 说明 |
|------|------|
| 微信支付集成 | 扫码支付、H5支付 |
| 支付宝集成 | 手机网站支付 |
| 自动续费 | 订阅到期前自动扣费 |
| 过期提醒 | 到期前3天/1天/当天提醒 |
| 欠费处理 | 余额不足时降级为免费套餐 |

### Phase 5：开发者平台（可选）

| 任务 | 说明 |
|------|------|
| 开发者文档 | API 文档、SDK |
| 在线调试 | Postman 风格的调试工具 |
| 用量统计 | 开发者查看自己的调用量 |
| Webhook | 订阅状态变更通知 |

---

## 五、技术选型

| 组件 | 选型 | 理由 |
|------|------|------|
| 限流存储 | Redis | 高性能、支持分布式 |
| 监控采集 | Prometheus | 云原生标准 |
| 日志收集 | Loki | 轻量、与 Grafana 集成 |
| 可视化 | Grafana | 开源、灵活 |
| 告警通知 | Prometheus Alertmanager | 与 Prometheus 集成 |
| 支付 | 微信支付 + 支付宝 | 国内主流 |
| 消息队列 | Redis List / RabbitMQ | 异步处理 |

---

## 六、风险与应对

| 风险 | 影响 | 应对 |
|------|------|------|
| Redis 单点故障 | 限流失效 | 部署 Redis Sentinel 集群 |
| 支付接口变更 | 充值失败 | 封装支付适配层，隔离变化 |
| 监控数据过多 | 存储成本 | 设置 retention 策略 |
| 降级导致质量下降 | 用户体验差 | 降级时通知用户 |
| 自动续费争议 | 用户投诉 | 提供明确的续费提醒和取消入口 |

---

*文档版本：v1.0*
*更新日期：2026-05-26*
