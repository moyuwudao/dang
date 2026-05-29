# 畅记AI - 多模式计费系统设计方案

## 1. 业务需求分析

### 1.1 三种付费模式

| 模式 | 说明 | 适用场景 |
|------|------|----------|
| **订阅制** | 月度/年度付费，包含多种功能配额 | 重度用户，需要完整功能 |
| **资源包** | 单项或组合资源包，一次性购买 | 轻度用户，仅需特定功能 |
| **按量付费** | 充值金额，按实际Token消耗扣费 | 灵活使用，不确定用量 |

### 1.2 功能类型定义

| 功能类型 | 计费单位 | 说明 |
|----------|----------|------|
| `transcription` | 分钟 | 语音转写 |
| `realtime_transcription` | 分钟 | 实时语音转写 |
| `text_analysis` | 千字符 | 文本分析/总结 |
| `image_recognition` | 张 | 图像识别/理解 |
| `ocr` | 张 | OCR文字识别 |
| `ai_chat` | Token | AI对话（按实际Token） |
| `tts` | 千字符 | 语音合成 |

### 1.3 资源包组合

| 资源包名称 | 包含功能 | 目标用户 |
|------------|----------|----------|
| 语音包 | transcription + realtime_transcription | 会议记录用户 |
| 语音+文本包 | 语音包 + text_analysis | 需要分析的用户 |
| 图像包 | image_recognition + ocr | 文档处理用户 |
| 图像+文本包 | 图像包 + text_analysis | 综合处理用户 |
| 文本包 | text_analysis + ai_chat | 纯文本用户 |

---

## 2. 数据模型设计

### 2.1 套餐表（plans）- 扩展

```typescript
@Entity('plans')
export class Plan {
  @PrimaryColumn()
  id: string;

  @Column()
  name: string;

  @Column({ nullable: true })
  description: string;

  @Column({ name: 'price_cents' })
  priceCents: number;

  @Column({ name: 'duration_days', default: 30 })
  durationDays: number;

  // 套餐类型：subscription(订阅) | package(资源包) | recharge(充值)
  @Column({ default: 'subscription' })
  type: string;

  // 资源包专用：包含的功能类型列表
  @Column({ type: 'simple-array', nullable: true })
  includedFeatures: string[];

  @Column({ type: 'simple-array', nullable: true })
  features: string[];

  @Column({ name: 'is_recommended', default: false })
  isRecommended: boolean;

  // 统一配额字段（兼容现有）
  @Column({ name: 'quota_type', default: 'minutes' })
  quotaType: string;

  @Column({ name: 'quota_value', nullable: true })
  quotaValue: number;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @OneToMany(() => PlanFeatureQuota, q => q.plan)
  featureQuotas: PlanFeatureQuota[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
```

### 2.2 套餐功能配额表（plan_feature_quotas）- 新增

```typescript
@Entity('plan_feature_quotas')
export class PlanFeatureQuota {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'plan_id' })
  planId: string;

  @Column({ name: 'feature_type' })
  featureType: string; // transcription | text_analysis | image_recognition | ocr | ai_chat | tts

  @Column({ name: 'quota_value' })
  quotaValue: number;

  @Column({ name: 'quota_unit' })
  quotaUnit: string; // minutes | thousand_chars | images | tokens

  // 成本系数（不同模型不同系数）
  @Column({ default: 1.0 })
  multiplier: number;

  @ManyToOne(() => Plan, plan => plan.featureQuotas)
  @JoinColumn({ name: 'planId' })
  plan: Plan;
}
```

### 2.3 用户订阅表（subscriptions）- 扩展

```typescript
@Entity('subscriptions')
export class Subscription {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({ name: 'plan_id' })
  planId: string;

  // 新增：套餐类型
  @Column({ default: 'subscription' })
  type: string; // subscription | package

  @Column({ name: 'started_at' })
  startedAt: Date;

  @Column({ name: 'expires_at' })
  expiresAt: Date;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  // 统一配额（兼容现有）
  @Column({ name: 'quota_used', default: 0 })
  quotaUsed: number;

  @Column({ name: 'quota_total', default: 0 })
  quotaTotal: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
```

