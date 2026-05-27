import { Injectable, HttpException } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { firstValueFrom } from 'rxjs';
import { createReadStream, unlink } from 'fs';
import { ApiKeyService } from '../api-key/api-key.service';
import { SubscriptionService } from '../subscription/subscription.service';
import { RedisService } from '../redis/redis.service';
import { ApiUsageLog } from '../subscription/entities/api-usage-log.entity';
import { PlanApiPolicy } from '../subscription/entities/plan-api-policy.entity';

@Injectable()
export class AiService {
  constructor(
    private readonly httpService: HttpService,
    private readonly apiKeyService: ApiKeyService,
    private readonly subscriptionService: SubscriptionService,
    private readonly redisService: RedisService,
    @InjectRepository(ApiUsageLog)
    private apiUsageLogRepository: Repository<ApiUsageLog>,
    @InjectRepository(PlanApiPolicy)
    private planApiPolicyRepository: Repository<PlanApiPolicy>,
  ) {}

  async chat(userId: string, params: {
    messages: Array<{ role: string; content: string }>;
    provider?: string;
    model?: string;
    stream?: boolean;
  }) {
    // 1. 检查用户订阅和权限
    const subscription = await this.subscriptionService.getSubscription(userId);
    if (!subscription.data || subscription.data.status !== 'active') {
      throw new HttpException('订阅已过期，请充值', 402);
    }

    // 2. 获取 API Key
    const apiKeyResult = await this.apiKeyService.getApiKey(userId);
    if (!apiKeyResult.data?.apiKey) {
      throw new HttpException('未分配 API Key', 500);
    }

    const apiKey = apiKeyResult.data;

    // 3. 计算预估配额消耗（实际调用后更新）
    const estimatedQuota = 1; // 基础消耗

    // 4. 检查余额
    const balance = subscription.data.remainingQuota || 0;
    if (balance < estimatedQuota) {
      throw new HttpException('配额不足，请充值', 402);
    }

    // 5. 调用 AI 服务
    try {
      const response = await this.callAiProvider(apiKey, params);

      // 6. 计算实际消耗
      const promptTokens = response.usage?.prompt_tokens || 0;
      const completionTokens = response.usage?.completion_tokens || 0;
      const totalTokens = promptTokens + completionTokens;

      // 7. 计算配额消耗
      const quotaConsumed = await this.calculateQuotaConsumed(
        userId,
        apiKey.provider,
        params.model || 'default',
        totalTokens,
      );

      // 8. 扣减配额（直接更新数据库）
      await this.subscriptionService.updateQuotaUsage(userId, quotaConsumed);

      // 9. 记录使用日志
      await this.logApiUsage({
        userId,
        subscriptionId: subscription.data.planId,
        apiKeyId: apiKey.provider, // 简化处理
        provider: apiKey.provider,
        model: params.model || response.model || 'unknown',
        promptTokens,
        completionTokens,
        quotaConsumed,
      });

      return {
        code: 200,
        message: 'success',
        data: {
          content: response.choices?.[0]?.message?.content || '',
          model: response.model,
          provider: apiKey.provider,
        },
        usage: {
          promptTokens,
          completionTokens,
          totalTokens,
          quotaConsumed,
          remainingQuota: balance - quotaConsumed,
        },
      };
    } catch (error) {
      throw new HttpException(
        `AI 服务调用失败: ${error.message}`,
        error.status || 500,
      );
    }
  }

  async transcribe(userId: string, params: {
    audioPath: string;
    provider?: string;
    language?: string;
  }) {
    const subscription = await this.subscriptionService.getSubscription(userId);
    if (!subscription.data || subscription.data.status !== 'active') {
      throw new HttpException('订阅已过期，请充值', 402);
    }

    const apiKeyResult = await this.apiKeyService.getApiKey(userId);
    if (!apiKeyResult.data?.apiKey) {
      throw new HttpException('未分配 API Key', 500);
    }

    const apiKey = apiKeyResult.data;
    const balance = subscription.data.remainingQuota || 0;
    const estimatedQuota = 1;

    if (balance < estimatedQuota) {
      throw new HttpException('配额不足，请充值', 402);
    }

    try {
      const response = await this.callTranscriptionApi(apiKey, params);

      const quotaConsumed = await this.calculateQuotaConsumed(
        userId,
        apiKey.provider,
        'transcription',
        1,
      );

      await this.subscriptionService.updateQuotaUsage(userId, quotaConsumed);

      await this.logApiUsage({
        userId,
        subscriptionId: subscription.data.planId,
        apiKeyId: apiKey.provider,
        provider: apiKey.provider,
        model: 'transcription',
        promptTokens: 0,
        completionTokens: response.duration || 0,
        quotaConsumed,
      });

      unlink(params.audioPath, () => {});

      return {
        code: 200,
        message: 'success',
        data: {
          text: response.text || '',
          duration: response.duration || 0,
          provider: apiKey.provider,
        },
        usage: {
          quotaConsumed,
          remainingQuota: balance - quotaConsumed,
        },
      };
    } catch (error) {
      unlink(params.audioPath, () => {});
      throw new HttpException(
        `转写服务调用失败: ${error.message}`,
        error.status || 500,
      );
    }
  }

