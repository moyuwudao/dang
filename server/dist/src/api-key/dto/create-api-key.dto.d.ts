import { ApiKeyProvider, ApiKeyScope, ApiKeyStatus } from '../entities/api-key.entity';
export declare class CreateApiKeyDto {
    provider: ApiKeyProvider;
    name: string;
    description?: string;
    apiKey: string;
    apiSecret?: string;
    model: string;
    baseUrl?: string;
    status?: ApiKeyStatus;
    scopes?: ApiKeyScope[];
    rateLimitPerMin?: number;
    maxConcurrentRequests?: number;
    dailyQuota?: number;
    expiresAt?: string;
    isDefault?: boolean;
    allowedIpRanges?: string;
}
