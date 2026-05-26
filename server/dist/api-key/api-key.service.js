"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ApiKeyService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const api_key_entity_1 = require("./entities/api-key.entity");
const user_api_key_entity_1 = require("./entities/user-api-key.entity");
const crypto_util_1 = require("../common/crypto.util");
let ApiKeyService = class ApiKeyService {
    constructor(apiKeyRepository, userApiKeyRepository) {
        this.apiKeyRepository = apiKeyRepository;
        this.userApiKeyRepository = userApiKeyRepository;
    }
    async getApiKey(userId) {
        const existingAssignment = await this.userApiKeyRepository.findOne({
            where: { userId, isActive: true },
            order: { assignedAt: 'DESC' },
        });
        if (existingAssignment && existingAssignment.expiresAt > new Date()) {
            const apiKey = await this.apiKeyRepository.findOne({
                where: { id: existingAssignment.apiKeyId },
            });
            if (apiKey && apiKey.isActive) {
                const decryptedKey = crypto_util_1.CryptoUtil.decrypt(apiKey.apiKeyEncrypted);
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
    async refreshApiKey(userId) {
        await this.userApiKeyRepository.update({ userId, isActive: true }, { isActive: false });
        return this.assignNewKey(userId);
    }
    async createApiKey(dto) {
        const encryptedKey = crypto_util_1.CryptoUtil.encrypt(dto.apiKey);
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
    async deleteApiKey(id) {
        await this.apiKeyRepository.delete(id);
        return {
            code: 200,
            message: 'API Key 删除成功',
            data: null,
        };
    }
    async assignNewKey(userId) {
        const availableKey = await this.apiKeyRepository.findOne({
            where: { isActive: true },
        });
        if (!availableKey) {
            throw new common_1.ForbiddenException('API Key 池已耗尽，请联系管理员');
        }
        const expiresAt = new Date();
        expiresAt.setHours(expiresAt.getHours() + 24);
        const assignment = this.userApiKeyRepository.create({
            userId,
            apiKeyId: availableKey.id,
            assignedAt: new Date(),
            expiresAt,
            isActive: true,
        });
        await this.userApiKeyRepository.save(assignment);
        const decryptedKey = crypto_util_1.CryptoUtil.decrypt(availableKey.apiKeyEncrypted);
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
};
exports.ApiKeyService = ApiKeyService;
exports.ApiKeyService = ApiKeyService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(api_key_entity_1.ApiKey)),
    __param(1, (0, typeorm_1.InjectRepository)(user_api_key_entity_1.UserApiKey)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository])
], ApiKeyService);
//# sourceMappingURL=api-key.service.js.map