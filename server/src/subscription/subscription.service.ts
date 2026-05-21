import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Subscription } from './entities/subscription.entity';
import { Plan } from './entities/plan.entity';
import { UserBalance } from './entities/user-balance.entity';
import { RechargeRecord } from './entities/recharge-record.entity';
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
}
