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

  async getSubscription(userId: string) {
    const subscription = await this.subscriptionRepository.findOne({
      where: { userId, status: 'active' },
      order: { expiresAt: 'DESC' },
    });

    const tokenBalance = await this.userTokenBalanceRepository.findOne({
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
          tokenQuota: 0,
          usedTokens: 0,
          balanceTokens: tokenBalance?.balanceTokens || 0,
          freeTokensRemaining: tokenBalance?.freeTokensRemaining || 500,
        },
      };
    }

    const plan = await this.planRepository.findOne({
      where: { id: subscription.planId },
    });

    return {
      code: 200,
      message: 'success',
      data: {
        planId: subscription.planId,
        planName: plan?.name || '未知套餐',
        status: subscription.status,
        expiresAt: subscription.expiresAt,
        tokenQuota: subscription.tokenQuota,
        usedTokens: subscription.usedTokens,
        balanceTokens: tokenBalance?.balanceTokens || 0,
        freeTokensRemaining: tokenBalance?.freeTokensRemaining || 0,
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

    const subscription = this.subscriptionRepository.create({
      userId,
      planId,
      status: 'active',
      startedAt: now,
      expiresAt,
      tokenQuota: plan.tokenQuota || 0,
      usedTokens: 0,
      balanceTokens: plan.tokenQuota || 0,
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
      allowedModels: dto.allowedModels || [],
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

    const subscription = this.subscriptionRepository.create({
      userId,
      planId: trialData.planId,
      status: 'active',
      startedAt: new Date(),
      expiresAt: trialData.expiresAt,
      tokenQuota: trialData.totalQuota,
      usedTokens: trialData.usedQuota,
      balanceTokens: trialData.totalQuota - trialData.usedQuota,
      type: 'monthly',
    });

    await this.subscriptionRepository.save(subscription);
    return subscription;
  }
}
