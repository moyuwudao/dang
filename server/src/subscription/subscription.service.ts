import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Subscription } from './entities/subscription.entity';
import { Plan } from './entities/plan.entity';
import { UserTokenBalance } from './entities/user-token-balance.entity';
import { RechargeRecord } from './entities/recharge-record.entity';
import { ApiUsageLog } from './entities/api-usage-log.entity';
import { CreatePlanDto, RechargeDto, RefundDto } from './dto';
import { PlanService } from '../plan/plan.service';
import { TokenBillingService } from './services/token-billing.service';

@Injectable()
export class SubscriptionService {
  constructor(
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
    @InjectRepository(Plan)
    private planRepository: Repository<Plan>,
    @InjectRepository(UserTokenBalance)
    private userTokenBalanceRepository: Repository<UserTokenBalance>,
    @InjectRepository(RechargeRecord)
    private rechargeRecordRepository: Repository<RechargeRecord>,
    @InjectRepository(ApiUsageLog)
    private apiUsageLogRepository: Repository<ApiUsageLog>,
    private planService: PlanService,
    private tokenBillingService: TokenBillingService,
  ) {}

  // 提取套餐分配的 API
  // 优先级：plan.allowedModels（云端「已勾选 API」权威列表） > plan.apiPolicies（兜底） > 空数组
  // 关键：必须与云端套餐编辑页展示的「已勾选 API」一致，避免手机端出现「多出的 API」
  // 不再提供 getDefaultApiPolicies() 硬编码兜底——9 个具体旧模型（qwen-asr-realtime 等）与云端不同源，
  // 无订阅/无 plan 时直接返回空数组，让客户端展示「暂无 API 配置」
  private pickApiPolicies(plan: any): any[] {
    const allowedModels = Array.isArray(plan?.allowedModels) ? plan.allowedModels : [];
    // 最高优先级：云端 admin 在「可用 API」勾选的列表（与编辑页 UI 一致）
    if (allowedModels.length > 0) {
      return this.deriveApiPoliciesFromPlan(plan);
    }
    // 第二优先级：套餐只配置了 apiPolicies（没有 allowedModels）时，直接用它
    if (Array.isArray(plan?.apiPolicies) && plan.apiPolicies.length > 0) {
      return plan.apiPolicies
        .filter((p: any) => p && p.isAllowed !== false)
        .map((p: any) => ({
          provider: String(p.provider || ''),
          model: p.model ? String(p.model) : (p.modelPattern ? String(p.modelPattern).split(':').pop() : ''),
          modelPattern: p.modelPattern ? String(p.modelPattern) : (p.model ? String(p.model) : ''),
          multiplier: typeof p.multiplier === 'number' ? p.multiplier : Number(p.multiplier || 1),
          isAllowed: p.isAllowed !== false,
        }));
    }
    // 都为空：返回空数组（与无订阅行为保持一致，避免展示云端不存在的旧模型）
    return [];
  }

  // 将套餐的 defaultConfigs Record 转成 defaultConfigs 数组
  // 入参：{ textAnalysis: 'qwen-max', ... }
  // 出参：[{ functionType: 'textAnalysis', modelPattern: 'provider:model' }, ...]
  // 关键：modelPattern 必须带 provider 前缀，APK 端 syncCloudDefaults 按 ':' 解析
  private buildDefaultConfigsArray(
    defaultConfigs: Record<string, string> | undefined | null,
    apiPolicies: any[] = [],
  ) {
    if (!defaultConfigs || typeof defaultConfigs !== 'object') return [];
    // 建立 model -> provider 索引，用于补全 provider 前缀
    const providerByModel = new Map<string, string>();
    for (const p of apiPolicies) {
      const model = p?.model || p?.modelPattern;
      if (model) {
        providerByModel.set(String(model), String(p.provider || 'alibabaQwen'));
      }
    }
    return Object.entries(defaultConfigs)
      .filter(([k, v]) => !!k && !!v)
      .map(([functionType, modelValue]) => {
        // modelValue 可能已有 provider 前缀，也可能只是 model 名称
        const modelPattern = modelValue.includes(':')
          ? modelValue
          : `${providerByModel.get(modelValue) || 'alibabaQwen'}:${modelValue}`;
        return { functionType, modelPattern };
      });
  }

