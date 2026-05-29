import { HttpService } from '@nestjs/axios';
import { Repository } from 'typeorm';
import { ApiKeyService } from '../api-key/api-key.service';
import { SubscriptionService } from '../subscription/subscription.service';
import { RedisService } from '../redis/redis.service';
import { ApiUsageLog } from '../subscription/entities/api-usage-log.entity';
import { PlanApiPolicy } from '../subscription/entities/plan-api-policy.entity';
export declare class AiService {
    private readonly httpService;
    private readonly apiKeyService;
    private readonly subscriptionService;
    private readonly redisService;
    private apiUsageLogRepository;
    private planApiPolicyRepository;
    constructor(httpService: HttpService, apiKeyService: ApiKeyService, subscriptionService: SubscriptionService, redisService: RedisService, apiUsageLogRepository: Repository<ApiUsageLog>, planApiPolicyRepository: Repository<PlanApiPolicy>);
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
            quotaConsumed: number;
            remainingQuota: number;
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
            quotaConsumed: number;
            remainingQuota: number;
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
                quotaConsumed: number;
                createdAt: Date;
            }[];
        };
    }>;
    private callAiProvider;
    private getDefaultBaseUrl;
    private getDefaultModel;
    private calculateQuotaConsumed;
    private logApiUsage;
}
