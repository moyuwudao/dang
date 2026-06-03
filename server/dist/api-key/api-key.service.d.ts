import { Repository } from 'typeorm';
import { ApiKey, ApiKeyProvider, ApiKeyStatus, ApiKeyScope } from './entities/api-key.entity';
import { UserApiKey } from './entities/user-api-key.entity';
import { CreateApiKeyDto } from './dto';
import { HttpService } from '@nestjs/axios';
import { RedisService } from '../redis/redis.service';
export declare class ApiKeyService {
    private apiKeyRepository;
    private userApiKeyRepository;
    private readonly httpService;
    private readonly redisService;
    private readonly ACTIVE_KEYS_CACHE;
    private readonly USER_KEY_CACHE_PREFIX;
    private readonly KEY_USAGE_PREFIX;
    private readonly CACHE_TTL;
    constructor(apiKeyRepository: Repository<ApiKey>, userApiKeyRepository: Repository<UserApiKey>, httpService: HttpService, redisService: RedisService);
    getApiKey(userId: string): Promise<{
        code: number;
        message: string;
        data: {
            provider: ApiKeyProvider;
            apiKey: string;
            model: string;
            rateLimitPerMin: number;
            expiresAt: Date;
        };
    }>;
    refreshApiKey(userId: string): Promise<{
        code: number;
        message: string;
        data: {
            provider: ApiKeyProvider;
            apiKey: string;
            model: string;
            rateLimitPerMin: number;
            expiresAt: Date;
        };
    }>;
    createApiKey(dto: CreateApiKeyDto): Promise<{
        code: number;
        message: string;
        data: {
            id: string;
            provider: ApiKeyProvider;
            name: string;
            model: string;
            status: ApiKeyStatus;
        };
    }>;
    getApiKeys(): Promise<{
        code: number;
        message: string;
        data: {
            id: string;
            provider: ApiKeyProvider;
            name: string;
            description: string;
            model: string;
            status: ApiKeyStatus;
            scopes: ApiKeyScope[];
            rateLimitPerMin: number;
            maxConcurrentRequests: number;
            dailyQuota: number;
            dailyUsage: number;
            expiresAt: Date;
            isDefault: boolean;
            lastUsedAt: Date;
            lastHealthCheckAt: Date;
            lastHealthCheckStatus: string;
            createdAt: Date;
            updatedAt: Date;
        }[];
    }>;
    getApiKeyById(id: string): Promise<{
        code: number;
        message: string;
        data: {
            id: string;
            provider: ApiKeyProvider;
            name: string;
            description: string;
            model: string;
            baseUrl: string;
            status: ApiKeyStatus;
            scopes: ApiKeyScope[];
            rateLimitPerMin: number;
            maxConcurrentRequests: number;
            dailyQuota: number;
            dailyUsage: number;
            expiresAt: Date;
            isDefault: boolean;
            lastUsedAt: Date;
            lastHealthCheckAt: Date;
            lastHealthCheckStatus: string;
            allowedIpRanges: string;
            createdAt: Date;
            updatedAt: Date;
        };
    }>;
    updateApiKey(id: string, dto: Partial<CreateApiKeyDto>): Promise<{
        code: number;
        message: string;
        data: {
            id: string;
            provider: ApiKeyProvider;
            name: string;
            status: ApiKeyStatus;
        };
    }>;
    deleteApiKey(id: string): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    testApiKey(id: string): Promise<{
        code: number;
        message: string;
        data: {
            status: string;
            provider: ApiKeyProvider;
            model: string;
            responseTime: number;
            details: any;
            error?: undefined;
        };
    } | {
        code: number;
        message: string;
        data: {
            status: string;
            provider: ApiKeyProvider;
            model: string;
            error: any;
            responseTime?: undefined;
            details?: undefined;
        };
    }>;
    getHealthyModels(): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    getApiKeyStats(): Promise<{
        code: number;
        message: string;
        data: {
            total: number;
            active: number;
            inactive: number;
            expired: number;
            providers: {
                provider: ApiKeyProvider;
                count: number;
            }[];
        };
    }>;
    recordKeyUsage(keyId: string, tokens: number): Promise<void>;
    private getKeyFromCacheOrDb;
    private isKeyAvailable;
    private assignNewKey;
    private getActiveKeysWithCache;
    private selectOptimalKey;
    private findLessLoadedKey;
    private assignKeyToUser;
    private performHealthCheck;
    private checkOpenAI;
    private checkAnthropic;
    private checkQwen;
    private checkDeepSeek;
    private checkGemini;
    private checkGrok;
    private checkGeneric;
}