  private async callTranscriptionApi(apiKey: any, params: {
    audioPath: string;
    language?: string;
  }) {
    const url = apiKey.baseUrl || this.getDefaultBaseUrl(apiKey.provider);
    
    const formData = new (await import('form-data')).default();
    formData.append('file', createReadStream(params.audioPath));
    if (params.language) {
      formData.append('language', params.language);
    }

    let response;
    switch (apiKey.provider) {
      case 'qwen':
        response = await firstValueFrom(
          this.httpService.post(
            `${url}/asr/v1/recognize`,
            formData,
            {
              headers: {
                'Authorization': `Bearer ${apiKey.apiKey}`,
                ...formData.getHeaders(),
              },
              timeout: 120000,
            },
          ),
        );
        return {
          text: response.data.result?.sentence || response.data.data?.text || '',
          duration: response.data.duration || 0,
        };
      case 'openai':
        response = await firstValueFrom(
          this.httpService.post(
            `${url}/v1/audio/transcriptions`,
            formData,
            {
              headers: {
                'Authorization': `Bearer ${apiKey.apiKey}`,
                ...formData.getHeaders(),
              },
              timeout: 120000,
            },
          ),
        );
        return {
          text: response.data.text || '',
          duration: response.data.duration || 0,
        };
      default:
        throw new HttpException(`不支持的转写提供商: ${apiKey.provider}`, 400);
    }
  }

  async getUsage(userId: string, startDate?: string, endDate?: string) {
    const query = this.apiUsageLogRepository.createQueryBuilder('log')
      .where('log.userId = :userId', { userId })
      .orderBy('log.createdAt', 'DESC');

    if (startDate) {
      query.andWhere('log.createdAt >= :startDate', { startDate: new Date(startDate) });
    }
    if (endDate) {
      query.andWhere('log.createdAt <= :endDate', { endDate: new Date(endDate) });
    }

    const logs = await query.getMany();

    const totalCalls = logs.length;
    const totalTokens = logs.reduce((sum, log) => sum + log.promptTokens + log.completionTokens, 0);
    const totalQuota = logs.reduce((sum, log) => sum + log.quotaConsumed, 0);

    return {
      code: 200,
      message: 'success',
      data: {
        totalCalls,
        totalTokens,
        totalQuotaConsumed: totalQuota,
        logs: logs.map(log => ({
          id: log.id,
          provider: log.provider,
          model: log.model,
          promptTokens: log.promptTokens,
          completionTokens: log.completionTokens,
          quotaConsumed: log.quotaConsumed,
          createdAt: log.createdAt,
        })),
      },
    };
  }

  private async callAiProvider(apiKey: any, params: any) {
    // 根据 provider 调用不同的 API
    const url = apiKey.baseUrl || this.getDefaultBaseUrl(apiKey.provider);
    const model = params.model || apiKey.model || this.getDefaultModel(apiKey.provider);

    const response = await firstValueFrom(
      this.httpService.post(
        `${url}/v1/chat/completions`,
        {
          model,
          messages: params.messages,
          stream: params.stream || false,
        },
        {
          headers: {
            'Authorization': `Bearer ${apiKey.apiKey}`,
            'Content-Type': 'application/json',
          },
          timeout: 30000,
        },
      ),
    );

    return response.data;
  }

  private getDefaultBaseUrl(provider: string): string {
    const urls: Record<string, string> = {
      qwen: 'https://dashscope.aliyuncs.com/api',
      openai: 'https://api.openai.com',
      deepseek: 'https://api.deepseek.com',
      anthropic: 'https://api.anthropic.com',
      gemini: 'https://generativelanguage.googleapis.com',
      grok: 'https://api.x.ai',
    };
    return urls[provider] || 'https://api.openai.com';
  }

  private getDefaultModel(provider: string): string {
    const models: Record<string, string> = {
      qwen: 'qwen-plus',
      openai: 'gpt-3.5-turbo',
      deepseek: 'deepseek-chat',
      anthropic: 'claude-3-haiku-20240307',
      gemini: 'gemini-pro',
      grok: 'grok-beta',
    };
    return models[provider] || 'gpt-3.5-turbo';
  }

  private async calculateQuotaConsumed(
    userId: string,
    provider: string,
    model: string,
    tokens: number,
  ): Promise<number> {
    // 获取用户订阅和策略
    const subscription = await this.subscriptionService.getSubscription(userId);
    const planId = subscription.data?.planId;

    if (!planId) return 1;

    // 获取套餐API策略
    const policies = await this.planApiPolicyRepository.find({
      where: { planId },
    });

    // 查找匹配的策略
    const policy = policies.find((p: any) => {
      if (p.provider !== provider && p.provider !== 'all') return false;
      if (!p.modelPattern) return true;
      const pattern = p.modelPattern.replace('*', '.*');
      return new RegExp(`^${pattern}$`).test(model);
    });

    const multiplier = policy ? policy.multiplier : 1;

    // 计算消耗（基础1单位 × 倍数）
    return Math.ceil(1 * multiplier);
  }

  private async logApiUsage(params: {
    userId: string;
    subscriptionId: string;
    apiKeyId: string;
    provider: string;
    model: string;
    promptTokens: number;
    completionTokens: number;
    quotaConsumed: number;
  }) {
    const log = this.apiUsageLogRepository.create(params);
    await this.apiUsageLogRepository.save(log);
  }
}
