import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiKey, ApiKeyStatus } from './entities/api-key.entity';
import { ApiKeyService } from './api-key.service';

@Injectable()
export class ApiKeyHealthService {
  private readonly logger = new Logger(ApiKeyHealthService.name);

  constructor(
    @InjectRepository(ApiKey)
    private apiKeyRepository: Repository<ApiKey>,
    private readonly apiKeyService: ApiKeyService,
  ) {}

  // 每5分钟检查一次所有 API Key 的健康状态
  @Cron(CronExpression.EVERY_5_MINUTES)
  async checkAllApiKeysHealth() {
    this.logger.log('开始检查所有 API Key 健康状态');

    const keys = await this.apiKeyRepository.find({
      where: { status: ApiKeyStatus.ACTIVE },
    });

    for (const key of keys) {
      try {
        await this.apiKeyService.testApiKey(key.id);
        this.logger.log(`API Key ${key.name} (${key.provider}) 健康检查通过`);
      } catch (error) {
        this.logger.error(`API Key ${key.name} (${key.provider}) 健康检查失败: ${error.message}`);
      }
    }

    this.logger.log('API Key 健康检查完成');
  }

  // 获取健康的 API Key 列表
  async getHealthyKeys(provider?: string): Promise<ApiKey[]> {
    const where: any = {
      status: ApiKeyStatus.ACTIVE,
      lastHealthCheckStatus: 'healthy',
    };

    if (provider) {
      where.provider = provider;
    }

    return this.apiKeyRepository.find({ where });
  }

  // 获取最优的 API Key（健康 + 使用率低）
  async getOptimalKey(provider?: string): Promise<ApiKey | null> {
    const keys = await this.getHealthyKeys(provider);

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
}
