# 服务器状态与部署记录

> **服务器**: 101.133.238.249 (changji)
> **实际用户**: admin
> **后端路径**: `/home/admin/dang/server/`
> **最后更新**: 2026-06-02

---

## 一、本次部署记录（2026-06-02）

### 1.1 部署内容

| 模块 | 变更内容 | 文件 |
|------|---------|------|
| API Key 分配策略 | 实现加权轮询 + 配额预检 + 健康过滤 | `api-key.service.ts` |
| Redis 缓存机制 | 三层缓存：用户分配、活跃Key列表、实时使用量 | `api-key.service.ts` |
| AI 服务集成 | 调用 `recordKeyUsage` 更新实时使用量缓存 | `ai.service.ts` |
| 模块依赖 | ApiKeyModule 添加 RedisModule 依赖 | `api-key.module.ts` |

### 1.2 部署结果

```bash
# 部署命令
cd /home/admin/dang/server
git pull origin master      # ✅ Already up to date
npm run build               # ✅ 构建成功
npx pm2 restart changji-api # ✅ 重启成功
npx pm2 status              # ✅ online, PID 557292
curl -s http://localhost:3000/api/v1/health  # 待验证
```

### 1.3 服务状态

| 服务 | 状态 | PID | 内存 | 重启次数 |
|------|------|-----|------|---------|
| changji-api | online | 557292 | ~81MB | 12 |

---

## 二、多用户API访问架构改进

### 2.1 问题背景

**原有问题**：
- `ApiKeyService.assignNewKey()` 使用 `findOne({ where: { status: ACTIVE } })` 取第一个可用 Key
- 所有用户可能分配到同一个 API Key，导致该 Key 的配额快速耗尽
- 每次请求都查询数据库，无 Redis 缓存

### 2.2 解决方案

#### 2.2.1 加权轮询分配算法

```typescript
// 综合评分 = 使用率(40%) + 健康度(30%) + 响应时间(20%) + 配额余量(10%)
private selectOptimalKey(keys: ApiKey[]): ApiKey {
  const scoredKeys = keys.map(key => {
    const usageRate = key.dailyQuota > 0 ? key.dailyUsage / key.dailyQuota : 0;
    const usageScore = (1 - usageRate) * 40;
    
    let healthScore = 30;
    if (key.lastHealthCheckStatus === 'healthy') healthScore = 30;
    else if (key.lastHealthCheckStatus === 'unhealthy') healthScore = 0;
    else healthScore = 15;
    
    // ... 响应时间评分、配额余量评分
    
    return { key, score: usageScore + healthScore + responseScore + quotaScore };
  });
  
  // 分数相近时随机选择，避免总是命中同一个
  scoredKeys.sort((a, b) => b.score - a.score);
  const topKeys = scoredKeys.filter(s => s.score >= scoredKeys[0].score - 5);
  if (topKeys.length > 1) {
    return topKeys[Math.floor(Math.random() * topKeys.length)].key;
  }
  return scoredKeys[0].key;
}
```

#### 2.2.2 三层 Redis 缓存

| 缓存键 | TTL | 用途 |
|--------|-----|------|
| `api:active_keys` | 5分钟 | 活跃Key列表，减少数据库查询 |
| `api:user_key:${userId}` | 24小时 | 用户分配关系，确保同一用户持续命中同一Key |
| `api:key_usage:${keyId}` | 当天有效 | 实时使用量，用于动态负载均衡 |

#### 2.2.3 配额预检与并发控制

```typescript
// 分配前检查
private isKeyAvailable(key: ApiKey): boolean {
  if (key.status !== ApiKeyStatus.ACTIVE) return false;
  if (key.lastHealthCheckStatus !== 'healthy') return false;
  if (key.dailyUsage >= key.dailyQuota) return false;
  if (key.expiresAt && key.expiresAt < new Date()) return false;
  return true;
}

// 并发负载检查
if (assignedUserCount >= selectedKey.maxConcurrentRequests) {
  const alternativeKey = this.findLessLoadedKey(availableKeys, selectedKey);
  if (alternativeKey) {
    return this.assignKeyToUser(userId, alternativeKey);
  }
}
```

### 2.3 缓存命中策略

**用户缓存命中流程**：

