import { Injectable, ForbiddenException, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiKey, ApiKeyProvider, ApiKeyStatus, ApiKeyScope } from './entities/api-key.entity';
import { UserApiKey } from './entities/user-api-key.entity';
import { CreateApiKeyDto } from './dto';
import { CryptoUtil } from '../common/crypto.util';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { RedisService } from '../redis/redis.service';

interface KeyScore {
  key: ApiKey;
  score: number;
}

@Injectable()
export class ApiKeyService {
  private readonly ACTIVE_KEYS_CACHE = 'api:active_keys';
  private readonly USER_KEY_CACHE_PREFIX = 'api:user_key:';
  private readonly KEY_USAGE_PREFIX = 'api:key_usage:';
  private readonly CACHE_TTL = 300; // 5分钟

  constructor(
    @InjectRepository(ApiKey)
    private apiKeyRepository: Repository<ApiKey>,
    @InjectRepository(UserApiKey)
    private userApiKeyRepository: Repository<UserApiKey>,
    private readonly httpService: HttpService,
    private readonly redisService: RedisService,
  ) {}

  async getApiKey(userId: string) {
    // 1. 先查Redis缓存用户的分配关系
    const cachedKeyId = await this.redisService.get(`${this.USER_KEY_CACHE_PREFIX}${userId}`);

    if (cachedKeyId) {
      const cachedKey = await this.getKeyFromCacheOrDb(cachedKeyId);
      if (cachedKey && this.isKeyAvailable(cachedKey)) {
        const decryptedKey = CryptoUtil.decrypt(cachedKey.apiKeyEncrypted);
        return {
          code: 200,
          message: 'success',
          data: {
            provider: cachedKey.provider,
            apiKey: decryptedKey,
            model: cachedKey.model,
            rateLimitPerMin: cachedKey.rateLimitPerMin,
            expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
          },
        };
      }
    }

    // 2. 查数据库中的活跃分配
    const existingAssignment = await this.userApiKeyRepository.findOne({
      where: { userId, isActive: true },
      order: { assignedAt: 'DESC' },
    });

    if (existingAssignment && existingAssignment.expiresAt > new Date()) {
      const apiKey = await this.apiKeyRepository.findOne({
        where: { id: existingAssignment.apiKeyId },
      });

      if (apiKey && this.isKeyAvailable(apiKey)) {
        // 缓存用户分配关系
        await this.redisService.set(
          `${this.USER_KEY_CACHE_PREFIX}${userId}`,
          apiKey.id,
          this.CACHE_TTL,
        );

        const decryptedKey = CryptoUtil.decrypt(apiKey.apiKeyEncrypted);
        return {
          code: 200,
          message: 'success',
          data: {
            provider: apiKey.provider,
            apiKey: decryptedKey,
            model: apiKey.model,
            rateLimitPerMin: apiKey.rateLimitPerMin,
            expiresAt: existingAssignment.expiresAt,
          },
        };
      }
    }

    // 3. 分配新Key（带负载均衡）
    return this.assignNewKey(userId);
  }

  async refreshApiKey(userId: string) {
    // 清除缓存
    await this.redisService.del(`${this.USER_KEY_CACHE_PREFIX}${userId}`);

    await this.userApiKeyRepository.update(
      { userId, isActive: true },
      { isActive: false },
    );

    return this.assignNewKey(userId);
  }

  async createApiKey(dto: CreateApiKeyDto) {
    const encryptedKey = CryptoUtil.encrypt(dto.apiKey);
    const encryptedSecret = dto.apiSecret ? CryptoUtil.encrypt(dto.apiSecret) : null;

    const apiKey = this.apiKeyRepository.create({
      provider: dto.provider,
      name: dto.name,
      description: dto.description,
      apiKeyEncrypted: encryptedKey,
      apiSecretEncrypted: encryptedSecret,
      model: dto.model,
      baseUrl: dto.baseUrl,
      status: dto.status ?? ApiKeyStatus.ACTIVE,
      scopes: (dto.scopes ?? [ApiKeyScope.ALL]) as ApiKeyScope[],
      rateLimitPerMin: dto.rateLimitPerMin ?? 60,
      maxConcurrentRequests: dto.maxConcurrentRequests ?? 5,
      dailyQuota: dto.dailyQuota ?? 1000,
      expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : null,
      isDefault: dto.isDefault ?? false,
      allowedIpRanges: dto.allowedIpRanges,
    });

    await this.apiKeyRepository.save(apiKey);

    // 清除活跃Key缓存，让下次请求重新加载
    await this.redisService.del(this.ACTIVE_KEYS_CACHE);

    return {
      code: 200,
      message: 'API Key 创建成功',
      data: {
        id: apiKey.id,
        provider: apiKey.provider,
        name: apiKey.name,
        model: apiKey.model,
        status: apiKey.status,
      },
    };
  }

