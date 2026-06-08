import { ApiKeyService } from './api-key.service';
import { CreateApiKeyDto, TestApiKeyDto } from './dto';
export declare class ApiKeyController {
    private readonly apiKeyService;
    constructor(apiKeyService: ApiKeyService);
    getApiKey(req: any, provider?: string): Promise<{
        code: number;
        message: string;
        data: {
            provider: import("./entities/api-key.entity").ApiKeyProvider;
            apiKey: string;
            model: string;
            rateLimitPerMin: number;
            expiresAt: Date;
        };
    }>;
    refreshApiKey(req: any): Promise<{
        code: number;
        message: string;
        data: {
            provider: import("./entities/api-key.entity").ApiKeyProvider;
            apiKey: string;
            model: string;
            rateLimitPerMin: number;
            expiresAt: Date;
        };
    }>;
    getApiKeys(): Promise<{
        code: number;
        message: string;
        data: {
            id: string;
            provider: import("./entities/api-key.entity").ApiKeyProvider;
            name: string;
            description: string;
            model: string;
            status: import("./entities/api-key.entity").ApiKeyStatus;
            scopes: import("./entities/api-key.entity").ApiKeyScope[];
            supportedFeatures: string[];
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
    getApiKeyStats(): Promise<{
        code: number;
        message: string;
        data: {
            total: number;
            active: number;
            inactive: number;
            expired: number;
            providers: {
                provider: import("./entities/api-key.entity").ApiKeyProvider;
                count: number;
            }[];
        };
    }>;
    getHealthyModels(): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    getApiKeyById(id: string): Promise<{
        code: number;
        message: string;
        data: {
            id: string;
            provider: import("./entities/api-key.entity").ApiKeyProvider;
            name: string;
            description: string;
            model: string;
            baseUrl: string;
            status: import("./entities/api-key.entity").ApiKeyStatus;
            scopes: import("./entities/api-key.entity").ApiKeyScope[];
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
    createApiKey(dto: CreateApiKeyDto): Promise<{
        code: number;
        message: string;
        data: {
            id: string;
            provider: import("./entities/api-key.entity").ApiKeyProvider;
            name: string;
            model: string;
            status: import("./entities/api-key.entity").ApiKeyStatus;
        };
    }>;
    batchCreateApiKeys(dtos: CreateApiKeyDto[]): Promise<{
        code: number;
        message: string;
        data: any[];
    }>;
    updateApiKey(id: string, dto: Partial<CreateApiKeyDto>): Promise<{
        code: number;
        message: string;
        data: {
            id: string;
            provider: import("./entities/api-key.entity").ApiKeyProvider;
            name: string;
            status: import("./entities/api-key.entity").ApiKeyStatus;
        };
    }>;
    deleteApiKey(id: string): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    testApiKey(id: string, dto?: TestApiKeyDto): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
}
