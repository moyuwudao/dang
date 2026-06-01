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
exports.RateLimitInterceptor = void 0;
const common_1 = require("@nestjs/common");
const rxjs_1 = require("rxjs");
const operators_1 = require("rxjs/operators");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const api_key_entity_1 = require("../entities/api-key.entity");
const requestCounters = new Map();
const concurrentRequests = new Map();
let RateLimitInterceptor = class RateLimitInterceptor {
    constructor(apiKeyRepository) {
        this.apiKeyRepository = apiKeyRepository;
    }
    async intercept(context, next) {
        const request = context.switchToHttp().getRequest();
        const apiKeyId = request.headers['x-api-key-id'];
        if (!apiKeyId) {
            return next.handle();
        }
        const apiKey = await this.apiKeyRepository.findOne({
            where: { id: apiKeyId },
        });
        if (!apiKey || apiKey.status !== 'active') {
            return (0, rxjs_1.throwError)(() => new common_1.HttpException('API Key 无效或已停用', 403));
        }
        const rateLimitCheck = this.checkRateLimit(apiKeyId, apiKey.rateLimitPerMin);
        if (!rateLimitCheck.allowed) {
            return (0, rxjs_1.throwError)(() => new common_1.HttpException(`请求过于频繁，请稍后再试。限制：${apiKey.rateLimitPerMin} 请求/分钟`, 429));
        }
        const concurrentCheck = this.checkConcurrentLimit(apiKeyId, apiKey.maxConcurrentRequests);
        if (!concurrentCheck.allowed) {
            return (0, rxjs_1.throwError)(() => new common_1.HttpException(`并发请求过多，请稍后再试。限制：${apiKey.maxConcurrentRequests} 并发`, 429));
        }
        if (apiKey.dailyUsage >= apiKey.dailyQuota) {
            return (0, rxjs_1.throwError)(() => new common_1.HttpException(`日配额已用完。配额：${apiKey.dailyQuota}，已用：${apiKey.dailyUsage}`, 429));
        }
        this.incrementConcurrent(apiKeyId);
        apiKey.lastUsedAt = new Date();
        await this.apiKeyRepository.save(apiKey);
        return next.handle().pipe((0, operators_1.tap)(async () => {
            apiKey.dailyUsage += 1;
            await this.apiKeyRepository.save(apiKey);
        }), (0, operators_1.catchError)(async (error) => {
            this.decrementConcurrent(apiKeyId);
            return (0, rxjs_1.throwError)(() => error);
        }), (0, operators_1.tap)(() => {
            this.decrementConcurrent(apiKeyId);
        }));
    }
    checkRateLimit(apiKeyId, limitPerMin) {
        const now = Date.now();
        const windowMs = 60 * 1000;
        const counter = requestCounters.get(apiKeyId);
        if (!counter || now > counter.resetTime) {
            requestCounters.set(apiKeyId, {
                count: 1,
                resetTime: now + windowMs,
            });
            return { allowed: true };
        }
        if (counter.count >= limitPerMin) {
            return { allowed: false };
        }
        counter.count += 1;
        return { allowed: true };
    }
    checkConcurrentLimit(apiKeyId, maxConcurrent) {
        const current = concurrentRequests.get(apiKeyId) || 0;
        return { allowed: current < maxConcurrent };
    }
    incrementConcurrent(apiKeyId) {
        const current = concurrentRequests.get(apiKeyId) || 0;
        concurrentRequests.set(apiKeyId, current + 1);
    }
    decrementConcurrent(apiKeyId) {
        const current = concurrentRequests.get(apiKeyId) || 0;
        if (current > 0) {
            concurrentRequests.set(apiKeyId, current - 1);
        }
    }
};
exports.RateLimitInterceptor = RateLimitInterceptor;
exports.RateLimitInterceptor = RateLimitInterceptor = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(api_key_entity_1.ApiKey)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], RateLimitInterceptor);
//# sourceMappingURL=rate-limit.interceptor.js.map