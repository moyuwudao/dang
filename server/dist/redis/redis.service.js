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
exports.RedisService = void 0;
const common_1 = require("@nestjs/common");
const ioredis_1 = require("@nestjs-modules/ioredis");
const ioredis_2 = require("ioredis");
let RedisService = class RedisService {
    constructor(redis) {
        this.redis = redis;
    }
    async get(key) {
        return this.redis.get(key);
    }
    async set(key, value, ttl) {
        if (ttl) {
            await this.redis.setex(key, ttl, value);
        }
        else {
            await this.redis.set(key, value);
        }
    }
    async del(key) {
        await this.redis.del(key);
    }
    async increment(key, amount = 1) {
        return this.redis.incrby(key, amount);
    }
    async decrement(key, amount = 1) {
        return this.redis.decrby(key, amount);
    }
    async expire(key, seconds) {
        await this.redis.expire(key, seconds);
    }
    async ttl(key) {
        return this.redis.ttl(key);
    }
    async exists(key) {
        const result = await this.redis.exists(key);
        return result === 1;
    }
    async rateLimit(key, limit, windowSeconds) {
        const current = await this.redis.incr(key);
        if (current === 1) {
            await this.redis.expire(key, windowSeconds);
        }
        const ttl = await this.redis.ttl(key);
        const allowed = current <= limit;
        const remaining = Math.max(0, limit - current);
        return {
            allowed,
            remaining,
            resetTime: Date.now() + ttl * 1000,
        };
    }
};
exports.RedisService = RedisService;
exports.RedisService = RedisService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, ioredis_1.InjectRedis)()),
    __metadata("design:paramtypes", [ioredis_2.default])
], RedisService);
//# sourceMappingURL=redis.service.js.map