# API 差异化计费与套餐分配方案

## 一、现状分析

### 1.1 现有模型

| 模型 | 用途 | 问题 |
|------|------|------|
| `Plan` (套餐) | 定义订阅套餐 | 只有 quotaType/quotaValue，无法区分 API |
| `Subscription` (订阅) | 用户订阅记录 | totalQuota/usedQuota 是全局计数 |
| `UserBalance` (余额) | 充值金额 | 与 API 使用无直接关联 |
| `ApiKey` (API密钥) | 平台密钥池 | 有 dailyQuota/dailyUsage，但按 Key 统计 |

### 1.2 核心问题

- **套餐配额是全局的**：用户买了 1000 次套餐，但不知道哪些 API 能用、各能用多少次
- **API 成本差异大**：OpenAI GPT-4 和 通义千问成本差 10 倍，但配额计算方式相同
- **没有 API-套餐映射关系**：无法限制某些套餐只能用特定 API

---

## 二、方案设计

### 2.1 核心概念：配额单位 (Quota Unit)

引入 **"配额单位"** 作为统一计量标准，不同 API 调用消耗不同单位：

| API 平台 | 模型 | 消耗配额单位 |
|---------|------|------------|
| 通义千问 | qwen-turbo | 1 单位/次 |
| 通义千问 | qwen-plus | 2 单位/次 |
| DeepSeek | deepseek-chat | 1 单位/次 |
| DeepSeek | deepseek-reasoner | 3 单位/次 |
| OpenAI | gpt-4o | 5 单位/次 |
| OpenAI | gpt-4o-mini | 2 单位/次 |
| Anthropic | claude-3-sonnet | 4 单位/次 |
| Gemini | gemini-1.5-pro | 2 单位/次 |
| Grok | grok-2 | 3 单位/次 |

> **原理**：低成本 API 消耗少，高成本 API 消耗多，实现差异化计费。

### 2.2 套餐类型设计

保留三种套餐类型，但增加 API 可用性配置：

#### A. 订阅套餐 (subscription)
- **周期**：月付/季付/年付
- **配额**：每月 N 个配额单位
- **API 范围**：可配置可用 API（如：仅国产、全部、仅基础模型）
- **价格**：¥9.9/月 ~ ¥99/月

#### B. 次数套餐 (package)
- **周期**：一次性，用完即止
- **配额**：固定 N 个配额单位
- **API 范围**：可配置
- **价格**：¥5 ~ ¥100

#### C. 充值账户 (recharge)
- **周期**：永久有效
- **配额**：按金额换算配额单位（如 ¥1 = 10 单位）
- **API 范围**：全部可用
- **价格**：任意金额

### 2.3 数据库模型变更

#### 新增表：`plan_api_policies` (套餐API策略)

```sql
CREATE TABLE plan_api_policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id VARCHAR(50) NOT NULL REFERENCES plans(id),
  provider VARCHAR(50) NOT NULL,  -- 'qwen' | 'deepseek' | 'openai' | 'anthropic' | 'gemini' | 'grok' | 'all'
  model_pattern VARCHAR(100),     -- 模型匹配规则，如 'qwen-*' | 'gpt-4o'
  multiplier DECIMAL(3,1) DEFAULT 1.0,  -- 配额消耗倍数
  is_allowed BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### 新增表：`api_usage_logs` (API使用日志)

```sql
CREATE TABLE api_usage_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  subscription_id UUID REFERENCES subscriptions(id),
  api_key_id UUID REFERENCES api_keys(id),
  provider VARCHAR(50) NOT NULL,
  model VARCHAR(100) NOT NULL,
  prompt_tokens INT DEFAULT 0,
  completion_tokens INT DEFAULT 0,
  quota_consumed INT NOT NULL,    -- 消耗的配额单位
  cost_cents INT,                 -- 实际成本（分）
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### 修改表：`plans` (套餐表)

