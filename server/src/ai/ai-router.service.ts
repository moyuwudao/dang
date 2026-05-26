import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiKey, ApiKeyStatus } from '../api-key/entities/api-key.entity';
import { RedisService } from '../redis/redis.service';

interface RoutingStrategy {
  provider?: string;
  model?: string;
  fallbackEnabled: boolean;
}

@Injectable()
export class AiRouterService {
  private readonly logger = new Logger(AiRouterService.name);

  // 降级优先级：高成本 -> 低成本
  private readonly fallbackProviders = [
    'openai',
    'anthropic',
    'gemini',
    'grok',
    'deepseek',
    'qwen',
  ];

  constructor(
    @InjectRepository(ApiKey)
    private apiKeyRepository: Repository<ApiKey>,
    private readonly redisService: RedisService,
  ) {}

  // 选择最优的 API Key
  async selectOptimalKey(strategy: RoutingStrategy): Promise<ApiKey | null> {
    const { provider, model, fallbackEnabled } = strategy;

    // 1. 如果指定了 provider，优先选择该 provider 的 Key
    if (provider) {
      const key = await this.selectBestKey(provider);
      if (key) return key;

      // 如果指定 provider 不可用，且允许降级
      if (fallbackEnabled) {
        this.logger.warn(`Provider ${provider} 不可用，尝试降级`);
        return this.fallbackToNextProvider(provider);
      }

      return null;
    }

    // 2. 如果没有指定 provider，选择最优的可用 Key
    return this.selectBestKeyFromAll();
  }

  // 从指定 provider 中选择最优 Key
  private async selectBestKey(provider: string): Promise<ApiKey | null> {
    const keys = await this.apiKeyRepository.find({
      where: {
        provider,
        status: ApiKeyStatus.ACTIVE,
        lastHealthCheckStatus: 'healthy',
      },
    });

    if (keys.length === 0) {
      return null;
    }

    // 按使用率排序，选择使用率最低的
    return keys.sort((a, b) => {
      const usageA = a.dailyUsage / (a.dailyQuota || 1);
      const usageB = b.dailyUsage / (b.dailyQuota || 1);
      return usageA - usageB;
    })[0];
  }

  // 从所有 provider 中选择最优 Key
  private async selectBestKeyFromAll(): Promise<ApiKey | null> {
    for (const provider of this.fallbackProviders) {
      const key = await this.selectBestKey(provider);
      if (key) return key;
    }

    return null;
  }

  // 降级到下一个 provider
  private async fallbackToNextProvider(currentProvider: string): Promise<ApiKey | null> {
    const currentIndex = this.fallbackProviders.indexOf(currentProvider);
    
    if (currentIndex === -1 || currentIndex >= this.fallbackProviders.length - 1) {
      return null;
    }

    // 尝试下一个 provider
    for (let i = currentIndex + 1; i < this.fallbackProviders.length; i++) {
      const nextProvider = this.fallbackProviders[i];
      const key = await this.selectBestKey(nextProvider);
      if (key) {
        this.logger.log(`降级到 provider: ${nextProvider}`);
        return key;
      }
    }

    return null;
  }

  // 记录 API Key 使用
  async recordKeyUsage(keyId: string, tokens: number): Promise<void> {
    const key = await this.apiKeyRepository.findOne({ where: { id: keyId } });
    if (key) {
      key.dailyUsage += tokens;
      key.lastUsedAt = new Date();
      await this.apiKeyRepository.save(key);
    }
  }

  // 检查 API Key 是否可用
  async isKeyAvailable(keyId: string): Promise<boolean> {
    const key = await this.apiKeyRepository.findOne({
      where: { id: keyId, status: ApiKeyStatus.ACTIVE },
    });

    if (!key) return false;

    // 检查日配额
    if (key.dailyUsage >= key.dailyQuota) {
      return false;
    }

    // 检查健康状态
    if (key.lastHealthCheckStatus !== 'healthy') {
      return false;
    }

    return true;
  }
}
