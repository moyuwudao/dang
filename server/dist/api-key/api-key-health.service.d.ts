import { Repository } from 'typeorm';
import { ApiKey } from './entities/api-key.entity';
import { ApiKeyService } from './api-key.service';
export declare class ApiKeyHealthService {
    private apiKeyRepository;
    private readonly apiKeyService;
    private readonly logger;
    constructor(apiKeyRepository: Repository<ApiKey>, apiKeyService: ApiKeyService);
    checkAllApiKeysHealth(): Promise<void>;
    getHealthyKeys(provider?: string): Promise<ApiKey[]>;
    getOptimalKey(provider?: string): Promise<ApiKey | null>;
}