  // 从 allowedModels + apiPolicies 派生最终 API 列表
  // 关键：allowedModels 是云端 admin 在「可用 API」勾选的权威列表，必须与之一致
  // multiplier/provider 从 apiPolicies 中查（admin 在套餐编辑页配置的）
  // 这样既能保证手机端和云端展示一致，又保留了 admin 设置的 multiplier
  private deriveApiPoliciesFromPlan(plan: any) {
    const allowedModels = Array.isArray(plan?.allowedModels) ? plan.allowedModels : [];
    const apiPolicies = Array.isArray(plan?.apiPolicies) ? plan.apiPolicies : [];
    // 按 model 索引 apiPolicies，便于查找 multiplier/provider
    const policyByModel = new Map<string, any>();
    for (const p of apiPolicies) {
      const key = p?.model || p?.modelPattern;
      if (key) policyByModel.set(String(key), p);
    }
    return allowedModels.map((m: string) => {
      const found = policyByModel.get(String(m));
      return {
        provider: found?.provider ? String(found.provider) : 'alibabaQwen',
        model: String(m),
        modelPattern: found?.modelPattern ? String(found.modelPattern) : String(m),
        multiplier: typeof found?.multiplier === 'number' ? found.multiplier : 1.0,
        isAllowed: found?.isAllowed !== false,
      };
    });
  }

  // 提取套餐分配的 API（保留单一定义，避免编译错误）
  // 注：完整定义在文件顶部（第 33 行），此处为空以确保 TypeScript 不报 duplicate

  async getSubscription(userId: string) {
    // 查询该用户的所有 active 订阅，按到期时间倒序
    const subscriptions = await this.subscriptionRepository.find({
      where: { userId, status: 'active' },
      order: { expiresAt: 'DESC' },
    });

    const tokenBalance = await this.userTokenBalanceRepository.findOne({
      where: { userId },
    });

    if (subscriptions.length === 0) {
      // 免费版：无订阅，无云端 API 配置可展示
      return {
        code: 200,
        message: 'success',
        data: {
          planId: 'free',
          planName: '免费版',
          status: 'active',
          expiresAt: null,
          tokenQuota: 0,
          usedTokens: 0,
          balanceTokens: tokenBalance?.balanceTokens || 0,
          freeTokensRemaining: tokenBalance?.freeTokensRemaining || 500,
          // 修复 Issue 3：无订阅时不展示硬编码的 9 个旧模型，与云端不一致
          apiPolicies: [],
          defaultConfigs: this.buildDefaultConfigsArray({}),
          // 新增：多订阅列表
          subscriptions: [],
        },
      };
    }

    // 兼容旧版：返回单套餐的简化结构
    const activeSub = subscriptions[0];
    const plan = await this.planRepository.findOne({ where: { id: activeSub.planId } });
    const planData = plan ? this.normalizePlan(plan) : null;

    // 汇总所有 active 订阅的默认配置 + apiPolicies（用于多套餐场景）
    const allSubscriptions: any[] = [];
    for (const sub of subscriptions) {
      const subPlan = await this.planRepository.findOne({ where: { id: sub.planId } });
      if (!subPlan) continue;
      const subPlanData = this.normalizePlan(subPlan);
      allSubscriptions.push({
        subscriptionId: sub.id,
        planId: sub.planId,
        planName: subPlanData.name,
        // 修复 Issue 1：实时按当前 plan.durationDays 重新计算 expiresAt
        // 避免 admin 修改 durationDays 后，已订阅用户的过期时间不更新
        expiresAt: this.computeExpiresAt(sub.startedAt, subPlanData.durationDays, sub.expiresAt),
        startedAt: sub.startedAt,
        status: sub.status,
        defaultConfigs: this.buildDefaultConfigsArray(subPlanData.defaultConfigs, subPlanData.apiPolicies),
        apiPolicies: this.pickApiPolicies(subPlanData),
        allowedModels: subPlanData.allowedModels || [],
      });
    }

    return {
      code: 200,
      message: 'success',
      data: {
        // 单套餐视图（兼容老逻辑）
        planId: activeSub.planId,
        planName: planData?.name || '未知套餐',
        status: activeSub.status,
        // 修复 Issue 1：实时按当前 plan.durationDays 重新计算 expiresAt
        expiresAt: this.computeExpiresAt(activeSub.startedAt, planData?.durationDays, activeSub.expiresAt),
        totalQuota: activeSub.totalQuota,
        usedQuota: activeSub.usedQuota,
        balanceTokens: tokenBalance?.balanceTokens || 0,
        freeTokensRemaining: tokenBalance?.freeTokensRemaining || 0,
        // 从套餐读 defaultConfigs + apiPolicies
        // 修复 Issue 3：planData 缺失时不再回退到 getDefaultApiPolicies()，与无订阅行为保持一致
        apiPolicies: planData ? this.pickApiPolicies(planData) : [],
        defaultConfigs: planData ? this.buildDefaultConfigsArray(planData.defaultConfigs, planData.apiPolicies) : [],
        // 新增：多套餐列表
        subscriptions: allSubscriptions,
      },
    };
  }

