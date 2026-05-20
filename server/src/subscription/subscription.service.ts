import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Subscription } from './entities/subscription.entity';
import { Plan } from './entities/plan.entity';

@Injectable()
export class SubscriptionService {
  constructor(
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
    @InjectRepository(Plan)
    private planRepository: Repository<Plan>,
  ) {}

  async getSubscription(userId: string) {
    const subscription = await this.subscriptionRepository.findOne({
      where: { userId, status: 'active' },
      order: { expiresAt: 'DESC' },
    });

    if (!subscription) {
      // 返回免费版默认状态
      return {
        code: 200,
        message: 'success',
        data: {
          planId: 'free',
          status: 'active',
          expiresAt: null,
          totalQuota: 30,
          usedQuota: 0,
          remainingQuota: 30,
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
      },
    };
  }

  async getPlans() {
    const plans = await this.planRepository.find({
      where: { isActive: true },
    });

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
}
