import { Injectable, ForbiddenException, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiKey, ApiKeyProvider, ApiKeyStatus } from './entities/api-key.entity';
import { UserApiKey } from './entities/user-api-key.entity';
import { CreateApiKeyDto } from './dto';
import { CryptoUtil } from '../common/crypto.util';

@Injectable()
export class ApiKeyService {
  constructor(
    @InjectRepository(ApiKey)
    private apiKeyRepository: Repository<ApiKey>,
    @InjectRepository(UserApiKey)
    private userApiKeyRepository: Repository<UserApiKey>,
  ) {}

  async getApiKey(userId: string) {
    const existingAssignment = await this.userApiKeyRepository.findOne({
      where: { userId, isActive: true },
      order: { assignedAt: 'DESC' },
    });

    if (existingAssignment && existingAssignment.expiresAt > new Date()) {
      const apiKey = await this.apiKeyRepository.findOne({
        where: { id: existingAssignment.apiKeyId },
      });

      if (apiKey && apiKey.status === ApiKeyStatus.ACTIVE) {
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

    return this.assignNewKey(userId);
  }

  async refreshApiKey(userId: string) {
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
      scopes: dto.scopes ?? ['all'],
      rateLimitPerMin: dto.rateLimitPerMin ?? 60,
      maxConcurrentRequests: dto.maxConcurrentRequests ?? 5,
      dailyQuota: dto.dailyQuota ?? 1000,
      expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : null,
      isDefault: dto.isDefault ?? false,
      allowedIpRanges: dto.allowedIpRanges,
    });

    await this.apiKeyRepository.save(apiKey);

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

    Object.assign(apiKey, {
      ...dto,
      apiKeyEncrypted: apiKey.apiKeyEncrypted,
      apiSecretEncrypted: apiKey.apiSecretEncrypted,
    });

    await this.apiKeyRepository.save(apiKey);

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

  private async assignNewKey(userId: string) {
    const availableKey = await this.apiKeyRepository.findOne({
      where: { status: ApiKeyStatus.ACTIVE },
    });

    if (!availableKey) {
      throw new ForbiddenException('API Key 池已耗尽，请联系管理员');
    }

    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24); // 24小时过期

    const assignment = this.userApiKeyRepository.create({
      userId,
      apiKeyId: availableKey.id,
      assignedAt: new Date(),
      expiresAt,
      isActive: true,
    });

    await this.userApiKeyRepository.save(assignment);

    const decryptedKey = CryptoUtil.decrypt(availableKey.apiKeyEncrypted);

    return {
      code: 200,
      message: 'success',
      data: {
        provider: availableKey.provider,
        apiKey: decryptedKey,
        model: availableKey.model,
        rateLimitPerMin: availableKey.rateLimitPerMin,
        expiresAt,
      },
    };
  }

  private async performHealthCheck(provider: string, apiKey: string, baseUrl?: string): Promise<{ responseTime: number; details: any }> {
    const startTime = Date.now();
    
    // 这里实现各平台的连通性测试逻辑
    // 后续可以根据需要扩展
    
    return {
      responseTime: Date.now() - startTime,
      details: {
        provider,
        timestamp: new Date().toISOString(),
      },
    };
  }
}
