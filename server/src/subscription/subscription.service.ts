import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Subscription } from './entities/subscription.entity';
import { Plan } from './entities/plan.entity';
import { UserBalance } from './entities/user-balance.entity';
import { RechargeRecord } from './entities/recharge-record.entity';
import { PlanApiPolicy } from './entities/plan-api-policy.entity';
import { ApiUsageLog } from './entities/api-usage-log.entity';
import { CreatePlanDto, RechargeDto, RefundDto } from './dto';

@Injectable()
export class SubscriptionService {
  constructor(
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
    @InjectRepository(Plan)
    private planRepository: Repository<Plan>,
    @InjectRepository(UserBalance)
    private userBalanceRepository: Repository<UserBalance>,
    @InjectRepository(RechargeRecord)
    private rechargeRecordRepository: Repository<RechargeRecord>,
    @InjectRepository(PlanApiPolicy)
    private planApiPolicyRepository: Repository<PlanApiPolicy>,
    @InjectRepository(ApiUsageLog)
    private apiUsageLogRepository: Repository<ApiUsageLog>,
  ) {}

  async getSubscription(userId: string) {
    const subscription = await this.subscriptionRepository.findOne({
      where: { userId, status: 'active' },
      order: { expiresAt: 'DESC' },
    });

    const userBalance = await this.userBalanceRepository.findOne({
      where: { userId },
    });

    if (!subscription) {
      return {
        code: 200,
        message: 'success',
        data: {
          planId: 'free',
          planName: '免费版',
          status: 'active',
          expiresAt: null,
          totalQuota: 30,
          usedQuota: 0,
          remainingQuota: 30,
          balanceCents: userBalance?.balanceCents || 0,
        },
      };
    }

    const plan = await this.planRepository.findOne({
      where: { id: subscription.planId },
    });

    const remainingQuota = subscription.totalQuota - subscription.usedQuota;

    // 获取套餐的API策略
    const apiPolicies = await this.planApiPolicyRepository.find({
      where: { planId: subscription.planId },
    });

    return {
      code: 200,
      message: 'success',
      data: {
        planId: subscription.planId,
        planName: plan?.name || '未知套餐',
        status: subscription.status,
        expiresAt: subscription.expiresAt,
        totalQuota: subscription.totalQuota,
        usedQuota: subscription.usedQuota,
        remainingQuota: Math.max(0, remainingQuota),
        balanceCents: userBalance?.balanceCents || 0,
        apiPolicies: apiPolicies.map(p => ({
          provider: p.provider,
          modelPattern: p.modelPattern,
          multiplier: p.multiplier,
          isAllowed: p.isAllowed,
        })),
      },
    };
  }