  async getApiKeys() {
    const keys = await this.apiKeyRepository.find();
    return {
      code: 200,
      message: 'success',
      data: keys.map(k => ({
        id: k.id,
        provider: k.provider,
        name: k.name,
        description: k.description,
        model: k.model,
        status: k.status,
        scopes: k.scopes,
        rateLimitPerMin: k.rateLimitPerMin,
        maxConcurrentRequests: k.maxConcurrentRequests,
        dailyQuota: k.dailyQuota,
        dailyUsage: k.dailyUsage,
        expiresAt: k.expiresAt,
        isDefault: k.isDefault,
        lastUsedAt: k.lastUsedAt,
        lastHealthCheckAt: k.lastHealthCheckAt,
        lastHealthCheckStatus: k.lastHealthCheckStatus,
        createdAt: k.createdAt,
        updatedAt: k.updatedAt,
      })),
    };
  }

  async getApiKeyById(id: string) {
    const apiKey = await this.apiKeyRepository.findOne({ where: { id } });
    if (!apiKey) {
      throw new NotFoundException('API Key 不存在');
    }
    return {
      code: 200,
      message: 'success',
      data: {
        id: apiKey.id,
        provider: apiKey.provider,
        name: apiKey.name,
        description: apiKey.description,
        model: apiKey.model,
        baseUrl: apiKey.baseUrl,
        status: apiKey.status,
        scopes: apiKey.scopes,
        rateLimitPerMin: apiKey.rateLimitPerMin,
        maxConcurrentRequests: apiKey.maxConcurrentRequests,
        dailyQuota: apiKey.dailyQuota,
        dailyUsage: apiKey.dailyUsage,
        expiresAt: apiKey.expiresAt,
        isDefault: apiKey.isDefault,
        lastUsedAt: apiKey.lastUsedAt,
        lastHealthCheckAt: apiKey.lastHealthCheckAt,
        lastHealthCheckStatus: apiKey.lastHealthCheckStatus,
        allowedIpRanges: apiKey.allowedIpRanges,
        createdAt: apiKey.createdAt,
        updatedAt: apiKey.updatedAt,
      },
    };
  }

  async updateApiKey(id: string, dto: Partial<CreateApiKeyDto>) {
    const apiKey = await this.apiKeyRepository.findOne({ where: { id } });
    if (!apiKey) {
      throw new NotFoundException('API Key 不存在');
    }

    if (dto.apiKey) {
      apiKey.apiKeyEncrypted = CryptoUtil.encrypt(dto.apiKey);
    }
    if (dto.apiSecret) {
      apiKey.apiSecretEncrypted = CryptoUtil.encrypt(dto.apiSecret);
    }
    if (dto.provider) apiKey.provider = dto.provider;
    if (dto.name) apiKey.name = dto.name;
    if (dto.description !== undefined) apiKey.description = dto.description;
    if (dto.model) apiKey.model = dto.model;
    if (dto.baseUrl !== undefined) apiKey.baseUrl = dto.baseUrl;
    if (dto.status) apiKey.status = dto.status;
    if (dto.scopes) apiKey.scopes = dto.scopes;
    if (dto.rateLimitPerMin !== undefined) apiKey.rateLimitPerMin = dto.rateLimitPerMin;
    if (dto.maxConcurrentRequests !== undefined) apiKey.maxConcurrentRequests = dto.maxConcurrentRequests;
    if (dto.dailyQuota !== undefined) apiKey.dailyQuota = dto.dailyQuota;
    if (dto.expiresAt) apiKey.expiresAt = new Date(dto.expiresAt);
    if (dto.isDefault !== undefined) apiKey.isDefault = dto.isDefault;
    if (dto.allowedIpRanges !== undefined) apiKey.allowedIpRanges = dto.allowedIpRanges;

    await this.apiKeyRepository.save(apiKey);

    // 清除相关缓存
    await this.redisService.del(this.ACTIVE_KEYS_CACHE);
    await this.redisService.del(`${this.KEY_USAGE_PREFIX}${id}`);

    return {
      code: 200,
      message: 'API Key 更新成功',
      data: {
        id: apiKey.id,
        provider: apiKey.provider,
        name: apiKey.name,
        status: apiKey.status,
      },
    };
  }

