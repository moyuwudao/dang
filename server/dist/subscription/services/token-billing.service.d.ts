import { Repository } from 'typeorm';
import { ApiConfig } from '../entities/api-config.entity';
import { TokenPricing } from '../entities/token-pricing.entity';
import { UserTokenBalance } from '../entities/user-token-balance.entity';
import { ApiUsageLog } from '../entities/api-usage-log.entity';
export interface ConsumeTokenResult {
    success: boolean;
    tokenConsumed: number;
    costYuan: number;
    balanceRemaining: number;
    freeTokensRemaining: number;
    message?: string;
}
export interface TokenUsageMetadata {
    provider: string;
    model: string;
    rawAmount: number;
    promptTokens?: number;
    completionTokens?: number;
}
export declare class TokenBillingService {
    private apiConfigRepo;
    private pricingRepo;
    private balanceRepo;
    private usageLogRepo;
    constructor(apiConfigRepo: Repository<ApiConfig>, pricingRepo: Repository<TokenPricing>, balanceRepo: Repository<UserTokenBalance>, usageLogRepo: Repository<ApiUsageLog>);
    consumeToken(userId: string, metadata: TokenUsageMetadata): Promise<ConsumeTokenResult>;
    getOrCreateBalance(userId: string): Promise<UserTokenBalance>;
    rechargeTokens(userId: string, tokens: number): Promise<UserTokenBalance>;
    getBalance(userId: string): Promise<{
        balanceTokens: number;
        freeTokensRemaining: number;
        totalTokens: number;
        usedTokens: number;
    }>;
    canUse(userId: string, estimatedTokens: number): Promise<boolean>;
    getUsageLogs(userId: string, limit?: number): Promise<ApiUsageLog[]>;
}
