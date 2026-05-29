import { Repository } from 'typeorm';
import { BillingStrategy, ConsumeResult } from '../interfaces/billing-strategy.interface';
import { Subscription } from '../../entities/subscription.entity';
import { UserFeatureUsage } from '../../entities/user-feature-usage.entity';
import { PlanFeatureQuota } from '../../entities/plan-feature-quota.entity';
export declare class SubscriptionBillingStrategy implements BillingStrategy {
    private subscriptionRepo;
    private featureUsageRepo;
    private planFeatureQuotaRepo;
    constructor(subscriptionRepo: Repository<Subscription>, featureUsageRepo: Repository<UserFeatureUsage>, planFeatureQuotaRepo: Repository<PlanFeatureQuota>);
    canUse(userId: string, featureType: string, amount: number): Promise<boolean>;
    consume(userId: string, featureType: string, amount: number): Promise<ConsumeResult>;
    getRemaining(userId: string, featureType: string): Promise<number>;
    private getActiveSubscription;
    private getFeatureQuota;
    private getFeatureUsage;
}
