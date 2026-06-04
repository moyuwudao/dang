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
  ) {}

  // 默认 API 策略（套餐未配置时使用，按 Token 计费模式下，所有登录用户都能用所有模型）
  // 注意：套餐已配置 apiPolicies 时优先用套餐配置
  private getDefaultApiPolicies() {
    return [
      // 实时语音转写
      { provider: 'alibabaQwen', modelPattern: 'qwen-asr-realtime', model: 'qwen-asr-realtime', multiplier: 1.0, isAllowed: true },
      { provider: 'alibabaQwen', modelPattern: 'qwen-asr-realtime-8k', model: 'qwen-asr-realtime-8k', multiplier: 1.0, isAllowed: true },
      { provider: 'alibabaQwen', modelPattern: 'qwen-asr-realtime-16k', model: 'qwen-asr-realtime-16k', multiplier: 1.2, isAllowed: true },
      // 文件转写
      { provider: 'alibabaQwen', modelPattern: 'qwen-asr', model: 'qwen-asr', multiplier: 1.0, isAllowed: true },
      { provider: 'alibabaQwen', modelPattern: 'paraformer-v2', model: 'paraformer-v2', multiplier: 1.0, isAllowed: true },
      // 文本分析（总结/翻译/思维导图）
      { provider: 'alibabaQwen', modelPattern: 'qwen-turbo', model: 'qwen-turbo', multiplier: 0.5, isAllowed: true },
      { provider: 'alibabaQwen', modelPattern: 'qwen-plus', model: 'qwen-plus', multiplier: 1.0, isAllowed: true },
      { provider: 'alibabaQwen', modelPattern: 'qwen-max', model: 'qwen-max', multiplier: 2.0, isAllowed: true },
      // 图像识别
      { provider: 'alibabaQwen', modelPattern: 'qwen-vl-plus', model: 'qwen-vl-plus', multiplier: 1.5, isAllowed: true },
    ];
  }

  // 将套餐的 defaultConfigs Record 转成 defaultConfigs 数组
  // 入参：{ textAnalysis: 'qwen-max', ... } → [{ functionType: 'textAnalysis', modelPattern: 'qwen-max' }, ...]
  private buildDefaultConfigsArray(defaultConfigs: Record<string, string> | undefined | null) {
    if (!defaultConfigs || typeof defaultConfigs !== 'object') return [];
    return Object.entries(defaultConfigs)
      .filter(([k, v]) => !!k && !!v)
      .map(([functionType, modelPattern]) => ({ functionType, modelPattern }));
  }

  // 提取套餐分配的 API（去重 + 仅 isAllowed）
  private pickApiPolicies(plan: any) {
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
    return this.getDefaultApiPolicies();
  }

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
      // 免费版
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
          apiPolicies: this.getDefaultApiPolicies(),
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
        expiresAt: sub.expiresAt,
        status: sub.status,
        defaultConfigs: this.buildDefaultConfigsArray(subPlanData.defaultConfigs),
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
        expiresAt: activeSub.expiresAt,
        totalQuota: activeSub.totalQuota,
        usedQuota: activeSub.usedQuota,
        balanceTokens: tokenBalance?.balanceTokens || 0,
        freeTokensRemaining: tokenBalance?.freeTokensRemaining || 0,
        // 从套餐读 defaultConfigs + apiPolicies
        apiPolicies: planData ? this.pickApiPolicies(planData) : this.getDefaultApiPolicies(),
        defaultConfigs: planData ? this.buildDefaultConfigsArray(planData.defaultConfigs) : [],
        // 新增：多套餐列表
        subscriptions: allSubscriptions,
      },
    };
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
        expiresAt: subscription.expiresAt,
        totalQuota: subscription.totalQuota,
        usedQuota: subscription.usedQuota,
        balanceTokens: tokenBalance?.balanceTokens || 0,
        freeTokensRemaining: tokenBalance?.freeTokensRemaining || 0,
        apiPolicies: planData ? this.pickApiPolicies(planData) : this.getDefaultApiPolicies(),
        defaultConfigs: planData ? this.buildDefaultConfigsArray(planData.defaultConfigs) : [],
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
    const tokenBalance = await this.userTokenBalanceRepository.findOne({
      where: { userId },
    });

    return {
      code: 200,
      message: 'success',
      data: {
        balanceTokens: tokenBalance?.balanceTokens || 0,
        freeTokensRemaining: tokenBalance?.freeTokensRemaining || 0,
        totalTokens: tokenBalance?.totalTokens || 0,
        usedTokens: tokenBalance?.usedTokens || 0,
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