### 2.4 用户功能配额使用表（user_feature_usage）- 新增

```typescript
@Entity('user_feature_usage')
export class UserFeatureUsage {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({ name: 'subscription_id' })
  subscriptionId: string;

  @Column({ name: 'feature_type' })
  featureType: string;

  @Column({ name: 'used_amount', default: 0 })
  usedAmount: number;

  @Column({ name: 'total_amount' })
  totalAmount: number;

  @Column({ name: 'unit' })
  unit: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
```

### 2.5 用户余额表（user_balances）- 扩展

```typescript
@Entity('user_balances')
export class UserBalance {
  @PrimaryColumn()
  userId: string;

  @Column({ default: 0 })
  balanceCents: number;

  @Column({ name: 'gift_balance_cents', default: 0 })
  giftBalanceCents: number;

  @Column({ default: 0 })
  totalRechargedCents: number;

  @Column({ default: 0 })
  totalRefundedCents: number;

  @OneToOne(() => User, user => user.balance)
  @JoinColumn({ name: 'userId' })
  user: User;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
```

### 2.6 Token价格配置表（token_pricing）- 新增

```typescript
@Entity('token_pricing')
export class TokenPricing {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'provider' })
  provider: string; // openai | anthropic | gemini

  @Column({ name: 'model_pattern' })
  modelPattern: string; // gpt-4 | claude-3-opus | *

  @Column({ name: 'prompt_price_per_1k' })
  promptPricePer1k: number; // 每1000 tokens输入价格（分）

  @Column({ name: 'completion_price_per_1k' })
  completionPricePer1k: number; // 每1000 tokens输出价格（分）

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
```

### 2.7 API使用日志表（api_usage_logs）- 扩展

```typescript
@Entity('api_usage_logs')
export class ApiUsageLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({ name: 'provider' })
  provider: string;

  @Column({ name: 'model' })
  model: string;

  @Column({ name: 'feature_type', nullable: true })
  featureType: string; // 新增：功能类型

  @Column({ name: 'resource_consumed', nullable: true })
  resourceConsumed: number; // 新增：实际消耗资源量

  @Column({ name: 'unit', nullable: true })
  unit: string; // 新增：单位

  @Column({ name: 'cost_cents', nullable: true })
  costCents: number; // 新增：实际成本（分）

  @Column({ name: 'prompt_tokens', nullable: true })
  promptTokens: number;

  @Column({ name: 'completion_tokens', nullable: true })
  completionTokens: number;

  @Column({ name: 'total_tokens', nullable: true })
  totalTokens: number;

  @Column({ name: 'multiplier', default: 1 })
  multiplier: number;

  @Column({ name: 'quota_consumed', default: 0 })
  quotaConsumed: number;

  @Column({ name: 'created_at' })
  createdAt: Date;
}
```

---

## 3. 核心业务逻辑设计

### 3.1 计费策略接口

```typescript
// 计费策略接口
interface BillingStrategy {
  // 检查是否可以使用
  canUse(userId: string, featureType: string, amount: number): Promise<boolean>;
  
  // 使用资源
  consume(userId: string, featureType: string, amount: number, metadata?: any): Promise<ConsumeResult>;
  
  // 获取剩余配额
  getRemaining(userId: string, featureType: string): Promise<number>;
}

interface ConsumeResult {
  success: boolean;
  consumed: number;
  remaining: number;
  costCents?: number;
  message?: string;
}
```

### 3.2 三种计费策略实现

#### 3.2.1 订阅制策略（SubscriptionBillingStrategy）

