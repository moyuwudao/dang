import { ApiKeyService } from './api-key.service';
import { CreateApiKeyDto } from './dto';
export declare class ApiKeyController {
    private readonly apiKeyService;
    constructor(apiKeyService: ApiKeyService);
    getApiKey(req: any): Promise<{
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
    refreshApiKey(req: any): Promise<{
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
    deleteApiKey(id: string): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
}
