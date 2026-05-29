import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BillingStrategy, ConsumeResult } from '../interfaces/billing-strategy.interface';
import { Subscription } from '../../entities/subscription.entity';
import { UserFeatureUsage } from '../../entities/user-feature-usage.entity';
import { PlanFeatureQuota } from '../../entities/plan-feature-quota.entity';

@Injectable()
export class PackageBillingStrategy implements BillingStrategy {
  constructor(
    @InjectRepository(Subscription)
    private subscriptionRepo: Repository<Subscription>,
    @InjectRepository(UserFeatureUsage)
    private featureUsageRepo: Repository<UserFeatureUsage>,
    @InjectRepository(PlanFeatureQuota)
    private planFeatureQuotaRepo: Repository<PlanFeatureQuota>,
  ) {}

  async canUse(userId: string, featureType: string, amount: number): Promise<boolean> {
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

        if (usage.usedAmount >= usage.totalAmount) {
          pkg.status = 'expired';
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

  private async getActivePackages(userId: string): Promise<Subscription[]> {
    return this.subscriptionRepo.find({
      where: {
        userId,
        type: 'package',
        status: 'active',
      },
      order: { createdAt: 'ASC' },
    });
  }

  private async getFeatureUsage(userId: string, subscriptionId: string, featureType: string): Promise<UserFeatureUsage | null> {
    let usage = await this.featureUsageRepo.findOne({
      where: { userId, subscriptionId, featureType },
    });

    if (!usage) {
      const subscription = await this.subscriptionRepo.findOne({ where: { id: subscriptionId } });
      if (!subscription) return null;

      const quota = await this.planFeatureQuotaRepo.findOne({
        where: { planId: subscription.planId, featureType },
      });
      
      if (!quota) return null;
      
      usage = this.featureUsageRepo.create({
        userId,
        subscriptionId,
        featureType,
        usedAmount: 0,
        totalAmount: quota.quotaValue,
        unit: quota.quotaUnit,
      });
      await this.featureUsageRepo.save(usage);
    }

    return usage;
  }
}
