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
var ApiKeyHealthService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.ApiKeyHealthService = void 0;
const common_1 = require("@nestjs/common");
const schedule_1 = require("@nestjs/schedule");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const api_key_entity_1 = require("./entities/api-key.entity");
const api_key_service_1 = require("./api-key.service");
let ApiKeyHealthService = ApiKeyHealthService_1 = class ApiKeyHealthService {
    constructor(apiKeyRepository, apiKeyService) {
        this.apiKeyRepository = apiKeyRepository;
        this.apiKeyService = apiKeyService;
        this.logger = new common_1.Logger(ApiKeyHealthService_1.name);
    }
    async checkAllApiKeysHealth() {
        this.logger.log('开始检查所有 API Key 健康状态');
        const keys = await this.apiKeyRepository.find({
            where: { status: api_key_entity_1.ApiKeyStatus.ACTIVE },
        });
        for (const key of keys) {
            try {
                await this.apiKeyService.testApiKey(key.id);
                this.logger.log(`API Key ${key.name} (${key.provider}) 健康检查通过`);
            }
            catch (error) {
                this.logger.error(`API Key ${key.name} (${key.provider}) 健康检查失败: ${error.message}`);
            }
        }
        this.logger.log('API Key 健康检查完成');
    }
    async getHealthyKeys(provider) {
        const where = {
            status: api_key_entity_1.ApiKeyStatus.ACTIVE,
            lastHealthCheckStatus: 'healthy',
        };
        if (provider) {
            where.provider = provider;
        }
        return this.apiKeyRepository.find({ where });
    }
    async getOptimalKey(provider) {
        const keys = await this.getHealthyKeys(provider);
        if (keys.length === 0) {
            return null;
        }
        return keys.sort((a, b) => {
            const usageA = a.dailyUsage / (a.dailyQuota || 1);
            const usageB = b.dailyUsage / (b.dailyQuota || 1);
            return usageA - usageB;
        })[0];
    }
};
exports.ApiKeyHealthService = ApiKeyHealthService;
__decorate([
    (0, schedule_1.Cron)(schedule_1.CronExpression.EVERY_5_MINUTES),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ApiKeyHealthService.prototype, "checkAllApiKeysHealth", null);
exports.ApiKeyHealthService = ApiKeyHealthService = ApiKeyHealthService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(api_key_entity_1.ApiKey)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        api_key_service_1.ApiKeyService])
], ApiKeyHealthService);
//# sourceMappingURL=api-key-health.service.js.map