  async deleteApiKey(id: string) {
    const apiKey = await this.apiKeyRepository.findOne({ where: { id } });
    if (!apiKey) {
      throw new NotFoundException('API Key 不存在');
    }

    await this.apiKeyRepository.delete(id);

    // 清除相关缓存
    await this.redisService.del(this.ACTIVE_KEYS_CACHE);
    await this.redisService.del(`${this.KEY_USAGE_PREFIX}${id}`);

    return {
      code: 200,
      message: 'API Key 删除成功',
      data: null,
    };
  }

  async testApiKey(id: string) {
    const apiKey = await this.apiKeyRepository.findOne({ where: { id } });
    if (!apiKey) {
      throw new NotFoundException('API Key 不存在');
    }

    const decryptedKey = CryptoUtil.decrypt(apiKey.apiKeyEncrypted);

    // 更新健康检查时间
    apiKey.lastHealthCheckAt = new Date();

    try {
      // 根据 provider 进行不同的连通性测试
      const result = await this.performHealthCheck(apiKey.provider, decryptedKey, apiKey.baseUrl);
      apiKey.lastHealthCheckStatus = 'healthy';
      await this.apiKeyRepository.save(apiKey);

      return {
        code: 200,
        message: '连通性测试成功',
        data: {
          status: 'healthy',
          provider: apiKey.provider,
          model: apiKey.model,
          responseTime: result.responseTime,
          details: result.details,
        },
      };
    } catch (error) {
      apiKey.lastHealthCheckStatus = 'unhealthy';
      await this.apiKeyRepository.save(apiKey);

      return {
        code: 200,
        message: '连通性测试失败',
        data: {
          status: 'unhealthy',
          provider: apiKey.provider,
          model: apiKey.model,
          error: error.message,
        },
      };
    }
  }

  // 获取已测试通过的健康 API Key 模型列表
  async getHealthyModels() {
    // 优先从缓存获取
    const cached = await this.redisService.get(this.ACTIVE_KEYS_CACHE);
    if (cached) {
      const keys = JSON.parse(cached);
      const healthyKeys = keys.filter((k: any) => k.status === ApiKeyStatus.ACTIVE && k.lastHealthCheckStatus === 'healthy');
      return {
        code: 200,
        message: 'success',
        data: healthyKeys.map((k: any) => ({
          id: k.id,
          provider: k.provider,
          name: k.name,
          model: k.model,
          lastHealthCheckAt: k.lastHealthCheckAt,
        })),
      };
    }

    const keys = await this.apiKeyRepository.find({
      where: {
        status: ApiKeyStatus.ACTIVE,
        lastHealthCheckStatus: 'healthy',
      },
    });

    const models = keys.map(k => ({
      id: k.id,
      provider: k.provider,
      name: k.name,
      model: k.model,
      lastHealthCheckAt: k.lastHealthCheckAt,
    }));

    return {
      code: 200,
      message: 'success',
      data: models,
    };
  }

