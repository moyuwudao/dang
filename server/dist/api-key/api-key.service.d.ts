import { Repository } from 'typeorm';
import { ApiKey } from './entities/api-key.entity';
import { UserApiKey } from './entities/user-api-key.entity';
import { CreateApiKeyDto } from './dto';
export declare class ApiKeyService {
    private apiKeyRepository;
    private userApiKeyRepository;
    constructor(apiKeyRepository: Repository<ApiKey>, userApiKeyRepository: Repository<UserApiKey>);
    getApiKey(userId: string): Promise<{
        code: number;
        message: string;
        data: {
            provider: string;
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
            provider: string;
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
            provider: string;
            model: string;
            isActive: boolean;
        };
    }>;
    getApiKeys(): Promise<{
        code: number;
        message: string;
        data: {
            id: string;
            provider: string;
            model: string;
            isActive: boolean;
            rateLimitPerMin: number;
            createdAt: Date;
        }[];
    }>;
    deleteApiKey(id: string): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    private assignNewKey;
}
