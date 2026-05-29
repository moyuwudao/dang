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
Object.defineProperty(exports, "__esModule", { value: true });
exports.RedisRateLimitInterceptor = void 0;
const common_1 = require("@nestjs/common");
const redis_service_1 = require("../../redis/redis.service");
let RedisRateLimitInterceptor = class RedisRateLimitInterceptor {
    constructor(redisService) {
        this.redisService = redisService;
    }
    async intercept(context, next) {
        const request = context.switchToHttp().getRequest();
        const user = request.user;
        const userId = user?.sub || user?.userId || 'anonymous';
        const ip = request.ip || request.connection?.remoteAddress || 'unknown';
        const userKey = `rate_limit:user:${userId}`;
        const userLimit = await this.redisService.rateLimit(userKey, 60, 60);
        if (!userLimit.allowed) {
            throw new common_1.HttpException({
                code: 429,
                message: '请求过于频繁，请稍后再试',
                data: {
                    remaining: userLimit.remaining,
                    resetTime: userLimit.resetTime,
                },
            }, 429);
        }
        const ipKey = `rate_limit:ip:${ip}`;
        const ipLimit = await this.redisService.rateLimit(ipKey, 100, 60);
        if (!ipLimit.allowed) {
            throw new common_1.HttpException({
                code: 429,
                message: '该IP请求过于频繁',
                data: {
                    remaining: ipLimit.remaining,
                    resetTime: ipLimit.resetTime,
                },
            }, 429);
        }
        const globalKey = `rate_limit:global`;
        const globalLimit = await this.redisService.rateLimit(globalKey, 1000, 60);
        if (!globalLimit.allowed) {
            throw new common_1.HttpException({
                code: 429,
                message: '系统繁忙，请稍后再试',
                data: {
                    remaining: globalLimit.remaining,
                    resetTime: globalLimit.resetTime,
                },
            }, 429);
        }
        return next.handle();
    }
};
exports.RedisRateLimitInterceptor = RedisRateLimitInterceptor;
exports.RedisRateLimitInterceptor = RedisRateLimitInterceptor = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [redis_service_1.RedisService])
], RedisRateLimitInterceptor);
//# sourceMappingURL=redis-rate-limit.interceptor.js.map