  async getApiKeyStats() {
    const totalKeys = await this.apiKeyRepository.count();
    const activeKeys = await this.apiKeyRepository.count({ where: { status: ApiKeyStatus.ACTIVE } });
    const inactiveKeys = await this.apiKeyRepository.count({ where: { status: ApiKeyStatus.INACTIVE } });
    const expiredKeys = await this.apiKeyRepository.count({ where: { status: ApiKeyStatus.EXPIRED } });

    // 获取各 provider 的统计
    const providers = Object.values(ApiKeyProvider);
    const providerStats = await Promise.all(
      providers.map(async (provider) => ({
        provider,
        count: await this.apiKeyRepository.count({ where: { provider } }),
      })),
    );

    return {
      code: 200,
      message: 'success',
      data: {
        total: totalKeys,
        active: activeKeys,
        inactive: inactiveKeys,
        expired: expiredKeys,
        providers: providerStats.filter(p => p.count > 0),
      },
    };
  }

  // 记录API Key使用（用于实时更新缓存中的使用率）
  async recordKeyUsage(keyId: string, tokens: number): Promise<void> {
    // 更新Redis中的实时使用量
    await this.redisService.increment(`${this.KEY_USAGE_PREFIX}${keyId}`, tokens);
    // 设置过期时间为当天剩余时间
    const now = new Date();
    const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
    const ttlSeconds = Math.floor((endOfDay.getTime() - now.getTime()) / 1000);
    await this.redisService.expire(`${this.KEY_USAGE_PREFIX}${keyId}`, ttlSeconds);

    // 异步更新数据库
    const key = await this.apiKeyRepository.findOne({ where: { id: keyId } });
    if (key) {
      key.dailyUsage += tokens;
      key.lastUsedAt = new Date();
      await this.apiKeyRepository.save(key);
    }
  }

  // 从缓存或数据库获取Key
  private async getKeyFromCacheOrDb(keyId: string): Promise<ApiKey | null> {
    // 先查活跃Key缓存
    const cached = await this.redisService.get(this.ACTIVE_KEYS_CACHE);
    if (cached) {
      const keys = JSON.parse(cached);
      const found = keys.find((k: any) => k.id === keyId);
      if (found) {
        // 合并Redis实时使用量
        const realTimeUsage = await this.redisService.get(`${this.KEY_USAGE_PREFIX}${keyId}`);
        if (realTimeUsage) {
          found.dailyUsage = parseInt(realTimeUsage, 10);
        }
        return found;
      }
    }

    // 回退到数据库
    return this.apiKeyRepository.findOne({ where: { id: keyId } });
  }

  // 检查Key是否可用（配额+健康状态）
  private isKeyAvailable(key: ApiKey): boolean {
    if (key.status !== ApiKeyStatus.ACTIVE) return false;
    if (key.lastHealthCheckStatus !== 'healthy') return false;
    if (key.dailyUsage >= key.dailyQuota) return false;
    if (key.expiresAt && key.expiresAt < new Date()) return false;
    return true;
  }

  // 核心：带负载均衡的Key分配
  private async assignNewKey(userId: string) {
    // 1. 获取所有活跃且健康的Key（带缓存）
    const activeKeys = await this.getActiveKeysWithCache();

    // 2. 过滤可用Key（配额预检）
    const availableKeys = activeKeys.filter(key => this.isKeyAvailable(key));

    if (availableKeys.length === 0) {
      throw new ForbiddenException('API Key 池已耗尽，请联系管理员');
    }

    // 3. 加权轮询选择最优Key
    const selectedKey = this.selectOptimalKey(availableKeys);

    // 4. 获取该Key当前已分配的用户数（用于负载均衡计算）
    const assignedUserCount = await this.userApiKeyRepository.count({
      where: { apiKeyId: selectedKey.id, isActive: true },
    });

    // 5. 如果该Key负载过高（用户数超过并发限制），尝试找次优Key
    if (assignedUserCount >= selectedKey.maxConcurrentRequests) {
      const alternativeKey = this.findLessLoadedKey(availableKeys, selectedKey);
      if (alternativeKey) {
        return this.assignKeyToUser(userId, alternativeKey);
      }
    }

    return this.assignKeyToUser(userId, selectedKey);
  }

