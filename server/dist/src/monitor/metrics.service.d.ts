import { Repository } from 'typeorm';
import { ApiUsageLog } from '../subscription/entities/api-usage-log.entity';
import { RedisService } from '../redis/redis.service';
export interface MetricsData {
    totalCalls: number;
    totalTokens: number;
    totalQuotaConsumed: number;
    avgResponseTime: number;
    errorRate: number;
    callsByProvider: Record<string, number>;
    callsByHour: Record<string, number>;
}
export declare class MetricsService {
    private apiUsageLogRepository;
    private readonly redisService;
    private readonly logger;
    constructor(apiUsageLogRepository: Repository<ApiUsageLog>, redisService: RedisService);
    getRealtimeMetrics(): Promise<MetricsData>;
    getDailyMetrics(date?: Date): Promise<any>;
    getTrendData(days?: number): Promise<any[]>;
    recordResponseTime(duration: number): Promise<void>;
    recordError(provider: string, errorType: string): Promise<void>;
}
