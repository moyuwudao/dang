import { HttpService } from '@nestjs/axios';
import { Repository } from 'typeorm';
import { ApiKeyService } from '../api-key/api-key.service';
import { SubscriptionService } from '../subscription/subscription.service';
import { RedisService } from '../redis/redis.service';
import { TokenBillingService } from '../subscription/services/token-billing.service';
import { ApiUsageLog } from '../subscription/entities/api-usage-log.entity';
export declare class AiService {
    private readonly httpService;
    private readonly apiKeyService;
    private readonly subscriptionService;
    private readonly redisService;
    private readonly tokenBillingService;
    private apiUsageLogRepository;
    constructor(httpService: HttpService, apiKeyService: ApiKeyService, subscriptionService: SubscriptionService, redisService: RedisService, tokenBillingService: TokenBillingService, apiUsageLogRepository: Repository<ApiUsageLog>);
    chat(userId: string, params: {
        messages: Array<{
            role: string;
            content: string;
        }>;
        provider?: string;
        model?: string;
        stream?: boolean;
    }): Promise<{
        code: number;
        message: string;
        data: {
            content: any;
            model: any;
            provider: import("../api-key/entities/api-key.entity").ApiKeyProvider;
        };
        usage: {
            promptTokens: any;
            completionTokens: any;
            totalTokens: any;
            tokenConsumed: number;
            costYuan: number;
            balanceRemaining: number;
            freeTokensRemaining: number;
        };
    }>;
    transcribe(userId: string, params: {
        audioUrl: string;
        provider?: string;
        language?: string;
    }): Promise<{
        code: number;
        message: string;
        data: {
            content: any;
            model: any;
            provider: import("../api-key/entities/api-key.entity").ApiKeyProvider;
        };
        usage: {
            promptTokens: any;
            completionTokens: any;
            totalTokens: any;
            tokenConsumed: number;
            costYuan: number;
            balanceRemaining: number;
            freeTokensRemaining: number;
        };
    }>;
    getUsage(userId: string, startDate?: string, endDate?: string): Promise<{
        code: number;
        message: string;
        data: {
            totalCalls: number;
            totalTokens: number;
            totalQuotaConsumed: number;
            logs: {
                id: string;
                provider: string;
                model: string;
                promptTokens: number;
                completionTokens: number;
                tokenConsumed: number;
                createdAt: Date;
            }[];
        };
    }>;
    private callAiProvider;
    private getDefaultBaseUrl;
    private getDefaultModel;
    private calculateQuotaConsumed;
}
