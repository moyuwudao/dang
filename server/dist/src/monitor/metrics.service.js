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
var MetricsService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.MetricsService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const api_usage_log_entity_1 = require("../subscription/entities/api-usage-log.entity");
const redis_service_1 = require("../redis/redis.service");
let MetricsService = MetricsService_1 = class MetricsService {
    constructor(apiUsageLogRepository, redisService) {
        this.apiUsageLogRepository = apiUsageLogRepository;
        this.redisService = redisService;
        this.logger = new common_1.Logger(MetricsService_1.name);
    }
    async getRealtimeMetrics() {
        const now = new Date();
        const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);
        const recentLogs = await this.apiUsageLogRepository.find({
            where: {
                createdAt: new Date(oneHourAgo),
            },
            order: { createdAt: 'DESC' },
            take: 1000,
        });
        const totalCalls = recentLogs.length;
        const totalTokens = recentLogs.reduce((sum, log) => sum + log.promptTokens + log.completionTokens, 0);
        const totalQuotaConsumed = recentLogs.reduce((sum, log) => sum + log.quotaConsumed, 0);
        const callsByProvider = {};
        recentLogs.forEach(log => {
            callsByProvider[log.provider] = (callsByProvider[log.provider] || 0) + 1;
        });
        const callsByHour = {};
        recentLogs.forEach(log => {
            const hour = log.createdAt.getHours().toString().padStart(2, '0') + ':00';
            callsByHour[hour] = (callsByHour[hour] || 0) + 1;
        });
        return {
            totalCalls,
            totalTokens,
            totalQuotaConsumed,
            avgResponseTime: 0,
            errorRate: 0,
            callsByProvider,
            callsByHour,
        };
    }
    async getDailyMetrics(date = new Date()) {
        const startOfDay = new Date(date.getFullYear(), date.getMonth(), date.getDate());
        const endOfDay = new Date(date.getFullYear(), date.getMonth(), date.getDate() + 1);
        const logs = await this.apiUsageLogRepository.find({
            where: {
                createdAt: new Date(startOfDay),
            },
        });
        const totalCalls = logs.length;
        const totalTokens = logs.reduce((sum, log) => sum + log.promptTokens + log.completionTokens, 0);
        const totalQuota = logs.reduce((sum, log) => sum + log.quotaConsumed, 0);
        const providerStats = {};
        logs.forEach(log => {
            if (!providerStats[log.provider]) {
                providerStats[log.provider] = { calls: 0, tokens: 0, quota: 0 };
            }
            providerStats[log.provider].calls++;
            providerStats[log.provider].tokens += log.promptTokens + log.completionTokens;
            providerStats[log.provider].quota += log.quotaConsumed;
        });
        return {
            date: startOfDay.toISOString().split('T')[0],
            totalCalls,
            totalTokens,
            totalQuotaConsumed: totalQuota,
            providerStats,
        };
    }
    async getTrendData(days = 7) {
        const result = [];
        const now = new Date();
        for (let i = days - 1; i >= 0; i--) {
            const date = new Date(now.getTime() - i * 24 * 60 * 60 * 1000);
            const metrics = await this.getDailyMetrics(date);
            result.push(metrics);
        }
        return result;
    }
    async recordResponseTime(duration) {
        const key = `metrics:response_time:${new Date().toISOString().split('T')[0]}`;
        await this.redisService.increment(key, Math.round(duration));
        await this.redisService.expire(key, 86400);
    }
    async recordError(provider, errorType) {
        const key = `metrics:error:${provider}:${new Date().toISOString().split('T')[0]}`;
        await this.redisService.increment(key, 1);
        await this.redisService.expire(key, 86400);
    }
};
exports.MetricsService = MetricsService;
exports.MetricsService = MetricsService = MetricsService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(api_usage_log_entity_1.ApiUsageLog)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        redis_service_1.RedisService])
], MetricsService);
//# sourceMappingURL=metrics.service.js.map