  // 获取活跃Key列表（带Redis缓存）
  private async getActiveKeysWithCache(): Promise<ApiKey[]> {
    const cached = await this.redisService.get(this.ACTIVE_KEYS_CACHE);
    if (cached) {
      const keys = JSON.parse(cached) as ApiKey[];
      // 合并实时使用量
      for (const key of keys) {
        const realTimeUsage = await this.redisService.get(`${this.KEY_USAGE_PREFIX}${key.id}`);
        if (realTimeUsage) {
          key.dailyUsage = parseInt(realTimeUsage, 10);
        }
      }
      return keys;
    }

    // 从数据库加载
    const keys = await this.apiKeyRepository.find({
      where: { status: ApiKeyStatus.ACTIVE },
    });

    // 缓存到Redis
    await this.redisService.set(this.ACTIVE_KEYS_CACHE, JSON.stringify(keys), this.CACHE_TTL);

    return keys;
  }

  // 选择最优Key（综合评分：使用率 + 响应时间 + 健康度）
  private selectOptimalKey(keys: ApiKey[]): ApiKey {
    const scoredKeys: KeyScore[] = keys.map(key => {
      // 使用率权重：40%（越低越好）
      const usageRate = key.dailyQuota > 0 ? key.dailyUsage / key.dailyQuota : 0;
      const usageScore = (1 - usageRate) * 40;

      // 健康度权重：30%（最近健康检查状态）
      let healthScore = 30;
      if (key.lastHealthCheckStatus === 'healthy') {
        healthScore = 30;
      } else if (key.lastHealthCheckStatus === 'unhealthy') {
        healthScore = 0;
      } else {
        healthScore = 15; // 未检查
      }

      // 响应时间权重：20%（最近响应时间越短越好，假设lastUsedAt作为代理）
      let responseScore = 20;
      if (key.lastUsedAt) {
        const minutesSinceLastUse = (Date.now() - key.lastUsedAt.getTime()) / 60000;
        if (minutesSinceLastUse < 5) {
          responseScore = 20; // 最近使用过，响应快
        } else if (minutesSinceLastUse < 30) {
          responseScore = 15;
        } else {
          responseScore = 10;
        }
      }

      // 稳定性权重：10%（配额余量）
      const quotaScore = key.dailyQuota > 0
        ? (1 - (key.dailyUsage / key.dailyQuota)) * 10
        : 10;

      return {
        key,
        score: usageScore + healthScore + responseScore + quotaScore,
      };
    });

    // 按分数降序排序，选择最高分
    scoredKeys.sort((a, b) => b.score - a.score);

    // 如果有多个Key分数相近（差距<5分），随机选择前几个中的一个，避免总是选同一个
    const topKeys = scoredKeys.filter(s => s.score >= scoredKeys[0].score - 5);
    if (topKeys.length > 1) {
      const randomIndex = Math.floor(Math.random() * topKeys.length);
      return topKeys[randomIndex].key;
    }

    return scoredKeys[0].key;
  }

  // 寻找负载更低的Key
  private findLessLoadedKey(keys: ApiKey[], excludeKey: ApiKey): ApiKey | null {
    const otherKeys = keys.filter(k => k.id !== excludeKey.id);
    if (otherKeys.length === 0) return null;

    // 按并发用户数排序
    return this.selectOptimalKey(otherKeys);
  }

  // 分配Key给用户
  private async assignKeyToUser(userId: string, apiKey: ApiKey) {
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24); // 24小时过期

    const assignment = this.userApiKeyRepository.create({
      userId,
      apiKeyId: apiKey.id,
      assignedAt: new Date(),
      expiresAt,
      isActive: true,
    });

    await this.userApiKeyRepository.save(assignment);

    // 缓存用户分配关系
    await this.redisService.set(
      `${this.USER_KEY_CACHE_PREFIX}${userId}`,
      apiKey.id,
      24 * 60 * 60, // 24小时，与用户分配过期时间一致
    );

    const decryptedKey = CryptoUtil.decrypt(apiKey.apiKeyEncrypted);

