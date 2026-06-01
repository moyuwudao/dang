import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
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

@Injectable()
export class MetricsService {
  private readonly logger = new Logger(MetricsService.name);

  constructor(
    @InjectRepository(ApiUsageLog)
    private apiUsageLogRepository: Repository<ApiUsageLog>,
    private readonly redisService: RedisService,
  ) {}

  // 获取实时指标
  async getRealtimeMetrics(): Promise<MetricsData> {
    const now = new Date();
    const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);

    // 最近1小时的调用记录
    const recentLogs = await this.apiUsageLogRepository.find({
      where: {
        createdAt: new Date(oneHourAgo),
      },
      order: { createdAt: 'DESC' },
      take: 1000,
    });

    const totalCalls = recentLogs.length;
    const totalTokens = recentLogs.reduce((sum, log) => 
      sum + log.promptTokens + log.completionTokens, 0);
    const totalQuotaConsumed = recentLogs.reduce((sum, log) => 
      sum + log.tokenConsumed, 0);

    // 按 provider 分组
    const callsByProvider: Record<string, number> = {};
    recentLogs.forEach(log => {
      callsByProvider[log.provider] = (callsByProvider[log.provider] || 0) + 1;
    });

    // 按小时分组
    const callsByHour: Record<string, number> = {};
    recentLogs.forEach(log => {
      const hour = log.createdAt.getHours().toString().padStart(2, '0') + ':00';
      callsByHour[hour] = (callsByHour[hour] || 0) + 1;
    });

    return {
      totalCalls,
      totalTokens,
      totalQuotaConsumed,
      avgResponseTime: 0, // 需要额外记录
      errorRate: 0, // 需要额外记录
      callsByProvider,
      callsByHour,
    };
  }

  // 获取日统计
  async getDailyMetrics(date: Date = new Date()): Promise<any> {
    const startOfDay = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    const endOfDay = new Date(date.getFullYear(), date.getMonth(), date.getDate() + 1);

    const logs = await this.apiUsageLogRepository.find({
      where: {
        createdAt: new Date(startOfDay),
      },
    });

    const totalCalls = logs.length;
    const totalTokens = logs.reduce((sum, log) => 
      sum + log.promptTokens + log.completionTokens, 0);
    const totalQuota = logs.reduce((sum, log) => 
      sum + log.tokenConsumed, 0);

    // 按 provider 统计
    const providerStats: Record<string, { calls: number; tokens: number; quota: number }> = {};
    logs.forEach(log => {
      if (!providerStats[log.provider]) {
        providerStats[log.provider] = { calls: 0, tokens: 0, quota: 0 };
      }
      providerStats[log.provider].calls++;
      providerStats[log.provider].tokens += log.promptTokens + log.completionTokens;
      providerStats[log.provider].quota += log.tokenConsumed;
    });

    return {
      date: startOfDay.toISOString().split('T')[0],
      totalCalls,
      totalTokens,
      totalQuotaConsumed: totalQuota,
      providerStats,
    };
  }

  // 获取趋势数据（最近7天）
  async getTrendData(days: number = 7): Promise<any[]> {
    const result = [];
    const now = new Date();

    for (let i = days - 1; i >= 0; i--) {
      const date = new Date(now.getTime() - i * 24 * 60 * 60 * 1000);
      const metrics = await this.getDailyMetrics(date);
      result.push(metrics);
    }

    return result;
  }

  // 记录响应时间
  async recordResponseTime(duration: number): Promise<void> {
    const key = `metrics:response_time:${new Date().toISOString().split('T')[0]}`;
    await this.redisService.increment(key, Math.round(duration));
    await this.redisService.expire(key, 86400); // 24小时过期
  }

  // 记录错误
  async recordError(provider: string, errorType: string): Promise<void> {
    const key = `metrics:error:${provider}:${new Date().toISOString().split('T')[0]}`;
    await this.redisService.increment(key, 1);
    await this.redisService.expire(key, 86400);
  }
}