```
用户请求 API Key
  ↓
1. 查 Redis: `api:user_key:${userId}`
  ├→ 命中 → 获取 Key ID → 验证 Key 是否仍可用 → 返回
  └→ 未命中 → 继续
  ↓
2. 查数据库: user_api_key 表
  ├→ 找到活跃分配 → 缓存到 Redis → 返回
  └→ 未找到 → 继续
  ↓
3. 执行加权轮询分配新 Key
  ├→ 查 Redis 活跃Key列表（或数据库）
  ├→ 过滤可用Key（配额预检）
  ├→ 加权评分选择最优Key
  ├→ 并发负载检查
  └→ 分配并缓存到 Redis
```

---

## 三、计费系统重构记录

### 3.1 重构背景

原计费系统过于复杂，包含：
- 多种计费标准（按分钟、按字符、按TOKEN）
- 功能类型字段（AI对话、语言转写等）
- 复杂的套餐配置（quotaType、quotaValue、features等）

### 3.2 新方案

| 项目 | 旧方案 | 新方案 |
|------|--------|--------|
| 计费模式 | 多种（分钟/字符/TOKEN） | 仅TOKEN计费 |
| 功能类型 | AI对话、语言转写等 | 全部删除 |
| 价格单位 | 分 | 元 |
| API系数 | 手动配置 | 基于API配置自动生成，可调整 |
| 用户费用 | 复杂计算 | TOKEN消耗 × TOKEN单价 |
| 套餐类型 | 复杂套餐 | 月度套餐（固定TOKEN）+ 充值（实时消耗） |

### 3.3 核心公式

```
用户端TOKEN消耗 = Σ（API系数 × 原始TOKEN消耗）
用户端费用 = TOKEN消耗 × TOKEN单价
```

### 3.4 已修改文件

**后端**：
- `server/src/subscription/entities/plan.entity.ts` - 简化套餐实体
- `server/src/subscription/entities/subscription.entity.ts` - 简化订阅实体
- `server/src/subscription/services/token-billing.service.ts` - Token计费核心服务
- `server/src/admin/admin.controller.ts` - 添加删除订阅API
- `server/src/admin/admin.service.ts` - 添加删除订阅服务

**前端**：
- `admin/pages/billing-config.tsx` - 计费配置页面重构
- `admin/pages/subscriptions.tsx` - 订阅管理页面重构（标签页+TOKEN显示+删除过期）
- `admin/pages/plan-editor.tsx` - 套餐编辑页面简化
- `admin/services/api.ts` - API调用封装更新
- `admin/types/index.ts` - 类型定义清理

---

## 四、已知问题与修复记录

### 4.1 已修复问题

| 问题 | 原因 | 修复方式 |
|------|------|---------|
| 所有用户分配到同一API Key | `findOne` 取第一个可用Key | 实现加权轮询 + 随机打散 |
| 每次请求查数据库 | 无缓存机制 | 添加Redis三层缓存 |
| 计费配置页面客户端异常 | `toFixed` 调用非数字类型 | `Number()` 转换 |
| AdminModule依赖注入错误 | MonitorService/MetricsService缺失 | 使用 `@Optional()` 装饰器 |
| JWT令牌无效 | token保存路径错误 | 修复 `response.accessToken` |
| API系数接口404 | 前端路径与后端不匹配 | 统一为 `/admin/api-configs` |
| 模型价格保存报错 | 数据库列不存在 | 添加缺失列 |
| 套餐列表显示分钟 | 前端未更新 | 改为显示TOKEN数量 |

### 4.2 待验证问题

| 问题 | 状态 |
|------|------|
| 健康检查 curl 结果 | 待确认 |
| 多用户API分配实际效果 | 待测试 |
| Redis缓存命中率 | 待监控 |

---

## 五、部署检查清单

```bash
# 1. 确认路径
cd /home/admin/dang/server
pwd  # 应输出 /home/admin/dang/server

# 2. 拉取代码
git pull origin master

# 3. 构建
npm run build

# 4. 确认编译输出
ls dist/main.js  # 应存在

# 5. 重启服务
npx pm2 restart changji-api

# 6. 验证状态
npx pm2 status
curl -s http://localhost:3000/api/v1/health

# 7. 查看日志（如有异常）
npx pm2 logs changji-api --lines 20 --nostream
```

---

## 六、更新记录

| 日期 | 版本 | 更新内容 |
|-----|------|---------|
| 2026-06-02 | v1.0 | 初始版本：记录API分配策略改进、计费系统重构、部署状态 |

---

*本文档记录服务器部署状态、架构改进和已知问题，便于后续维护和更新。*
