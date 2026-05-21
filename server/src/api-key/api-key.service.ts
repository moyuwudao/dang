import { Injectable, ForbiddenException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiKey } from './entities/api-key.entity';
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

      if (apiKey && apiKey.isActive) {
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
    
    const apiKey = this.apiKeyRepository.create({
      provider: dto.provider,
      apiKeyEncrypted: encryptedKey,
      model: dto.model,
      rateLimitPerMin: dto.rateLimitPerMin ?? 60,
      isActive: dto.isActive ?? true,
    });

    await this.apiKeyRepository.save(apiKey);

    return {
      code: 200,
      message: 'API Key 创建成功',
      data: {
        id: apiKey.id,
        provider: apiKey.provider,
        model: apiKey.model,
        isActive: apiKey.isActive,
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
        model: k.model,
        isActive: k.isActive,
        rateLimitPerMin: k.rateLimitPerMin,
        createdAt: k.createdAt,
      })),
    };
  }

  async deleteApiKey(id: string) {
    await this.apiKeyRepository.delete(id);
    return {
      code: 200,
      message: 'API Key 删除成功',
      data: null,
    };
  }

  private async assignNewKey(userId: string) {
    const availableKey = await this.apiKeyRepository.findOne({
      where: { isActive: true },
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
}
