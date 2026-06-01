import { Repository } from 'typeorm';
import { ApiKey, ApiKeyProvider, ApiKeyStatus, ApiKeyScope } from './entities/api-key.entity';
import { UserApiKey } from './entities/user-api-key.entity';
import { CreateApiKeyDto } from './dto';
import { HttpService } from '@nestjs/axios';
export declare class ApiKeyService {
    private apiKeyRepository;
    private userApiKeyRepository;
    private readonly httpService;
    constructor(apiKeyRepository: Repository<ApiKey>, userApiKeyRepository: Repository<UserApiKey>, httpService: HttpService);
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
        data: {
            id: string;
            provider: ApiKeyProvider;
            name: string;
            model: string;
            lastHealthCheckAt: Date;
        }[];
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
    private assignNewKey;
    private performHealthCheck;
    private checkOpenAI;
    private checkAnthropic;
    private checkQwen;
    private checkDeepSeek;
    private checkGemini;
    private checkGrok;
    private checkGeneric;
}