  /**
   * 修复 Issue 1：实时计算 expiresAt
   * 优先按 plan.durationDays 重新计算（响应 admin 修改套餐时长后立即生效）
   * 若 plan 没传（plan 已被删除），回退到原订阅记录里的 expiresAt
   */
  private computeExpiresAt(startedAt: Date, planDurationDays: number | undefined, fallback: Date): Date {
    if (!startedAt || !planDurationDays || planDurationDays <= 0) {
      return fallback;
    }
    return new Date(new Date(startedAt).getTime() + planDurationDays * 24 * 60 * 60 * 1000);
  }

  // 规范 plan 数据（与 PlanService 行为一致）
  private normalizePlan(plan: any) {
    return {
      ...plan,
      allowedModels: plan.allowedModels
        ? String(plan.allowedModels).split(',').map((s: string) => s.trim()).filter(Boolean)
        : [],
      defaultConfigs: plan.defaultConfigs || {},
      apiPolicies: Array.isArray(plan.apiPolicies) ? plan.apiPolicies : [],
    };
  }

  // 获取指定 subscriptionId 的套餐详情（用于多套餐切换）
  async getSubscriptionById(userId: string, subscriptionId: string) {
    const subscription = await this.subscriptionRepository.findOne({
      where: { id: subscriptionId, userId, status: 'active' },
    });
    if (!subscription) {
      return {
        code: 404,
        message: '订阅不存在或已过期',
        data: null,
      };
    }

    const plan = await this.planRepository.findOne({ where: { id: subscription.planId } });
    const planData = plan ? this.normalizePlan(plan) : null;

    const tokenBalance = await this.userTokenBalanceRepository.findOne({ where: { userId } });

    return {
      code: 200,
      message: 'success',
      data: {
        subscriptionId: subscription.id,
        planId: subscription.planId,
        planName: planData?.name || '未知套餐',
        status: subscription.status,
        // 修复 Issue 1：实时按当前 plan.durationDays 重新计算 expiresAt
        expiresAt: this.computeExpiresAt(subscription.startedAt, planData?.durationDays, subscription.expiresAt),
        totalQuota: subscription.totalQuota,
        usedQuota: subscription.usedQuota,
        balanceTokens: tokenBalance?.balanceTokens || 0,
        freeTokensRemaining: tokenBalance?.freeTokensRemaining || 0,
        // 修复 Issue 3：planData 缺失时不再回退到 getDefaultApiPolicies()，与无订阅行为保持一致
        apiPolicies: planData ? this.pickApiPolicies(planData) : [],
        defaultConfigs: planData ? this.buildDefaultConfigsArray(planData.defaultConfigs, planData.apiPolicies) : [],
        allowedModels: planData?.allowedModels || [],
      },
    };
  }

  async getPlans(type?: string) {
    const plans = await this.planService.getPlans(false);
    return {
      code: 200,
      message: 'success',
      data: plans,
    };
  }

  async createSubscription(userId: string, planId: string) {
    const plan = await this.planRepository.findOne({
      where: { id: planId },
    });

    if (!plan) {
      return {
        code: 400,
        message: '套餐不存在',
        data: null,
      };
    }

    const now = new Date();
    const expiresAt = new Date(now.getTime() + plan.durationDays * 24 * 60 * 60 * 1000);

    // 过期现有订阅
    await this.subscriptionRepository.update(
      { userId, status: 'active' },
      { status: 'expired' },
    );

    // 修复 schema mismatch: Subscription 实体字段名调整（tokenQuota→totalQuota, usedTokens→usedQuota, 移除 balanceTokens）
    const subscription = this.subscriptionRepository.create({
      userId,
      planId,
      status: 'active',
      startedAt: now,
      expiresAt,
      totalQuota: plan.tokenQuota || 0,
      usedQuota: 0,
      type: plan.type || 'monthly',
    });

    await this.subscriptionRepository.save(subscription);

    // 如果是月度套餐，将Token配额充值到用户余额
    if (plan.type === 'monthly' && plan.tokenQuota) {
      let balance = await this.userTokenBalanceRepository.findOne({ where: { userId } });
      if (!balance) {
        balance = this.userTokenBalanceRepository.create({
          userId,
          totalTokens: plan.tokenQuota,
          usedTokens: 0,
          balanceTokens: plan.tokenQuota,
          freeTokensRemaining: 500,
        });
      } else {
        balance.totalTokens += plan.tokenQuota;
        balance.balanceTokens += plan.tokenQuota;
      }
      await this.userTokenBalanceRepository.save(balance);
    }

    return {
      code: 200,
      message: '订阅创建成功',
      data: subscription,
    };
  }