```sql
ALTER TABLE plans ADD COLUMN type VARCHAR(20) DEFAULT 'subscription';  -- subscription | package | recharge
ALTER TABLE plans ADD COLUMN api_policy_type VARCHAR(20) DEFAULT 'all'; -- all | domestic | basic | custom
```

#### 修改表：`subscriptions` (订阅表)

```sql
ALTER TABLE subscriptions ADD COLUMN balance_quota INT DEFAULT 0;  -- 剩余配额单位（实时计算）
```

### 2.4 配额计算流程

```
用户发起请求
    ↓
选择可用 API Key（根据用户套餐策略过滤）
    ↓
调用 API
    ↓
记录使用日志 api_usage_logs
    ↓
计算消耗配额 = base_quota × multiplier
    ↓
更新 subscription.usedQuota += 消耗配额
    ↓
检查是否超额 → 超额则拒绝或提示充值
```

---

## 三、套餐与API分配关系

### 3.1 预设套餐模板

#### 免费套餐 (Free)
```json
{
  "name": "免费体验",
  "type": "subscription",
  "priceCents": 0,
  "durationDays": 30,
  "quotaValue": 50,
  "apiPolicyType": "domestic",
  "policies": [
    { "provider": "qwen", "multiplier": 1.0 },
    { "provider": "deepseek", "multiplier": 1.0 }
  ]
}
```

#### 基础套餐 (Basic)
```json
{
  "name": "基础版",
  "type": "subscription",
  "priceCents": 990,
  "durationDays": 30,
  "quotaValue": 1000,
  "apiPolicyType": "domestic",
  "policies": [
    { "provider": "qwen", "multiplier": 1.0 },
    { "provider": "deepseek", "multiplier": 1.0 }
  ]
}
```

#### 标准套餐 (Standard)
```json
{
  "name": "标准版",
  "type": "subscription",
  "priceCents": 2990,
  "durationDays": 30,
  "quotaValue": 3000,
  "apiPolicyType": "all",
  "policies": [
    { "provider": "qwen", "multiplier": 1.0 },
    { "provider": "deepseek", "multiplier": 1.0 },
    { "provider": "openai", "model_pattern": "gpt-4o-mini", "multiplier": 2.0 },
    { "provider": "gemini", "multiplier": 2.0 }
  ]
}
```

#### 高级套餐 (Pro)
```json
{
  "name": "专业版",
  "type": "subscription",
  "priceCents": 9900,
  "durationDays": 30,
  "quotaValue": 10000,
  "apiPolicyType": "all",
  "policies": [
    { "provider": "qwen", "multiplier": 1.0 },
    { "provider": "deepseek", "multiplier": 1.0 },
    { "provider": "openai", "multiplier": 5.0 },
    { "provider": "anthropic", "multiplier": 4.0 },
    { "provider": "gemini", "multiplier": 2.0 },
    { "provider": "grok", "multiplier": 3.0 }
  ]
}
```

#### 充值套餐 (Recharge)
```json
{
  "name": "账户充值",
  "type": "recharge",
  "priceCents": 0,
  "durationDays": 36500,
  "quotaValue": 0,
  "apiPolicyType": "all",
  "conversionRate": 10
}
```

### 3.2 API 可用性矩阵

| 套餐 | 通义千问 | DeepSeek | OpenAI | Anthropic | Gemini | Grok |
|------|---------|----------|--------|-----------|--------|------|
| 免费 | ✅ 1x | ✅ 1x | ❌ | ❌ | ❌ | ❌ |
| 基础 | ✅ 1x | ✅ 1x | ❌ | ❌ | ❌ | ❌ |
| 标准 | ✅ 1x | ✅ 1x | ✅ 2x(mini) | ❌ | ✅ 2x | ❌ |
| 专业 | ✅ 1x | ✅ 1x | ✅ 5x | ✅ 4x | ✅ 2x | ✅ 3x |
| 充值 | ✅ 1x | ✅ 1x | ✅ 5x | ✅ 4x | ✅ 2x | ✅ 3x |

> **x** 表示配额消耗倍数

---

## 四、关键业务流程

