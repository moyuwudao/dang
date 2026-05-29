import { Repository } from 'typeorm';
import { ApiKey } from '../api-key/entities/api-key.entity';
import { RedisService } from '../redis/redis.service';
interface RoutingStrategy {
    provider?: string;
    model?: string;
    fallbackEnabled: boolean;
}
export declare class AiRouterService {
    private apiKeyRepository;
    private readonly redisService;
    private readonly logger;
    private readonly fallbackProviders;
    constructor(apiKeyRepository: Repository<ApiKey>, redisService: RedisService);
    selectOptimalKey(strategy: RoutingStrategy): Promise<ApiKey | null>;
    private selectBestKey;
    private selectBestKeyFromAll;
    private fallbackToNextProvider;
    recordKeyUsage(keyId: string, tokens: number): Promise<void>;
    isKeyAvailable(keyId: string): Promise<boolean>;
}
export {};
