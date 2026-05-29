import { BillingStrategy } from './interfaces/billing-strategy.interface';
import { SubscriptionBillingStrategy } from './strategies/subscription-billing.strategy';
import { PackageBillingStrategy } from './strategies/package-billing.strategy';
import { PayAsYouGoBillingStrategy } from './strategies/pay-as-you-go-billing.strategy';
export declare class BillingStrategyFactory {
    private subscriptionStrategy;
    private packageStrategy;
    private payAsYouGoStrategy;
    constructor(subscriptionStrategy: SubscriptionBillingStrategy, packageStrategy: PackageBillingStrategy, payAsYouGoStrategy: PayAsYouGoBillingStrategy);
    getStrategy(userId: string, featureType: string): Promise<BillingStrategy>;
}