```typescript
@Injectable()
export class SubscriptionBillingStrategy implements BillingStrategy {
  constructor(
    @InjectRepository(Subscription)
    private subscriptionRepo: Repository<Subscription>,
    @InjectRepository(UserFeatureUsage)
    private featureUsageRepo: Repository<UserFeatureUsage>,
  ) {}

  async canUse(userId: string, featureType: string, amount: number): Promise<boolean> {
    // 1. 查找有效订阅
    const subscription = await this.getActiveSubscription(userId);
    if (!subscription) return false;

    // 2. 检查功能是否在订阅范围内
    const featureQuota = await this.getFeatureQuota(subscription.planId, featureType);
    if (!featureQuota) return false;

    // 3. 检查配额是否充足
    const usage = await this.getFeatureUsage(userId, subscription.id, featureType);
    return (usage.usedAmount + amount) <= usage.totalAmount;
  }

  async consume(userId: string, featureType: string, amount: number): Promise<ConsumeResult> {
    const subscription = await this.getActiveSubscription(userId);
    if (!subscription) {
      return { success: false, consumed: 0, remaining: 0, message: '无有效订阅' };
    }

    const usage = await this.getFeatureUsage(userId, subscription.id, featureType);
    if (usage.usedAmount + amount > usage.totalAmount) {
      return { success: false, consumed: 0, remaining: usage.totalAmount - usage.usedAmount, message: '配额不足' };
    }

    // 更新使用量
    usage.usedAmount += amount;
    await this.featureUsageRepo.save(usage);

    return {
      success: true,
      consumed: amount,
      remaining: usage.totalAmount - usage.usedAmount,
    };
  }

  async getRemaining(userId: string, featureType: string): Promise<number> {
    const subscription = await this.getActiveSubscription(userId);
    if (!subscription) return 0;

    const usage = await this.getFeatureUsage(userId, subscription.id, featureType);
    return usage.totalAmount - usage.usedAmount;
  }
}
```

#### 3.2.2 资源包策略（PackageBillingStrategy）

```typescript
@Injectable()
export class PackageBillingStrategy implements BillingStrategy {
  constructor(
    @InjectRepository(Subscription)
    private subscriptionRepo: Repository<Subscription>,
    @InjectRepository(UserFeatureUsage)
    private featureUsageRepo: Repository<UserFeatureUsage>,
  ) {}

  async canUse(userId: string, featureType: string, amount: number): Promise<boolean> {
    // 资源包没有过期时间，只要配额没用完就可以用
    const packages = await this.getActivePackages(userId);
    
    for (const pkg of packages) {
      const usage = await this.getFeatureUsage(userId, pkg.id, featureType);
      if (usage && (usage.usedAmount + amount) <= usage.totalAmount) {
        return true;
      }
    }
    return false;
  }

  async consume(userId: string, featureType: string, amount: number): Promise<ConsumeResult> {
    const packages = await this.getActivePackages(userId);
    
    for (const pkg of packages) {
      const usage = await this.getFeatureUsage(userId, pkg.id, featureType);
      if (usage && (usage.usedAmount + amount) <= usage.totalAmount) {
        usage.usedAmount += amount;
        await this.featureUsageRepo.save(usage);

        // 检查是否用完，用完标记为过期
        if (usage.usedAmount >= usage.totalAmount) {
          pkg.isActive = false;
          await this.subscriptionRepo.save(pkg);
        }

        return {
          success: true,
          consumed: amount,
          remaining: usage.totalAmount - usage.usedAmount,
        };
      }
    }

    return { success: false, consumed: 0, remaining: 0, message: '无有效资源包' };
  }

  async getRemaining(userId: string, featureType: string): Promise<number> {
    const packages = await this.getActivePackages(userId);
    let total = 0;
    
    for (const pkg of packages) {
      const usage = await this.getFeatureUsage(userId, pkg.id, featureType);
      if (usage) {
        total += (usage.totalAmount - usage.usedAmount);
      }
    }
    return total;
  }
}
```

#### 3.2.3 按量付费策略（PayAsYouGoBillingStrategy）

