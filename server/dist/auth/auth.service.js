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
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const bcrypt = require("bcryptjs");
const ioredis_1 = require("ioredis");
const user_entity_1 = require("./entities/user.entity");
const subscription_service_1 = require("../subscription/subscription.service");
const sms_service_1 = require("./sms.service");
let AuthService = class AuthService {
    constructor(userRepository, jwtService, subscriptionService, smsService) {
        this.userRepository = userRepository;
        this.jwtService = jwtService;
        this.subscriptionService = subscriptionService;
        this.smsService = smsService;
        this.redisClient = new ioredis_1.Redis({
            host: process.env.REDIS_HOST || 'localhost',
            port: parseInt(process.env.REDIS_PORT || '6379'),
            password: process.env.REDIS_PASSWORD,
        });
    }
    async register(dto) {
        const existingUser = await this.userRepository.findOne({
            where: { phone: dto.phone },
        });
        if (existingUser) {
            throw new common_1.BadRequestException('手机号已注册');
        }
        const passwordHash = await bcrypt.hash(dto.password, 12);
        const user = this.userRepository.create({
            phone: dto.phone,
            passwordHash,
        });
        await this.userRepository.save(user);
        await this.subscriptionService.initUserBalance(user.id);
        const now = new Date();
        const expiresAt = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
        await this.subscriptionService.createTrialSubscription(user.id, {
            planId: 'trial',
            planName: '新手体验包',
            totalQuota: 100,
            usedQuota: 0,
            expiresAt,
        });
        const tokens = await this.generateTokens(user);
        return {
            code: 200,
            message: '注册成功',
            data: {
                user: this.sanitizeUser(user),
                ...tokens,
            },
        };
    }
    async login(dto) {
        const user = await this.userRepository.findOne({
            where: { phone: dto.phone },
        });
        if (!user) {
            throw new common_1.UnauthorizedException('手机号或密码错误');
        }
        const isValid = await bcrypt.compare(dto.password, user.passwordHash);
        if (!isValid) {
            throw new common_1.UnauthorizedException('手机号或密码错误');
        }
        if (user.status !== 'active') {
            throw new common_1.UnauthorizedException('账户已被禁用');
        }
        const tokens = await this.generateTokens(user);
        return {
            code: 200,
            message: '登录成功',
            data: {
                user: this.sanitizeUser(user),
                ...tokens,
            },
        };
    }
    async sendSmsCode(phone) {
        const code = Math.floor(100000 + Math.random() * 900000).toString();
        await this.redisClient.set(`sms_code:${phone}`, code, 'EX', 300);
        try {
            await this.smsService.sendVerificationCode(phone);
            return {
                code: 200,
                message: '验证码已发送',
                data: { needCaptcha: false },
            };
        }
        catch {
            return {
                code: 200,
                message: '验证码已发送',
                data: { needCaptcha: false },
            };
        }
    }
    async smsLogin(dto) {
        const storedCode = await this.redisClient.get(`sms_code:${dto.phone}`);
        if (!storedCode) {
            throw new common_1.BadRequestException('验证码已过期，请重新获取');
        }
        if (storedCode !== dto.smsCode) {
            throw new common_1.BadRequestException('验证码错误');
        }
        await this.redisClient.del(`sms_code:${dto.phone}`);
        let user = await this.userRepository.findOne({
            where: { phone: dto.phone },
        });
        if (!user) {
            user = this.userRepository.create({
                phone: dto.phone,
                passwordHash: '',
            });
            await this.userRepository.save(user);
            await this.subscriptionService.initUserBalance(user.id);
            const now = new Date();
            const expiresAt = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
            await this.subscriptionService.createTrialSubscription(user.id, {
                planId: 'trial',
                planName: '新手体验包',
                totalQuota: 100,
                usedQuota: 0,
                expiresAt,
            });
        }
        if (user.status !== 'active') {
            throw new common_1.UnauthorizedException('账户已被禁用');
        }
        const tokens = await this.generateTokens(user);
        return {
            code: 200,
            message: '登录成功',
            data: {
                user: this.sanitizeUser(user),
                ...tokens,
            },
        };
    }
    async refresh(refreshToken) {
        try {
            const payload = this.jwtService.verify(refreshToken, {
                secret: process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET,
            });
            const user = await this.userRepository.findOne({
                where: { id: payload.sub },
            });
            if (!user || user.status !== 'active') {
                throw new common_1.UnauthorizedException('用户不存在或已被禁用');
            }
            return {
                code: 200,
                message: '刷新成功',
                data: await this.generateTokens(user),
            };
        }
        catch {
            throw new common_1.UnauthorizedException('刷新令牌无效');
        }
    }
    async logout(userId) {
        return {
            code: 200,
            message: '登出成功',
            data: null,
        };
    }
    async getProfile(userId) {
        const user = await this.userRepository.findOne({
            where: { id: userId },
        });
        if (!user) {
            throw new common_1.UnauthorizedException('用户不存在');
        }
        return {
            code: 200,
            message: 'success',
            data: this.sanitizeUser(user),
        };
    }
    async updateProfile(userId, dto) {
        await this.userRepository.update(userId, {
            nickname: dto.nickname,
            avatarUrl: dto.avatarUrl,
        });
        return {
            code: 200,
            message: '更新成功',
            data: null,
        };
    }
    async generateTokens(user) {
        const payload = { sub: user.id, phone: user.phone, role: user.role };
        const accessToken = this.jwtService.sign(payload);
        const refreshToken = this.jwtService.sign(payload, {
            secret: process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET,
            expiresIn: '7d',
        });
        return { accessToken, refreshToken };
    }
    sanitizeUser(user) {
        const { passwordHash, ...result } = user;
        return result;
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        jwt_1.JwtService,
        subscription_service_1.SubscriptionService,
        sms_service_1.SmsService])
], AuthService);
//# sourceMappingURL=auth.service.js.map