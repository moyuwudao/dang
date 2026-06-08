# 畅记云 - 云端API配置架构文档

> 版本: 1.0  
> 更新日期: 2026-06-06  
> 适用范围: 服务器端 + APK客户端

---

## 目录

1. [概述](#1-概述)
2. [服务器端架构](#2-服务器端架构)
3. [客户端/APK架构](#3-客户端apk架构)
4. [核心数据流](#4-核心数据流)
5. [关键接口契约](#5-关键接口契约)
6. [配置字段规范](#6-配置字段规范)
7. [常见问题排查](#7-常见问题排查)
8. [迭代记录](#8-迭代记录)

---

## 1. 概述

### 1.1 设计目标

云端API配置系统实现以下目标：
- **集中管理**: 管理员在WEB后台统一配置API Key、套餐策略
- **自动下发**: 用户登录后自动获取云端API配置，无需手动输入
- **动态切换**: 支持云端/本地AI配置一键切换
- **计费透明**: 按模型系数(multiplier)精确计算Token消耗
- **负载均衡**: 多Key池自动分配，避免单点过载

### 1.2 术语表

| 术语 | 说明 |
|------|------|
| API Key池 | 管理员配置的多个API Key集合 |
| 套餐(Plan) | 订阅套餐，包含可用模型、配额、时长 |
| apiPolicies | 套餐内的API策略列表（模型+系数+权限） |
| defaultConfigs | 功能场景到模型的默认映射 |
| functionAssignments | 客户端场景到配置条目的分配关系 |
| multiplier | 模型消耗系数（DEEPSEEK 0.5x = 便宜50%） |
| cloudConfig | 标记为云端下发的配置条目 |

---

## 2. 服务器端架构

### 2.1 模块关系图

```
┌─────────────────────────────────────────────────────────────┐
│                        服务器端                              │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  api-key     │  │ subscription │  │   billing    │      │
│  │  模块        │  │   模块       │  │   模块       │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                 │              │
│         ▼                 ▼                 ▼              │
│  ┌──────────────────────────────────────────────────┐     │
│  │              PostgreSQL + Redis                   │     │
│  │  api_keys | user_api_keys | plans | subscriptions │     │
│  │  user_token_balances | api_usage_logs             │     │
│  └──────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 API Key管理模块

#### 2.2.1 实体定义

**ApiKey** (`server/src/api-key/entities/api-key.entity.ts`)

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | uuid | Y | 自动生成 | 主键 |
| provider | enum | Y | - | qwen/openai/anthropic/gemini/deepseek/grok/custom |
| name | string | Y | - | 显示名称 |
| apiKeyEncrypted | string | Y | - | AES加密存储的API Key |
| apiSecretEncrypted | string | N | null | 加密API Secret |
| model | string | Y | - | 模型名称 |
| baseUrl | string | N | null | 自定义Base URL |
| status | enum | Y | active | active/inactive/expired/revoked |
| scopes | string[] | Y | [ALL] | 作用域 |
| rateLimitPerMin | int | Y | 60 | 每分钟请求限制 |
| maxConcurrentRequests | int | Y | 5 | 最大并发数 |
| dailyQuota | int | Y | 1000 | 日配额 |
| dailyUsage | int | Y | 0 | 当日已用量 |
| expiresAt | Date | N | null | Key过期时间 |
| lastHealthCheckStatus | string | N | null | healthy/degraded/unhealthy |
| supportedFeatures | string[] | Y | [] | 支持功能列表 |

**UserApiKey** - 用户与Key的分配关系

| 字段 | 说明 |
|------|------|
| userId | 用户ID |
| apiKeyId | 分配的API Key ID |
| assignedAt | 分配时间 |
| expiresAt | 分配过期时间（默认24小时） |
| isActive | 是否活跃 |

#### 2.2.2 核心服务: ApiKeyService

**文件**: `server/src/api-key/api-key.service.ts`

**getApiKey(userId)** - 用户获取API Key入口

```typescript
// 三级回退策略
1. 查Redis缓存 api:user_key:{userId}
2. 查DB user_api_keys 活跃分配
3. 执行 assignNewKey(userId) 负载均衡分配
```

**assignNewKey(userId)** - 带负载均衡的Key分配

```typescript
流程:
1. 从Redis获取活跃Key列表 (api:active_keys)
2. 过滤可用Key (isKeyAvailable)
3. selectOptimalKey() 加权评分选择
4. 检查并发用户数，超载则找次优Key
5. 创建UserApiKey分配记录
6. 缓存用户分配关系到Redis
```

**isKeyAvailable(key)** - Key可用性检查

```typescript
// 修复记录: 2026-06-06 允许degraded状态
// 原因: degraded表示API可用但有警告（如余额低），不应阻止分配

条件:
- status === ACTIVE
- lastHealthCheckStatus !== 'unhealthy'  // 允许healthy和degraded
- dailyUsage < dailyQuota
- expiresAt > now (如果有)
```

**selectOptimalKey(keys)** - 加权评分算法

| 权重 | 指标 | 说明 |
|------|------|------|
| 40% | 使用率 | dailyUsage/dailyQuota，越低越好 |
| 30% | 健康度 | healthy=30, degraded=15, unhealthy=0 |
| 20% | 响应时间 | 最近5分钟使用=20，30分钟内=15，更早=10 |
| 10% | 配额余量 | (1 - usageRate) * 10 |

**testApiKey(id, dto)** - 健康检查与测试

```typescript
检查项:
1. 连通性检查 (performHealthCheck)
2. 功能测试 (performFeatureTest) - 可选
3. 余额查询 (queryBalance)
4. supportedFeatures校验

// DEEPSEEK余额查询特殊处理
// 响应字段: balance_infos[].total_balance (不是balance)
// 修复记录: 2026-06-06 修复字段名错误导致余额误判
```

#### 2.2.3 控制器端点

| 方法 | 端点 | 权限 | 说明 |
|------|------|------|------|
| GET | /api-key | 用户 | 获取分配的API Key |
| POST | /api-key/refresh | 用户 | 刷新API Key分配 |
| GET | /api-key/admin/list | 管理员 | Key列表 |
| POST | /api-key/admin/create | 管理员 | 创建Key |
| POST | /api-key/admin/:id/test | 管理员 | 测试Key |

### 2.3 订阅套餐模块

#### 2.3.1 实体定义

**Plan** (`server/src/subscription/entities/plan.entity.ts`)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | 套餐ID（如monthly-basic） |
| name | string | 套餐名称 |
| priceCents | int | 价格（分） |
| durationDays | int | 有效期天数 |
| tokenQuota | int | Token配额 |
| allowedModels | string[] | 允许使用的模型列表 |
| defaultConfigs | jsonb | 功能→模型映射 |
| apiPolicies | jsonb | API策略数组 |
| isActive | boolean | 是否上架 |

**apiPolicies JSONB结构**

```json
[
  {
    "provider": "deepseek",
    "model": "deepseek-chat",
    "modelPattern": "deepseek-chat",
    "multiplier": 0.5,
    "isAllowed": true
  },
  {
    "provider": "qwen",
    "model": "qwen-max",
    "modelPattern": "qwen-max",
    "multiplier": 3.0,
    "isAllowed": true
  }
]
```

**defaultConfigs JSONB结构**

```json
{
  "textAnalysis": "qwen-max",
  "speechTranscribe": "qwen-turbo",
  "imageRecognition": "qwen-vl-plus"
}
```

#### 2.3.2 核心服务: SubscriptionService

**文件**: `server/src/subscription/subscription.service.ts`

**getSubscription(userId)**

```typescript
返回结构:
{
  planId: string,
  planName: string,
  status: 'active' | 'expired',
  expiresAt: Date,        // 实时计算: startedAt + plan.durationDays
  totalQuota: number,
  usedQuota: number,
  balanceTokens: number,
  freeTokensRemaining: number,
  apiPolicies: ApiPolicy[],
  defaultConfigs: DefaultConfig[],
  subscriptions: PlanSubscription[]  // 多套餐列表
}

// 修复记录: 2026-06-06 expiresAt改为实时计算
// 原因: admin修改durationDays后，已订阅用户应即时生效
```

**buildDefaultConfigsArray(defaultConfigs, apiPolicies)**

```typescript
// 将Map格式转为数组，并自动补全provider前缀
输入: { textAnalysis: "qwen-max" }
输出: [{ functionType: "textAnalysis", modelPattern: "qwen:qwen-max" }]

// 修复记录: 2026-06-06 支持自动从apiPolicies查找provider
// 原因: 服务器存储的defaultConfigs值只有模型名，不含provider
```

**computeExpiresAt(startedAt, durationDays, fallback)**

```typescript
// 实时计算过期时间
if (!startedAt || !durationDays || durationDays <= 0) return fallback;
return new Date(startedAt.getTime() + durationDays * 24 * 60 * 60 * 1000);
```

### 2.4 计费模块

#### 2.4.1 核心实体

**UserTokenBalance**

| 字段 | 说明 |
|------|------|
| userId | 用户ID |
| totalTokens | 总Token数 |
| usedTokens | 已用Token数 |
| balanceTokens | 付费余额 |
| freeTokensRemaining | 免费余额 |

**ApiUsageLog**

| 字段 | 说明 |
|------|------|
| userId | 用户ID |
| promptTokens | 输入Token数 |
| completionTokens | 输出Token数 |
| tokenConsumed | 实际消耗Token数 |
| apiCoefficient | API系数 |
| costYuan | 费用（元） |

#### 2.4.2 TokenBillingService

**consumeToken(userId, metadata)**

```typescript
计算流程:
1. 查ApiConfig获取baseCoefficient
2. tokenConsumed = ceil(rawAmount * coefficient)
3. 查TokenPricing获取单价
4. 优先扣减freeTokensRemaining
5. 检查并扣减balanceTokens
6. 记录ApiUsageLog
```

---

## 3. 客户端/APK架构

### 3.1 模块关系图

```
┌─────────────────────────────────────────────────────────────┐
│                      APK客户端                               │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ CloudConfig  │  │ ApiConfig    │  │  Billing     │      │
│  │ SyncService  │  │ Resolver     │  │  Service     │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                 │              │
│         ▼                 ▼                 ▼              │
│  ┌──────────────────────────────────────────────────┐     │
│  │              MultiApiConfig                      │     │
│  │  configs[] | functionAssignments[]               │     │
│  └──────────────────────────────────────────────────┘     │
│         │                                                 │
│         ▼                                                 │
│  ┌──────────────────────────────────────────────────┐     │
│  │  Storage (SharedPreferences) + SecureStorage      │     │
│  │  multi_api_config_v2 | cloud_api_config          │     │
│  └──────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 云端配置同步服务

**文件**: `lib/core/services/cloud_config_sync_service.dart`

#### 3.2.1 设计原则

1. **云端条目持久化**: 同步到`MultiApiConfig.configs`，标记`isCloudConfig=true`
2. **敏感信息隔离**: API Key不入普通Storage，从SecureStorage读取
3. **分配关系持久化**: `functionAssignments`存储场景到云端模型的映射
4. **清理回退**: 关闭云端AI时，functionAssignments回退到本地配置

#### 3.2.2 功能类型映射

| 服务端字段 | 客户端ApiFunctionType | 说明 |
|-----------|----------------------|------|
| textAnalysis | text | 文本分析 |
| speechTranscribe | voice | 语音转写 |
| speechRealtime | voiceRealtime | 实时语音 |
| speechOffline | offlineVoice | 离线语音 |
| imageRecognition | image | 图像识别 |

#### 3.2.3 核心方法

**syncApiPolicies({apiPolicies, defaultConfigs})**

```dart
流程:
1. 读取当前MultiApiConfig
2. 移除所有isCloudConfig=true的旧条目
3. 按apiPolicies生成新云端条目骨架:
   - id: cloud_{provider}_{model}
   - name: {provider} - {model}
   - provider: 枚举转换
   - model: modelPattern
   - isCloudConfig: true
   - cloudMultiplier: multiplier
   - apiKey: '' (运行时注入)
4. 从defaultConfigs推导每个模型支持的功能
5. 合并到configs，保留本地配置
6. 持久化到StorageService
```

**syncCloudDefaults({defaultConfigs, apiPolicies})**

```dart
流程:
1. 调用syncApiPolicies()
2. 应用defaultConfigs到functionAssignments:
   - 云端分配优先
   - configId格式: cloud_{provider}_{model}
3. 本地配置作为回退
4. 持久化到StorageService
```

**clearCloudConfigs()**

```dart
流程:
1. 过滤保留本地配置 (isCloudConfig=false)
2. 将指向云端的functionAssignments回退到本地默认配置
3. 更新defaultConfigId为本地第一个配置
4. 持久化到StorageService

// 修复记录: 2026-06-06 修复关闭云端后功能全挂
// 原因: 之前直接删除云端分配，未回退到本地配置
```

### 3.3 API配置解析器

**文件**: `lib/core/services/api_config_resolver.dart`

#### 3.3.1 三级回退策略

```dart
resolve(ApiFunctionType functionType):
  1. 未登录 → 直接走本地配置
  2. 已登录:
     a. 查functionAssignments，有明确分配 → 使用该配置
     b. 云端AI开启 → 从SecureStorage读取云端配置
     c. 回退到本地默认配置
```

#### 3.3.2 配置来源优先级

| 优先级 | 来源 | 条件 |
|--------|------|------|
| 1 | functionAssignments | 有明确场景分配 |
| 2 | SecureStorage.cloud_api_config | 云端AI开启且已登录 |
| 3 | StorageService.api_config | 本地默认配置 |

### 3.4 多API配置模型

**文件**: `lib/core/models/api_config.dart`

#### 3.4.1 ApiConfigEntry

```dart
class ApiConfigEntry {
  final String id;                    // 配置ID
  final String name;                  // 显示名称
  final AiProvider provider;          // 提供商枚举
  final String apiKey;                // API Key
  final String? baseUrl;              // 自定义Base URL
  final String model;                 // 模型名
  final List<ApiFunctionType> functions; // 支持功能
  final bool isActive;                // 是否启用
  final bool isCloudConfig;           // 是否为云端配置
  final double cloudMultiplier;       // 云端消耗系数
}
```

#### 3.4.2 MultiApiConfig

```dart
class MultiApiConfig {
  final List<ApiConfigEntry> configs;                    // 所有配置
  final List<ApiFunctionAssignment> functionAssignments; // 场景分配
  final String? defaultConfigId;                         // 默认配置ID
  
  ApiConfigEntry? getConfigForFunction(ApiFunctionType function) {
    // 按functionAssignments查找对应configId
    // 返回匹配的ApiConfigEntry
  }
}
```

### 3.5 计费服务

**文件**: `lib/core/services/billing_service.dart`

#### 3.5.1 FeatureType定义

| 类型 | 计量单位 | Token换算 |
|------|----------|-----------|
| transcription | 分钟 | 1分钟 = 1200 tokens |
| textAnalysis | 千字符 | 1千字符 = 1000 tokens |
| imageRecognition | 张 | 1张 = 2000 tokens |
| aiChat | tokens | 直接使用 |

#### 3.5.2 canUseFeature

```dart
Future<bool> canUseFeature(
  FeatureType type, 
  double amount, 
  {double multiplier = 1.0}
)

// 修复记录: 2026-06-06 增加multiplier参数
// 原因: DEEPSEEK系数0.5x，按1.0x计算会高估消耗导致误报余额不足

计算:
  estimatedTokens = (_estimateTokens(type, amount) * multiplier).ceil()
  return balance.hasEnough(estimatedTokens)
```

### 3.6 HttpClient与ApiService

**文件**: `lib/core/services/http_client.dart`, `lib/core/services/api_service.dart`

#### 3.6.1 HttpClient.configure

```dart
void configure({
  required String apiKey,
  required AiModelConfig config,
  String? customBaseUrl,
  String? appId,
  String? accessKeySecret,
  double multiplier = 1.0,  // 新增: 2026-06-06
})
```

#### 3.6.2 ApiService.configureFromServer

```dart
Future<void> configureFromServer(Map<String, dynamic> data) async {
  // 从服务器响应提取:
  // - provider, apiKey, baseUrl, model
  // - multiplier (从subscription apiPolicies查找)
  
  // 配置HttpClient
  configure(apiKey: apiKey, config: config, multiplier: multiplier);
  
  // 写入SecureStorage: cloud_api_config
  // 包含: provider, apiKey, baseUrl, model, multiplier
}
```

---

## 4. 核心数据流

### 4.1 用户登录完整流程

```
┌─────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  用户   │───▶│  登录/注册   │───▶│ 获取API Key │───▶│ 配置HttpClient│
└─────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                                          │
                              ┌───────────────────────────┘
                              ▼
                    ┌─────────────────┐
                    │  获取订阅信息    │
                    │  GET /subscription│
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ syncCloudDefaults │
                    │ 同步云端配置      │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ 应用到function   │
                    │ Assignments      │
                    └─────────────────┘
```

### 4.2 API调用时配置解析流程

```
业务层调用AI功能
    │
    ▼
┌─────────────────┐
│ ApiConfigResolver│
│ .resolve(type)   │
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼         ▼
function   云端配置    本地配置
Assignments  (开启时)   (回退)
    │         │         │
    └────┬────┘         │
         ▼              │
   ResolvedApiConfig    │
         │              │
         ▼              │
   applyToHttpClient    │
         │              │
         ▼              │
   实际HTTP请求 ◀───────┘
```

### 4.3 余额检查流程

```
准备调用AI
    │
    ▼
┌─────────────────────────┐
│ BillingService          │
│ .canUseFeature()        │
│ multiplier参数          │
└───────────┬─────────────┘
            │
            ▼
    ┌───────┴───────┐
    ▼               ▼
_estimateTokens   multiplier
    │               │
    └───────┬───────┘
            ▼
    estimatedTokens = ceil(estimate * multiplier)
            │
            ▼
    balance.hasEnough(estimatedTokens)
            │
       ┌────┴────┐
       ▼         ▼
     足够       不足
       │         │
       ▼         ▼
    继续调用   抛出异常
```

---

## 5. 关键接口契约

### 5.1 GET /api-key

**请求**: `GET /api/v1/api-key`
**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "provider": "deepseek",
    "apiKey": "sk-xxxxxxxx",
    "model": "deepseek-chat",
    "rateLimitPerMin": 60,
    "expiresAt": "2026-06-07T10:00:00.000Z"
  }
}
```

### 5.2 GET /subscription

**请求**: `GET /api/v1/subscription`
**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "planId": "trial",
    "planName": "新手体验包",
    "status": "active",
    "expiresAt": "2026-06-13T10:00:00.000Z",
    "totalQuota": 10000,
    "usedQuota": 0,
    "balanceTokens": 0,
    "freeTokensRemaining": 500,
    "apiPolicies": [
      {
        "provider": "deepseek",
        "modelPattern": "deepseek-chat",
        "multiplier": 0.5,
        "isAllowed": true
      }
    ],
    "defaultConfigs": [
      {
        "functionType": "textAnalysis",
        "modelPattern": "deepseek:deepseek-chat"
      }
    ],
    "subscriptions": [...]
  }
}
```

### 5.3 apiPolicies字段规范

```typescript
interface ApiPolicy {
  provider: string;        // 提供商: qwen | deepseek | openai | ...
  model?: string;          // 模型名（可选）
  modelPattern: string;    // 模型匹配模式
  multiplier: number;      // 消耗系数
  isAllowed: boolean;      // 是否允许使用
}
```

### 5.4 defaultConfigs字段规范

```typescript
// 服务器存储格式（Map）
interface DefaultConfigsMap {
  [functionType: string]: string;  // 值: 模型名（不含provider前缀）
}

// 示例
{
  "textAnalysis": "qwen-max",
  "speechTranscribe": "qwen-turbo"
}

// 服务器返回格式（数组）
interface DefaultConfig {
  functionType: string;
  modelPattern: string;  // provider:model 格式
}

// 示例
[
  { "functionType": "textAnalysis", "modelPattern": "qwen:qwen-max" }
]
```

---

## 6. 配置字段规范

### 6.1 服务器端Plan配置

| 配置项 | 类型 | 示例 | 说明 |
|--------|------|------|------|
| allowedModels | string[] | ["qwen-max", "deepseek-chat"] | 用户可用模型列表 |
| apiPolicies | ApiPolicy[] | 见5.3 | API策略，含系数 |
| defaultConfigs | Map | 见5.4 | 功能默认模型映射 |
| durationDays | int | 7/15/30 | 套餐有效期 |

### 6.2 客户端SecureStorage键

| Key | 用途 | 格式 |
|-----|------|------|
| cloud_api_config | 云端API配置 | JSON |
| secure_cloud_api_enabled | 云端AI开关 | bool字符串 |
| secure_cloud_access_token | 云端JWT | string |
| secure_cloud_refresh_token | 刷新Token | string |

### 6.3 客户端Storage键

| Key | 用途 | 格式 |
|-----|------|------|
| multi_api_config_v2 | 多API配置 | JSON |
| api_config | 本地单配置（兼容） | JSON |

---

## 7. 常见问题排查

### 7.1 DEEPSEEK显示余额不足但实际有余额

**症状**: WEB后台测试DEEPSEEK显示"余额已耗尽"，但实际账户有余额  
**根因**: `queryBalance`解析了错误字段`b.balance`，实际字段是`total_balance`  
**修复**: 将`parseFloat(b.balance)`改为`parseFloat(b.total_balance)`  
**文件**: `server/src/api-key/api-key.service.ts:558`

### 7.2 关闭云端AI后所有功能不可用

**症状**: 关闭云端AI开关后，文本分析/语音等功能全部报错  
**根因**: `clearCloudConfigs`删除了云端functionAssignments但未回退到本地配置  
**修复**: 关闭云端时，将指向云端的分配回退到本地默认配置  
**文件**: `lib/core/services/cloud_config_sync_service.dart`

### 7.3 API配置管理界面显示重复条目

**症状**: 云端2个API，界面显示4个（重复）  
**根因**: `_loadConfig`同时读取了Storage中的云端条目和重新生成的云端条目  
**修复**: 只从Storage读取，对云端条目注入apiKey即可，不再重新生成  
**文件**: `lib/features/settings/screens/multi_api_config_screen.dart`

### 7.4 有效期不随云端套餐更新

**症状**: admin修改套餐durationDays后，用户端仍显示旧有效期  
**根因**: `getSubscription`直接返回subscription.expiresAt（创建时写入的固定值）  
**修复**: 返回时实时计算`startedAt + plan.durationDays`  
**文件**: `server/src/subscription/subscription.service.ts`

### 7.5 DEEPSEEK/千问测试不通过

**症状**: WEB后台测试API Key显示失败  
**根因**: `isKeyAvailable`要求`lastHealthCheckStatus === 'healthy'`，但余额低时状态为`degraded`  
**修复**: 允许`degraded`状态（API可用但有警告），只有`unhealthy`才不可用  
**文件**: `server/src/api-key/api-key.service.ts:715`

---

## 8. 迭代记录

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-06-06 | 1.0 | 初始文档建立，汇总云端API配置完整架构 |
| 2026-06-06 | - | 修复DEEPSEEK余额字段解析错误 (`balance` → `total_balance`) |
| 2026-06-06 | - | 修复有效期实时计算 (`subscription.expiresAt` → `startedAt + durationDays`) |
| 2026-06-06 | - | 修复API配置重复显示 (去重逻辑) |
| 2026-06-06 | - | 修复关闭云端后功能回退 (clearCloudConfigs回退到本地) |
| 2026-06-06 | - | 修复isKeyAvailable允许degraded状态 |
| 2026-06-06 | - | 修复canUseFeature支持multiplier参数 |
| 2026-06-06 | - | 修复defaultConfigs自动补全provider前缀 |