  async getPlans(type?: string) {
    const where: any = { isActive: true };
    // 注意：plans 表目前没有 type 列，暂不使用 type 过滤
    // if (type) {
    //   where.type = type;
    // }

    const plans = await this.planRepository.find({ where });

    // 为每个套餐获取API策略中的模型列表
    const plansWithModels = await Promise.all(
      plans.map(async (plan) => {
        const policies = await this.planApiPolicyRepository.find({
          where: { planId: plan.id },
        });
        const allowedModels = policies
          .filter(p => p.modelPattern && p.modelPattern !== '*')
          .map(p => p.modelPattern);
        return {
          ...plan,
          allowedModels: Array.from(new Set(allowedModels)),
        };
      }),
    );

    return {
      code: 200,
      message: 'success',
      data: plansWithModels,
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

    // 检查余额是否足够
    const userBalance = await this.userBalanceRepository.findOne({
      where: { userId },
    });

    if (userBalance && userBalance.balanceCents >= plan.priceCents) {
      // 使用余额支付
      userBalance.balanceCents -= plan.priceCents;
      await this.userBalanceRepository.save(userBalance);
    }

    const now = new Date();
    const expiresAt = new Date(now.getTime() + plan.durationDays * 24 * 60 * 60 * 1000);

    await this.subscriptionRepository.update(
      { userId, status: 'active' },
      { status: 'expired' },
    );

    const subscription = this.subscriptionRepository.create({
      userId,
      planId,
      status: 'active',
      startedAt: now,
      expiresAt,
      totalQuota: plan.quotaValue || 0,
      usedQuota: 0,
    });

    await this.subscriptionRepository.save(subscription);

    return {
      code: 200,
      message: '订阅创建成功',
      data: subscription,
    };
  }

  async createPlan(dto: CreatePlanDto) {
    const existingPlan = await this.planRepository.findOne({
      where: { id: dto.id },
    });

    if (existingPlan) {
      return {
        code: 400,
        message: '套餐ID已存在',
        data: null,
      };
    }

    const plan = this.planRepository.create({
      id: dto.id,
      name: dto.name,
      description: dto.description,
      priceCents: dto.priceCents,
      durationDays: dto.durationDays,
      // type: dto.type || 'subscription', // 暂时注释，数据库无此列
      features: dto.features || [],
      isRecommended: dto.isRecommended || false,
      quotaType: dto.quotaType,
      quotaValue: dto.quotaValue,
      isActive: dto.isActive ?? true,
      allowedModels: dto.allowedModels || [],
    });

    await this.planRepository.save(plan);

    return {
      code: 200,
      message: '套餐创建成功',
      data: plan,
    };
  }

  async useQuota(userId: string, amount: number) {
    const subscription = await this.subscriptionRepository.findOne({
      where: { userId, status: 'active' },
    });

    if (!subscription) {
      const defaultQuota = 30;
      if (amount > defaultQuota) {
        throw new BadRequestException('配额不足');
      }
      return {
        code: 200,
        message: 'success',
        data: {
          planId: 'free',
          usedQuota: amount,
          remainingQuota: defaultQuota - amount,
        },
      };
    }

    const remainingQuota = subscription.totalQuota - subscription.usedQuota;
    if (remainingQuota < amount) {
      throw new BadRequestException('配额不足');
    }

    subscription.usedQuota += amount;
    await this.subscriptionRepository.save(subscription);
  }

  async updateQuotaUsage(userId: string, amount: number) {
    const subscription = await this.subscriptionRepository.findOne({
      where: { userId, status: 'active' },
    });

    if (!subscription) {
      throw new BadRequestException('无有效订阅');
    }

    const remainingQuota = subscription.totalQuota - subscription.usedQuota;
    if (remainingQuota < amount) {
      throw new BadRequestException('配额不足');
    }

    subscription.usedQuota += amount;
    await this.subscriptionRepository.save(subscription);

    return {
      code: 200,
      message: 'success',
      data: {
        usedQuota: subscription.usedQuota,
        remainingQuota: subscription.totalQuota - subscription.usedQuota,
      },
    };

    return {
      code: 200,
      message: '配额使用成功',
      data: {
        planId: subscription.planId,
        usedQuota: subscription.usedQuota,
        remainingQuota: subscription.totalQuota - subscription.usedQuota,
      },
    };
  }

  // 余额相关方法
  async getBalance(userId: string) {
    const userBalance = await this.userBalanceRepository.findOne({
      where: { userId },
    });

    return {
      code: 200,
      message: 'success',
      data: {
        balanceCents: userBalance?.balanceCents || 0,
        totalRechargedCents: userBalance?.totalRechargedCents || 0,
        totalRefundedCents: userBalance?.totalRefundedCents || 0,
      },
    };
  }

  async recharge(userId: string, dto: RechargeDto) {
    let userBalance = await this.userBalanceRepository.findOne({
      where: { userId },
    });

    if (!userBalance) {
      userBalance = this.userBalanceRepository.create({
        userId,
        balanceCents: 0,
        totalRechargedCents: 0,
        totalRefundedCents: 0,
      });
    }

    userBalance.balanceCents += dto.amountCents;
    userBalance.totalRechargedCents += dto.amountCents;
    await this.userBalanceRepository.save(userBalance);

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
        balanceCents: userBalance.balanceCents,
        amountCents: dto.amountCents,
      },
    };
  }

  async refund(userId: string, dto: RefundDto) {
    const userBalance = await this.userBalanceRepository.findOne({
      where: { userId },
    });

    if (!userBalance || userBalance.balanceCents < dto.amountCents) {
      throw new BadRequestException('余额不足，无法退款');
    }

    userBalance.balanceCents -= dto.amountCents;
    userBalance.totalRefundedCents += dto.amountCents;
    await this.userBalanceRepository.save(userBalance);

    // 创建退款记录
    const record = this.rechargeRecordRepository.create({
      userId,
      amountCents: dto.amountCents,
      type: 'refund',
      status: 'completed',
      remark: dto.reason,
    });
    await this.rechargeRecordRepository.save(record);

    return {
      code: 200,
      message: '退款成功',
      data: {
        balanceCents: userBalance.balanceCents,
        amountCents: dto.amountCents,
      },
    };
  }

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
    // 确保 plans 表中存在 trial 记录，避免外键约束失败
    let trialPlan = await this.planRepository.findOne({ where: { id: trialData.planId } });
    if (!trialPlan) {
      trialPlan = this.planRepository.create({
        id: trialData.planId,
        name: trialData.planName,
        description: '新用户注册赠送',
        priceCents: 0,
        durationDays: 7,
        quotaType: 'minutes',
        quotaValue: trialData.totalQuota,
        isActive: true,
      });
      await this.planRepository.save(trialPlan);
    }

    const subscription = this.subscriptionRepository.create({
      userId,
      planId: trialData.planId,
      status: 'active',
      startedAt: new Date(),
      expiresAt: trialData.expiresAt,
      totalQuota: trialData.totalQuota,
      usedQuota: trialData.usedQuota,
    });

    await this.subscriptionRepository.save(subscription);

    return subscription;
  }

  // 初始化用户余额
  async initUserBalance(userId: string) {
    const existing = await this.userBalanceRepository.findOne({
      where: { userId },
    });

    if (!existing) {
      const userBalance = this.userBalanceRepository.create({
        userId,
        balanceCents: 0,
        totalRechargedCents: 0,
        totalRefundedCents: 0,
      });
      await this.userBalanceRepository.save(userBalance);
    }
  }

  // 获取套餐的API策略
  async getPlanApiPolicies(planId: string) {
    return this.planApiPolicyRepository.find({
      where: { planId },
    });
  }

  // 创建或更新套餐API策略
  async setPlanApiPolicy(planId: string, provider: string, multiplier: number, modelPattern?: string) {
    // 使用 planId + provider + modelPattern 作为唯一键，支持同一provider多个模型
    const searchPattern = modelPattern || '*';
    let policy = await this.planApiPolicyRepository.findOne({
      where: { planId, provider, modelPattern: searchPattern },
    });

    if (policy) {
      policy.multiplier = multiplier;
    } else {
      policy = this.planApiPolicyRepository.create({
        planId,
        provider,
        multiplier,
        modelPattern: searchPattern,
        isAllowed: true,
      });
    }

    return this.planApiPolicyRepository.save(policy);
  }

  async deletePlanApiPolicy(policyId: string) {
    await this.planApiPolicyRepository.delete(policyId);
  }

  // 计算API调用应消耗的配额
  async calculateQuotaConsumption(userId: string, provider: string, model: string): Promise<number> {
    const subscription = await this.subscriptionRepository.findOne({
      where: { userId, status: 'active' },
      order: { expiresAt: 'DESC' },
    });

    if (!subscription) {
      return 1; // 免费用户默认消耗1单位
    }

    const policies = await this.planApiPolicyRepository.find({
      where: { planId: subscription.planId },
    });

    // 查找匹配的策略
    const policy = policies.find(p => {
      if (p.provider !== provider && p.provider !== 'all') return false;
      if (!p.modelPattern) return true;
      // 简单的通配符匹配
      const pattern = p.modelPattern.replace('*', '.*');
      const regex = new RegExp(`^${pattern}$`);
      return regex.test(model);
    });

    return policy ? policy.multiplier : 1;
  }

  // 使用配额（带API差异化计算）
  async consumeQuotaWithApi(userId: string, provider: string, model: string, tokens?: { prompt: number; completion: number }) {
    const multiplier = await this.calculateQuotaConsumption(userId, provider, model);
    const consumed = Math.ceil(multiplier);

    // 记录使用日志
    const subscription = await this.subscriptionRepository.findOne({
      where: { userId, status: 'active' },
      order: { expiresAt: 'DESC' },
    });

    const log = this.apiUsageLogRepository.create({
      userId,
      subscriptionId: subscription?.id,
      provider,
      model,
      promptTokens: tokens?.prompt || 0,
      completionTokens: tokens?.completion || 0,
      quotaConsumed: consumed,
    });
    await this.apiUsageLogRepository.save(log);

    // 更新订阅配额
    if (subscription) {
      subscription.usedQuota += consumed;
      subscription.balanceQuota = Math.max(0, subscription.totalQuota - subscription.usedQuota);
      await this.subscriptionRepository.save(subscription);
    }

    return {
      consumed,
      multiplier,
      remaining: subscription ? subscription.balanceQuota : 0,
    };
  }

  // 检查用户是否有权限使用特定API
  async canUseApi(userId: string, provider: string, model: string): Promise<{ allowed: boolean; reason?: string }> {
    const subscription = await this.subscriptionRepository.findOne({
      where: { userId, status: 'active' },
      order: { expiresAt: 'DESC' },
    });

    if (!subscription) {
      // 免费用户只允许使用国产API
      const domesticProviders = ['qwen', 'deepseek'];
      if (!domesticProviders.includes(provider)) {
        return { allowed: false, reason: '免费用户仅可使用国产API，请升级套餐' };
      }
      return { allowed: true };
    }

    // 检查套餐是否过期
    if (new Date() > subscription.expiresAt) {
      return { allowed: false, reason: '套餐已过期，请续费' };
    }

    // 检查配额
    if (subscription.balanceQuota <= 0) {
      return { allowed: false, reason: '配额已用完，请充值或升级套餐' };
    }

    // 检查API策略
    const policies = await this.planApiPolicyRepository.find({
      where: { planId: subscription.planId },
    });

    if (policies.length === 0) {
      return { allowed: true }; // 没有策略限制，允许使用
    }

    const allowed = policies.some(p => {
      if (p.provider === 'all') return true;
      if (p.provider !== provider) return false;
      if (!p.modelPattern) return p.isAllowed;
      const pattern = p.modelPattern.replace('*', '.*');
      const regex = new RegExp(`^${pattern}$`);
      return regex.test(model) && p.isAllowed;
    });

    if (!allowed) {
      return { allowed: false, reason: '当前套餐不支持使用该API，请升级套餐' };
    }

    return { allowed: true };
  }
}
