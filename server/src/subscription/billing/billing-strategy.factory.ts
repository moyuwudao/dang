import { Injectable } from '@nestjs/common';
import { BillingStrategy } from './interfaces/billing-strategy.interface';
import { SubscriptionBillingStrategy } from './strategies/subscription-billing.strategy';
import { PackageBillingStrategy } from './strategies/package-billing.strategy';
import { PayAsYouGoBillingStrategy } from './strategies/pay-as-you-go-billing.strategy';

@Injectable()
export class BillingStrategyFactory {
  constructor(
    private subscriptionStrategy: SubscriptionBillingStrategy,
    private packageStrategy: PackageBillingStrategy,
    private payAsYouGoStrategy: PayAsYouGoBillingStrategy,
  ) {}

  async getStrategy(userId: string, featureType: string): Promise<BillingStrategy> {
    // 优先级：订阅制 > 资源包 > 按量付费
    
    if (await this.subscriptionStrategy.canUse(userId, featureType, 0)) {
      return this.subscriptionStrategy;
    }

    if (await this.packageStrategy.canUse(userId, featureType, 0)) {
      return this.packageStrategy;
    }

    return this.payAsYouGoStrategy;
  }
}
