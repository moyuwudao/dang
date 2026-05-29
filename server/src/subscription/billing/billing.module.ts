import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BillingStrategyFactory } from './billing-strategy.factory';
import { SubscriptionBillingStrategy } from './strategies/subscription-billing.strategy';
import { PackageBillingStrategy } from './strategies/package-billing.strategy';
import { PayAsYouGoBillingStrategy } from './strategies/pay-as-you-go-billing.strategy';
import { Subscription } from '../entities/subscription.entity';
import { UserFeatureUsage } from '../entities/user-feature-usage.entity';
import { PlanFeatureQuota } from '../entities/plan-feature-quota.entity';
import { UserBalance } from '../entities/user-balance.entity';
import { TokenPricing } from '../entities/token-pricing.entity';
import { ApiUsageLog } from '../entities/api-usage-log.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Subscription,
      UserFeatureUsage,
      PlanFeatureQuota,
      UserBalance,
      TokenPricing,
      ApiUsageLog,
    ]),
  ],
  providers: [
    BillingStrategyFactory,
    SubscriptionBillingStrategy,
    PackageBillingStrategy,
    PayAsYouGoBillingStrategy,
  ],
  exports: [BillingStrategyFactory],
})
export class BillingModule {}
