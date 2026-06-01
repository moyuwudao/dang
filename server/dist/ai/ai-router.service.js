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
var AiRouterService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.AiRouterService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const api_key_entity_1 = require("../api-key/entities/api-key.entity");
const redis_service_1 = require("../redis/redis.service");
let AiRouterService = AiRouterService_1 = class AiRouterService {
    constructor(apiKeyRepository, redisService) {
        this.apiKeyRepository = apiKeyRepository;
        this.redisService = redisService;
        this.logger = new common_1.Logger(AiRouterService_1.name);
        this.fallbackProviders = [
            'openai',
            'anthropic',
            'gemini',
            'grok',
            'deepseek',
            'qwen',
        ];
    }
    async selectOptimalKey(strategy) {
        const { provider, model, fallbackEnabled } = strategy;
        if (provider) {
            const key = await this.selectBestKey(provider);
            if (key)
                return key;
            if (fallbackEnabled) {
                this.logger.warn(`Provider ${provider} 不可用，尝试降级`);
                return this.fallbackToNextProvider(provider);
            }
            return null;
        }
        return this.selectBestKeyFromAll();
    }
    async selectBestKey(provider) {
        const keys = await this.apiKeyRepository.find({
            where: {
                provider: provider,
                status: api_key_entity_1.ApiKeyStatus.ACTIVE,
                lastHealthCheckStatus: 'healthy',
            },
        });
        if (keys.length === 0) {
            return null;
        }
        return keys.sort((a, b) => {
            const usageA = a.dailyUsage / (a.dailyQuota || 1);
            const usageB = b.dailyUsage / (b.dailyQuota || 1);
            return usageA - usageB;
        })[0];
    }
    async selectBestKeyFromAll() {
        for (const provider of this.fallbackProviders) {
            const key = await this.selectBestKey(provider);
            if (key)
                return key;
        }
        return null;
    }
    async fallbackToNextProvider(currentProvider) {
        const currentIndex = this.fallbackProviders.indexOf(currentProvider);
        if (currentIndex === -1 || currentIndex >= this.fallbackProviders.length - 1) {
            return null;
        }
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
    async recordKeyUsage(keyId, tokens) {
        const key = await this.apiKeyRepository.findOne({ where: { id: keyId } });
        if (key) {
            key.dailyUsage += tokens;
            key.lastUsedAt = new Date();
            await this.apiKeyRepository.save(key);
        }
    }
    async isKeyAvailable(keyId) {
        const key = await this.apiKeyRepository.findOne({
            where: { id: keyId, status: api_key_entity_1.ApiKeyStatus.ACTIVE },
        });
        if (!key)
            return false;
        if (key.dailyUsage >= key.dailyQuota) {
            return false;
        }
        if (key.lastHealthCheckStatus !== 'healthy') {
            return false;
        }
        return true;
    }
};
exports.AiRouterService = AiRouterService;
exports.AiRouterService = AiRouterService = AiRouterService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(api_key_entity_1.ApiKey)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        redis_service_1.RedisService])
], AiRouterService);
//# sourceMappingURL=ai-router.service.js.map