```typescript
@Injectable()
export class PayAsYouGoBillingStrategy implements BillingStrategy {
  constructor(
    @InjectRepository(UserBalance)
    private balanceRepo: Repository<UserBalance>,
    @InjectRepository(TokenPricing)
    private pricingRepo: Repository<TokenPricing>,
    @InjectRepository(ApiUsageLog)
    private usageLogRepo: Repository<ApiUsageLog>,
  ) {}

  async canUse(userId: string, featureType: string, amount: number): Promise<boolean> {
    const balance = await this.balanceRepo.findOne({ where: { userId } });
    if (!balance || balance.balanceCents <= 0) return false;

    // 计算预估成本
    const estimatedCost = await this.calculateCost(featureType, amount);
    return balance.balanceCents >= estimatedCost;
  }

  async consume(userId: string, featureType: string, amount: number, metadata?: any): Promise<ConsumeResult> {
    const balance = await this.balanceRepo.findOne({ where: { userId } });
    if (!balance) {
      return { success: false, consumed: 0, remaining: 0, message: '余额不足' };
    }

    const costCents = await this.calculateCost(featureType, amount, metadata);
    if (balance.balanceCents < costCents) {
      return { success: false, consumed: 0, remaining: balance.balanceCents, message: '余额不足' };
    }

    // 扣减余额
    balance.balanceCents -= costCents;
    await this.balanceRepo.save(balance);

    // 记录使用日志
    await this.usageLogRepo.save({
      userId,
      provider: metadata?.provider || 'unknown',
      model: metadata?.model || 'unknown',
      featureType,
      resourceConsumed: amount,
      costCents,
      promptTokens: metadata?.promptTokens,
      completionTokens: metadata?.completionTokens,
      totalTokens: metadata?.totalTokens,
    });

    return {
      success: true,
      consumed: amount,
      remaining: balance.balanceCents,
      costCents,
    };
  }

  async getRemaining(userId: string): Promise<number> {
    const balance = await this.balanceRepo.findOne({ where: { userId } });
    return balance?.balanceCents || 0;
  }

  private async calculateCost(featureType: string, amount: number, metadata?: any): Promise<number> {
    switch (featureType) {
      case 'ai_chat':
        return this.calculateTokenCost(metadata?.provider, metadata?.model, metadata?.promptTokens, metadata?.completionTokens);
      case 'transcription':
        return Math.ceil(amount * 5); // 5分/分钟
      case 'text_analysis':
        return Math.ceil(amount * 2); // 2分/千字符
      case 'image_recognition':
        return Math.ceil(amount * 10); // 10分/张
      default:
        return 0;
    }
  }

  private async calculateTokenCost(provider: string, model: string, promptTokens: number, completionTokens: number): Promise<number> {
    const pricing = await this.pricingRepo.findOne({
      where: { provider, modelPattern: model, isActive: true },
    });

    if (!pricing) {
      // 使用默认价格
      return Math.ceil((promptTokens + completionTokens) * 0.01); // 0.01分/token
    }

    const promptCost = (promptTokens / 1000) * pricing.promptPricePer1k;
    const completionCost = (completionTokens / 1000) * pricing.completionPricePer1k;
    return Math.ceil(promptCost + completionCost);
  }
}
```

### 3.3 计费策略工厂

```typescript
@Injectable()
export class BillingStrategyFactory {
  constructor(
    private subscriptionStrategy: SubscriptionBillingStrategy,
    private packageStrategy: PackageBillingStrategy,
    private payAsYouGoStrategy: PayAsYouGoBillingStrategy,
  ) {}

  getStrategy(userId: string, featureType: string): Promise<BillingStrategy> {
    // 优先级：订阅制 > 资源包 > 按量付费
    
    // 1. 检查是否有订阅制且包含该功能
    if (await this.subscriptionStrategy.canUse(userId, featureType, 0)) {
      return this.subscriptionStrategy;
    }

    // 2. 检查是否有资源包且包含该功能
    if (await this.packageStrategy.canUse(userId, featureType, 0)) {
      return this.packageStrategy;
    }

    // 3. 使用按量付费
    return this.payAsYouGoStrategy;
  }
}
```

---

## 4. 余额转换与套餐兑换逻辑

### 4.1 余额转换服务

