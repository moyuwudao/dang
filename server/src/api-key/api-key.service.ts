import { Injectable, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiKey } from './entities/api-key.entity';
import { UserApiKey } from './entities/user-api-key.entity';

@Injectable()
export class ApiKeyService {
  constructor(
    @InjectRepository(ApiKey)
    private apiKeyRepository: Repository<ApiKey>,
    @InjectRepository(UserApiKey)
    private userApiKeyRepository: Repository<UserApiKey>,
  ) {}

  async getApiKey(userId: string) {
    // 检查用户是否有有效的 API Key 分配
    const existingAssignment = await this.userApiKeyRepository.findOne({
      where: { userId, isActive: true },
      order: { assignedAt: 'DESC' },
    });

    if (existingAssignment && existingAssignment.expiresAt > new Date()) {
      // 返回已分配的 Key
      const apiKey = await this.apiKeyRepository.findOne({
        where: { id: existingAssignment.apiKeyId },
      });

      if (apiKey && apiKey.isActive) {
        return {
          code: 200,
          message: 'success',
          data: {
            provider: apiKey.provider,
            apiKey: apiKey.apiKeyEncrypted, // 实际应解密
            model: apiKey.model,
            expiresAt: existingAssignment.expiresAt,
          },
        };
      }
    }

    // 分配新的 API Key
    return this.assignNewKey(userId);
  }

  async refreshApiKey(userId: string) {
    // 使旧 Key 失效
    await this.userApiKeyRepository.update(
      { userId, isActive: true },
      { isActive: false },
    );

    // 分配新 Key
    return this.assignNewKey(userId);
  }

  private async assignNewKey(userId: string) {
    // 从 Key 池中获取一个可用的 Key
    const availableKey = await this.apiKeyRepository.findOne({
      where: { isActive: true },
    });

    if (!availableKey) {
      throw new ForbiddenException('API Key 池已耗尽，请联系管理员');
    }

    // 创建分配记录
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 1); // 1 小时过期

    const assignment = this.userApiKeyRepository.create({
      userId,
      apiKeyId: availableKey.id,
      assignedAt: new Date(),
      expiresAt,
      isActive: true,
    });

    await this.userApiKeyRepository.save(assignment);

    return {
      code: 200,
      message: 'success',
      data: {
        provider: availableKey.provider,
        apiKey: availableKey.apiKeyEncrypted, // 实际应解密
        model: availableKey.model,
        expiresAt,
      },
    };
  }
}
