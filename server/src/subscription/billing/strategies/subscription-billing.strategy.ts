import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThan } from 'typeorm';
import { BillingStrategy, ConsumeResult } from '../interfaces/billing-strategy.interface';
import { Subscription } from '../../entities/subscription.entity';
import { UserFeatureUsage } from '../../entities/user-feature-usage.entity';
import { PlanFeatureQuota } from '../../entities/plan-feature-quota.entity';

@Injectable()
export class SubscriptionBillingStrategy implements BillingStrategy {
  constructor(
    @InjectRepository(Subscription)
    private subscriptionRepo: Repository<Subscription>,
    @InjectRepository(UserFeatureUsage)
    private featureUsageRepo: Repository<UserFeatureUsage>,
    @InjectRepository(PlanFeatureQuota)
    private planFeatureQuotaRepo: Repository<PlanFeatureQuota>,
  ) {}

  async canUse(userId: string, featureType: string, amount: number): Promise<boolean> {
    const subscription = await this.getActiveSubscription(userId);
    if (!subscription) return false;

    const featureQuota = await this.getFeatureQuota(subscription.planId, featureType);
    if (!featureQuota) return false;

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

  private async getActiveSubscription(userId: string): Promise<Subscription | null> {
    return this.subscriptionRepo.findOne({
      where: {
        userId,
        type: 'subscription',
        status: 'active',
        expiresAt: MoreThan(new Date()),
      },
      order: { expiresAt: 'DESC' },
    });
  }

  private async getFeatureQuota(planId: string, featureType: string): Promise<PlanFeatureQuota | null> {
    return this.planFeatureQuotaRepo.findOne({
      where: { planId, featureType },
    });
  }

  private async getFeatureUsage(userId: string, subscriptionId: string, featureType: string): Promise<UserFeatureUsage> {
    let usage = await this.featureUsageRepo.findOne({
      where: { userId, subscriptionId, featureType },
    });

    if (!usage) {
      const subscription = await this.subscriptionRepo.findOne({ where: { id: subscriptionId } });
      const quota = await this.getFeatureQuota(subscription.planId, featureType);
      
      usage = this.featureUsageRepo.create({
        userId,
        subscriptionId,
        featureType,
        usedAmount: 0,
        totalAmount: quota?.quotaValue || 0,
        unit: quota?.quotaUnit || 'minutes',
      });
      await this.featureUsageRepo.save(usage);
    }

    return usage;
  }
}