```typescript
@Injectable()
export class BalanceConversionService {
  constructor(
    @InjectRepository(UserBalance)
    private balanceRepo: Repository<UserBalance>,
    @InjectRepository(Subscription)
    private subscriptionRepo: Repository<Subscription>,
    @InjectRepository(RechargeRecord)
    private rechargeRecordRepo: Repository<RechargeRecord>,
    private subscriptionService: SubscriptionService,
  ) {}

  /**
   * 使用余额购买订阅/资源包
   */
  async purchaseWithBalance(
    userId: string,
    planId: string,
  ): Promise<{ success: boolean; message: string; subscription?: Subscription }> {
    // 1. 查询套餐
    const plan = await this.subscriptionService.getPlanById(planId);
    if (!plan) {
      return { success: false, message: '套餐不存在' };
    }

    // 2. 查询余额
    const balance = await this.balanceRepo.findOne({ where: { userId } });
    if (!balance || balance.balanceCents < plan.priceCents) {
      return { success: false, message: '余额不足' };
    }

    // 3. 扣减余额
    balance.balanceCents -= plan.priceCents;
    await this.balanceRepo.save(balance);

    // 4. 创建订阅/资源包
    const subscription = await this.subscriptionService.createSubscription(userId, planId);

    // 5. 记录转换日志
    await this.rechargeRecordRepo.save({
      userId,
      amountCents: -plan.priceCents,
      paymentMethod: 'balance_conversion',
      status: 'success',
      remark: `余额购买套餐: ${plan.name}`,
    });

    return { success: true, message: '购买成功', subscription };
  }

  /**
   * 余额转赠（可选功能）
   */
  async transferBalance(
    fromUserId: string,
    toUserId: string,
    amountCents: number,
  ): Promise<{ success: boolean; message: string }> {
    // 检查余额
    const fromBalance = await this.balanceRepo.findOne({ where: { userId: fromUserId } });
    if (!fromBalance || fromBalance.balanceCents < amountCents) {
      return { success: false, message: '余额不足' };
    }

    // 扣减转出方
    fromBalance.balanceCents -= amountCents;
    await this.balanceRepo.save(fromBalance);

    // 增加转入方
    let toBalance = await this.balanceRepo.findOne({ where: { userId: toUserId } });
    if (!toBalance) {
      toBalance = this.balanceRepo.create({ userId: toUserId, balanceCents: 0 });
    }
    toBalance.balanceCents += amountCents;
    await this.balanceRepo.save(toBalance);

    return { success: true, message: '转账成功' };
  }
}
```

---

## 5. API接口设计

### 5.1 套餐相关接口

```typescript
// GET /subscription/plans?type=subscription|package|recharge
// 获取套餐列表（按类型筛选）

// POST /subscription/purchase
// 购买套餐（支持余额支付）
{
  planId: string;
  paymentMethod: 'balance' | 'wechat' | 'alipay';
}

// GET /subscription/feature-usage
// 获取各功能使用情况
{
  transcription: { used: 100, total: 300, unit: 'minutes' },
  text_analysis: { used: 50, total: 200, unit: 'thousand_chars' },
  image_recognition: { used: 10, total: 50, unit: 'images' },
}
```

### 5.2 按量付费接口

```typescript
// POST /subscription/pay-as-you-go/consume
// 按量消费
{
  featureType: string;
  amount: number;
  provider?: string;
  model?: string;
  tokens?: { prompt: number; completion: number };
}

// GET /subscription/pay-as-you-go/pricing
// 获取按量付费价格表
{
  transcription: { unit: 'minutes', pricePerUnit: 5 },
  text_analysis: { unit: 'thousand_chars', pricePerUnit: 2 },
  image_recognition: { unit: 'images', pricePerUnit: 10 },
  ai_chat: { unit: 'tokens', pricePer1k: { prompt: 10, completion: 30 } },
}
```

### 5.3 余额转换接口

```typescript
// POST /subscription/convert-balance
// 余额购买套餐
{
  planId: string;
}

// POST /subscription/recharge
// 充值（现有）
{
  amount: number;
  paymentMethod: 'wechat' | 'alipay';
}
```

---

## 6. 客户端集成方案

### 6.1 计费服务封装

```dart
class BillingService {
  final ApiService _api;
  
  BillingService(this._api);

  // 使用功能前检查
  Future<bool> canUseFeature(FeatureType type, double amount) async {
    final response = await _api.post('/subscription/check-feature', {
      'featureType': type.name,
      'amount': amount,
    });
    return response.data['canUse'] ?? false;
  }

  // 使用功能
  Future<ConsumeResult> consumeFeature(
    FeatureType type, 
    double amount, {
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _api.post('/subscription/consume-feature', {
      'featureType': type.name,
      'amount': amount,
      ...?metadata,
    });
    return ConsumeResult.fromJson(response.data);
  }

  // 获取功能使用情况
  Future<Map<FeatureType, FeatureUsage>> getFeatureUsage() async {
    final response = await _api.get('/subscription/feature-usage');
    return Map.fromEntries(
      response.data.entries.map((e) => MapEntry(
        FeatureType.values.byName(e.key),
        FeatureUsage.fromJson(e.value),
      )),
    );
  }
}
```