  async createPlan(dto: CreatePlanDto) {
    const existingPlan = await this.planService.getPlanById(dto.id);

    if (existingPlan) {
      return {
        code: 400,
        message: '套餐ID已存在',
        data: null,
      };
    }

    const plan = await this.planService.createPlan({
      id: dto.id,
      name: dto.name,
      description: dto.description,
      priceCents: dto.priceCents,
      tokenQuota: dto.tokenQuota,
      durationDays: dto.durationDays,
      type: dto.type || 'monthly',
      isActive: dto.isActive ?? true,
      allowedModels: Array.isArray(dto.allowedModels)
        ? dto.allowedModels.filter((m: string) => m).join(',')
        : (dto.allowedModels || ''),
    });

    return {
      code: 200,
      message: '套餐创建成功',
      data: plan,
    };
  }

  // 充值Token（金额按Token单价换算）
  async rechargeTokens(userId: string, dto: RechargeDto) {
    // 查询全局Token单价（元/Token）
    const globalPricePerToken = 0.01; // 默认1分钱/Token，后续可从配置读取
    const tokens = Math.floor(dto.amountCents / 100 / globalPricePerToken);

    let balance = await this.userTokenBalanceRepository.findOne({ where: { userId } });
    if (!balance) {
      balance = this.userTokenBalanceRepository.create({
        userId,
        totalTokens: tokens,
        usedTokens: 0,
        balanceTokens: tokens,
        freeTokensRemaining: 500,
      });
    } else {
      balance.totalTokens += tokens;
      balance.balanceTokens += tokens;
    }
    await this.userTokenBalanceRepository.save(balance);

    // 创建充值记录
    const record = this.rechargeRecordRepository.create({
      userId,
      amountCents: dto.amountCents,
      type: 'recharge',
      paymentMethod: dto.paymentMethod,
      status: 'completed',
    });
    await this.rechargeRecordRepository.save(record);

    return {
      code: 200,
      message: '充值成功',
      data: {
        tokensAdded: tokens,
        balanceTokens: balance.balanceTokens,
        amountCents: dto.amountCents,
      },
    };
  }

  // 获取用户Token余额
  async getBalance(userId: string) {
    // 使用 tokenBillingService.getOrCreateBalance 确保新用户自动获得免费额度
    const balance = await this.tokenBillingService.getOrCreateBalance(userId);

    return {
      code: 200,
      message: 'success',
      data: {
        balanceTokens: balance.balanceTokens,
        freeTokensRemaining: balance.freeTokensRemaining,
        totalTokens: balance.totalTokens,
        usedTokens: balance.usedTokens,
      },
    };
  }

  // 获取充值记录
  async getRechargeRecords(userId: string) {
    const records = await this.rechargeRecordRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });

    return {
      code: 200,
      message: 'success',
      data: records,
    };
  }

  // 创建体验订阅
  async createTrialSubscription(userId: string, trialData: {
    planId: string;
    planName: string;
    totalQuota: number;
    usedQuota: number;
    expiresAt: Date;
  }) {
    let trialPlan = await this.planRepository.findOne({ where: { id: trialData.planId } });
    if (!trialPlan) {
      trialPlan = this.planRepository.create({
        id: trialData.planId,
        name: trialData.planName,
        description: '新用户注册赠送',
        priceCents: 0,
        durationDays: 7,
        tokenQuota: trialData.totalQuota,
        type: 'monthly',
        isActive: true,
      });
      await this.planRepository.save(trialPlan);
    }

    // 修复 schema mismatch: Subscription 实体字段名调整（tokenQuota→totalQuota, usedTokens→usedQuota, 移除 balanceTokens）
    const subscription = this.subscriptionRepository.create({
      userId,
      planId: trialData.planId,
      status: 'active',
      startedAt: new Date(),
      expiresAt: trialData.expiresAt,
      totalQuota: trialData.totalQuota,
      usedQuota: trialData.usedQuota,
      type: 'monthly',
    });

    await this.subscriptionRepository.save(subscription);
    return subscription;
  }
}