### 4.1 用户购买套餐

```
1. 用户选择套餐
2. 支付（订阅扣费/充值到账）
3. 创建 subscription 记录
4. 如果是充值类型，更新 user_balance
5. 返回成功，用户可立即使用
```

### 4.2 API 调用配额检查

```
1. 用户发起请求（如语音转写）
2. 系统查询用户当前活跃 subscription
3. 根据套餐 api_policy 筛选可用 API Keys
4. 选择最优 API Key（负载均衡）
5. 调用 API
6. 异步记录 usage_log
7. 实时更新 usedQuota
8. 如果 quota 不足，返回 429 提示升级套餐
```

### 4.3 套餐过期处理

```
1. 定时任务检查过期 subscription
2. 标记 status = 'expired'
3. 如果有自动续费，创建新 subscription
4. 如果没有，降级为免费套餐
5. 通知用户
```

---

## 五、技术实现要点

### 5.1 实时配额扣减

使用 Redis 做实时计数器，避免数据库压力：

```typescript
// 伪代码
async consumeQuota(userId: string, provider: string, model: string) {
  const multiplier = await getMultiplier(userId, provider, model);
  const consumed = 1 * multiplier;
  
  // Redis 原子扣减
  const remaining = await redis.decrby(`quota:${userId}`, consumed);
  
  if (remaining < 0) {
    // 超额，拒绝请求
    throw new QuotaExceededException();
  }
  
  // 异步记录日志
  logUsage(userId, provider, model, consumed);
}
```

### 5.2 成本核算

定期统计 `api_usage_logs`，计算：
- 每个 API 的实际调用成本
- 每个用户的利润率
- 平台整体盈亏

### 5.3 降级策略

当用户套餐过期或配额用完时：
1. **软限制**：提示用户升级，允许少量超额（如 10%）
2. **硬限制**：直接拒绝请求，返回 402 Payment Required
3. **降级服务**：切换到免费/低成本 API（如从 GPT-4 降级到 GPT-3.5）

---

## 六、管理后台功能

### 6.1 套餐管理
- 创建/编辑套餐（名称、价格、配额、API策略）
- 设置 API 消耗倍数
- 启用/禁用套餐

### 6.2 用户套餐分配
- 查看用户当前套餐和剩余配额
- 手动为用户分配/更换套餐
- 查看用户 API 使用详情

### 6.3 财务报表
- 收入统计（按套餐类型、时间）
- 成本统计（按 API 平台）
- 利润分析

### 6.4 API 使用监控
- 实时调用量
- 各 API 健康状态
- 异常告警（如某 API 成本突增）

---

## 七、实施计划

### Phase 1：基础改造（1-2周）
- [ ] 添加 `plan_api_policies` 表
- [ ] 添加 `api_usage_logs` 表
- [ ] 修改 `plans` 表添加 type/api_policy_type
- [ ] 实现配额计算逻辑

### Phase 2：套餐系统（2-3周）
- [ ] 实现套餐购买流程
- [ ] 实现订阅续费逻辑
- [ ] 实现充值兑换逻辑
- [ ] 集成支付系统

### Phase 3：API 接入（2周）
- [ ] 改造 API 调用流程，增加配额检查
- [ ] 实现 API Key 筛选逻辑
- [ ] 实现使用日志记录
- [ ] 实现实时配额扣减

### Phase 4：管理后台（1-2周）
- [ ] 套餐管理页面
- [ ] 用户套餐分配功能
- [ ] 财务报表页面
- [ ] API 监控仪表盘

---

## 八、风险与应对

| 风险 | 影响 | 应对 |
|------|------|------|
| 配额计算不准确 | 用户投诉、亏损 | 双写日志，定期对账 |
| API 成本波动 | 利润率下降 | 动态调整 multiplier |
| 用户恶意刷量 | 成本激增 | 限流+异常检测 |
| 套餐设计复杂 | 用户理解困难 | 提供套餐对比工具 |

---

*文档版本：v1.0*
*更新日期：2026-05-26*