### 6.2 各服务集成计费

```dart
class TextAnalysisService {
  final BillingService _billing;
  
  Future<String> analyzeText(String text) async {
    // 1. 预估消耗
    final estimatedChars = text.length / 1000;
    
    // 2. 检查配额
    final canUse = await _billing.canUseFeature(
      FeatureType.textAnalysis, 
      estimatedChars,
    );
    if (!canUse) throw InsufficientQuotaException();

    // 3. 调用API
    final result = await _callApi(text);
    
    // 4. 实际扣费
    final actualChars = (text.length + result.length) / 1000;
    await _billing.consumeFeature(
      FeatureType.textAnalysis, 
      actualChars,
    );
    
    return result;
  }
}

class ImageRecognitionService {
  final BillingService _billing;
  
  Future<String> recognizeImage(String imagePath) async {
    // 图像识别按张计费
    final canUse = await _billing.canUseFeature(
      FeatureType.imageRecognition, 
      1,
    );
    if (!canUse) throw InsufficientQuotaException();

    final result = await _callApi(imagePath);
    
    await _billing.consumeFeature(
      FeatureType.imageRecognition, 
      1,
    );
    
    return result;
  }
}
```

---

## 7. 实施计划

### 阶段一：数据库迁移（2-3天）

1. 创建新表
   - `plan_feature_quotas`
   - `user_feature_usage`
   - `token_pricing`

2. 修改现有表
   - `plans`：添加 `type`, `includedFeatures`
   - `subscriptions`：添加 `type`
   - `api_usage_logs`：添加 `featureType`, `resourceConsumed`, `costCents`
   - `user_balances`：添加 `giftBalanceCents`

3. 数据迁移
   - 现有套餐数据迁移到新的配额模型
   - 设置默认的Token价格

### 阶段二：服务端开发（4-5天）

1. 实现三种计费策略
2. 实现计费策略工厂
3. 实现余额转换服务
4. 修改现有API接口
5. 添加新的API接口

### 阶段三：客户端开发（3-4天）

1. 修改订阅页面（支持三种模式展示）
2. 添加资源包购买页面
3. 添加按量付费价格展示
4. 修改各服务集成计费
5. 添加余额转换功能

### 阶段四：测试与上线（2-3天）

1. 单元测试
2. 集成测试
3. 回归测试
4. 上线部署

---

## 8. 关键设计决策

### 8.1 计费优先级

```
用户发起请求 → 检查订阅制 → 检查资源包 → 使用按量付费
                ↓              ↓              ↓
              有配额？        有配额？        有余额？
                ↓              ↓              ↓
              使用订阅配额    使用资源包配额   扣减余额
```

### 8.2 配额共享策略

- **订阅制**：各功能独立配额，互不影响
- **资源包**：按购买时的配置，可包含多个功能
- **按量付费**：余额通用，所有功能共享

### 8.3 过期处理

- **订阅制**：到期后自动失效，可续费
- **资源包**：用完即失效，无时间限制
- **按量付费**：余额长期有效，可退款

---

## 9. 风险与应对

| 风险 | 影响 | 应对措施 |
|------|------|----------|
| 数据迁移失败 | 高 | 备份数据，分步迁移，回滚方案 |
| 计费不准确 | 高 | 详细日志，对账机制，人工审核 |
| 用户不理解新计费 | 中 | 清晰文档，示例说明，客服培训 |
| 性能问题 | 中 | 缓存优化，异步处理，限流 |

---

## 10. 后续优化方向

1. **智能推荐**：根据用户使用习惯推荐最优套餐
2. **家庭共享**：支持多人共享订阅
3. **企业版**：支持团队管理和统一计费
4. **优惠活动**：限时折扣，首充优惠等
5. **使用分析**：提供详细的使用报告和优化建议