    return {
      code: 200,
      message: 'success',
      data: {
        provider: apiKey.provider,
        apiKey: decryptedKey,
        model: apiKey.model,
        rateLimitPerMin: apiKey.rateLimitPerMin,
        expiresAt,
      },
    };
  }

  private async performHealthCheck(provider: string, apiKey: string, baseUrl?: string): Promise<{ responseTime: number; details: any }> {
    const startTime = Date.now();

    switch (provider) {
      case ApiKeyProvider.OPENAI:
        return this.checkOpenAI(apiKey, baseUrl);
      case ApiKeyProvider.ANTHROPIC:
        return this.checkAnthropic(apiKey, baseUrl);
      case ApiKeyProvider.QWEN:
        return this.checkQwen(apiKey, baseUrl);
      case ApiKeyProvider.DEEPSEEK:
        return this.checkDeepSeek(apiKey, baseUrl);
      case ApiKeyProvider.GEMINI:
        return this.checkGemini(apiKey, baseUrl);
      case ApiKeyProvider.GROK:
        return this.checkGrok(apiKey, baseUrl);
      default:
        return this.checkGeneric(apiKey, baseUrl);
    }
  }

  private async checkOpenAI(apiKey: string, baseUrl?: string): Promise<{ responseTime: number; details: any }> {
    const url = (baseUrl || 'https://api.openai.com/v1').replace(/\/$/, '') + '/models';
    const startTime = Date.now();

    try {
      const response = await firstValueFrom(
        this.httpService.get(url, {
          headers: { Authorization: `Bearer ${apiKey}` },
          timeout: 10000,
        }),
      );

      return {
        responseTime: Date.now() - startTime,
        details: {
          provider: 'openai',
          status: response.status,
          modelsAvailable: response.data?.data?.length || 0,
        },
      };
    } catch (error: any) {
      if (error.response?.status === 401) {
        throw new Error('OpenAI API Key 无效或已过期');
      }
      throw new Error(`OpenAI API 连接失败: ${error.message}`);
    }
  }

  private async checkAnthropic(apiKey: string, baseUrl?: string): Promise<{ responseTime: number; details: any }> {
    const url = (baseUrl || 'https://api.anthropic.com/v1').replace(/\/$/, '') + '/messages';
    const startTime = Date.now();

    try {
      await firstValueFrom(
        this.httpService.post(url, {
          model: 'claude-3-haiku-20240307',
          max_tokens: 1,
          messages: [{ role: 'user', content: 'hi' }],
        }, {
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
          timeout: 10000,
        }),
      );

      return {
        responseTime: Date.now() - startTime,
        details: {
          provider: 'anthropic',
          status: 200,
          note: '使用 messages API 验证',
        },
      };
    } catch (error: any) {
      if (error.response?.status === 401) {
        throw new Error('Anthropic API Key 无效或已过期');
      }
      if (error.response?.status === 400 || error.response?.status === 429) {
        return {
          responseTime: Date.now() - startTime,
          details: {
            provider: 'anthropic',
            status: error.response.status,
            note: 'API Key 有效，但请求被限制（正常）',
          },
        };
      }
      throw new Error(`Anthropic API 连接失败: ${error.message}`);
    }
  }

  private async checkQwen(apiKey: string, baseUrl?: string): Promise<{ responseTime: number; details: any }> {
    const url = (baseUrl || 'https://dashscope.aliyuncs.com/compatible-mode/v1').replace(/\/$/, '') + '/chat/completions';
    const startTime = Date.now();

    try {
      await firstValueFrom(
        this.httpService.post(url, {
          model: 'qwen-turbo',
          messages: [{ role: 'user', content: 'hi' }],
          max_tokens: 1,
        }, {
          headers: {
            Authorization: `Bearer ${apiKey}`,
            'Content-Type': 'application/json',
          },
          timeout: 10000,
        }),
      );

      return {
        responseTime: Date.now() - startTime,
        details: {
          provider: 'qwen',
          status: 200,
          note: '使用 chat/completions API 验证',
        },
      };
    } catch (error: any) {
      if (error.response?.status === 401) {
        throw new Error('通义千问 API Key 无效或已过期');
      }
      if (error.response?.status === 400 || error.response?.status === 429) {
        return {
          responseTime: Date.now() - startTime,
          details: {
            provider: 'qwen',
            status: error.response.status,
            note: 'API Key 有效，但请求被限制（正常）',
          },
        };
      }
      throw new Error(`通义千问 API 连接失败: ${error.message}`);
    }
  }

  private async checkDeepSeek(apiKey: string, baseUrl?: string): Promise<{ responseTime: number; details: any }> {
    const url = (baseUrl || 'https://api.deepseek.com/v1').replace(/\/$/, '') + '/chat/completions';
    const startTime = Date.now();

    try {
      await firstValueFrom(
        this.httpService.post(url, {
          model: 'deepseek-chat',
          messages: [{ role: 'user', content: 'hi' }],
          max_tokens: 1,
        }, {
          headers: {
            Authorization: `Bearer ${apiKey}`,
            'Content-Type': 'application/json',
          },
          timeout: 10000,
        }),
      );

      return {
        responseTime: Date.now() - startTime,
        details: {
          provider: 'deepseek',
          status: 200,
          note: '使用 chat/completions API 验证',
        },
      };
    } catch (error: any) {
      if (error.response?.status === 401) {
        throw new Error('DeepSeek API Key 无效或已过期');
      }
      if (error.response?.status === 400 || error.response?.status === 429) {
        return {
          responseTime: Date.now() - startTime,
          details: {
            provider: 'deepseek',
            status: error.response.status,
            note: 'API Key 有效，但请求被限制（正常）',
          },
        };
      }
      throw new Error(`DeepSeek API 连接失败: ${error.message}`);
    }
  }

  private async checkGemini(apiKey: string, baseUrl?: string): Promise<{ responseTime: number; details: any }> {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
    const startTime = Date.now();

    try {
      await firstValueFrom(
        this.httpService.post(url, {
          contents: [{ parts: [{ text: 'hi' }] }],
        }, {
          timeout: 10000,
        }),
      );

      return {
        responseTime: Date.now() - startTime,
        details: {
          provider: 'gemini',
          status: 200,
          note: '使用 generateContent API 验证',
        },
      };
    } catch (error: any) {
      if (error.response?.status === 400 && error.response?.data?.error?.message?.includes('API key')) {
        throw new Error('Gemini API Key 无效或已过期');
      }
      if (error.response?.status === 429) {
        return {
          responseTime: Date.now() - startTime,
          details: {
            provider: 'gemini',
            status: 429,
            note: 'API Key 有效，但请求被限制（正常）',
          },
        };
      }
      throw new Error(`Gemini API 连接失败: ${error.message}`);
    }
  }

  private async checkGrok(apiKey: string, baseUrl?: string): Promise<{ responseTime: number; details: any }> {
    const url = (baseUrl || 'https://api.x.ai/v1').replace(/\/$/, '') + '/chat/completions';
    const startTime = Date.now();

    try {
      await firstValueFrom(
        this.httpService.post(url, {
          model: 'grok-2',
          messages: [{ role: 'user', content: 'hi' }],
          max_tokens: 1,
        }, {
          headers: {
            Authorization: `Bearer ${apiKey}`,
            'Content-Type': 'application/json',
          },
          timeout: 10000,
        }),
      );

      return {
        responseTime: Date.now() - startTime,
        details: {
          provider: 'grok',
          status: 200,
          note: '使用 chat/completions API 验证',
        },
      };
    } catch (error: any) {
      if (error.response?.status === 401) {
        throw new Error('Grok API Key 无效或已过期');
      }
      if (error.response?.status === 400 || error.response?.status === 429) {
        return {
          responseTime: Date.now() - startTime,
          details: {
            provider: 'grok',
            status: error.response.status,
            note: 'API Key 有效，但请求被限制（正常）',
          },
        };
      }
      throw new Error(`Grok API 连接失败: ${error.message}`);
    }
  }

  private async checkGeneric(apiKey: string, baseUrl?: string): Promise<{ responseTime: number; details: any }> {
    if (!baseUrl) {
      throw new Error('自定义 provider 需要提供 baseUrl');
    }

    const startTime = Date.now();

    try {
      const response = await firstValueFrom(
        this.httpService.get(baseUrl, {
          headers: { Authorization: `Bearer ${apiKey}` },
          timeout: 10000,
        }),
      );

      return {
        responseTime: Date.now() - startTime,
        details: {
          provider: 'custom',
          status: response.status,
          baseUrl,
        },
      };
    } catch (error: any) {
      if (error.response?.status === 401) {
        throw new Error('自定义 API Key 无效或已过期');
      }
      throw new Error(`自定义 API 连接失败: ${error.message}`);
    }
  }
}
