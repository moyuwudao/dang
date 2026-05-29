import { Repository } from 'typeorm';
import { BillingStrategy, ConsumeResult } from '../interfaces/billing-strategy.interface';
import { UserBalance } from '../../entities/user-balance.entity';
import { TokenPricing } from '../../entities/token-pricing.entity';
import { ApiUsageLog } from '../../entities/api-usage-log.entity';
export declare class PayAsYouGoBillingStrategy implements BillingStrategy {
    private balanceRepo;
    private pricingRepo;
    private usageLogRepo;
    constructor(balanceRepo: Repository<UserBalance>, pricingRepo: Repository<TokenPricing>, usageLogRepo: Repository<ApiUsageLog>);
    canUse(userId: string, featureType: string, amount: number): Promise<boolean>;
    consume(userId: string, featureType: string, amount: number, metadata?: any): Promise<ConsumeResult>;
    getRemaining(userId: string): Promise<number>;
    private calculateCost;
    private calculateTokenCost;
}
