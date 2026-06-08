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
exports.TokenBillingService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const api_config_entity_1 = require("../entities/api-config.entity");
const token_pricing_entity_1 = require("../entities/token-pricing.entity");
const user_token_balance_entity_1 = require("../entities/user-token-balance.entity");
const api_usage_log_entity_1 = require("../entities/api-usage-log.entity");
const subscription_entity_1 = require("../entities/subscription.entity");
const plan_entity_1 = require("../entities/plan.entity");
let TokenBillingService = class TokenBillingService {
    constructor(apiConfigRepo, pricingRepo, balanceRepo, usageLogRepo, subscriptionRepo, planRepo) {
        this.apiConfigRepo = apiConfigRepo;
        this.pricingRepo = pricingRepo;
        this.balanceRepo = balanceRepo;
        this.usageLogRepo = usageLogRepo;
        this.subscriptionRepo = subscriptionRepo;
        this.planRepo = planRepo;
    }
    async consumeToken(userId, metadata) {
        const { provider, model, rawAmount } = metadata;
        const apiConfig = await this.apiConfigRepo.findOne({
            where: { provider, modelPattern: model, isActive: true },
        });
        const coefficient = apiConfig?.baseCoefficient ?? 1.0;
        const tokenConsumed = Math.ceil(rawAmount * coefficient);
        const pricing = await this.pricingRepo.findOne({
            where: { provider, modelPattern: model, isActive: true },
        });
        const pricePerToken = pricing?.pricePerToken ?? 0.002;
        const costYuan = tokenConsumed * pricePerToken;
        const activeSubscriptions = await this.subscriptionRepo.find({
            where: { userId, status: 'active' },
            order: { expiresAt: 'ASC' },
        });
        let remaining = tokenConsumed;
        let quotaRemaining = 0;
        for (const sub of activeSubscriptions) {
            if (remaining <= 0)
                break;
            const plan = await this.planRepo.findOne({ where: { id: sub.planId } });
            if (plan && plan.type === 'monthly') {
                const available = sub.totalQuota - sub.usedQuota;
                if (available > 0) {
                    const deduct = Math.min(remaining, available);
                    sub.usedQuota += deduct;
                    remaining -= deduct;
                    await this.subscriptionRepo.save(sub);
                }
            }
        }
        let totalMonthlyQuotaRemaining = 0;
        for (const sub of activeSubscriptions) {
            const plan = await this.planRepo.findOne({ where: { id: sub.planId } });
            if (plan && plan.type === 'monthly') {
                totalMonthlyQuotaRemaining += Math.max(0, sub.totalQuota - sub.usedQuota);
            }
        }
        quotaRemaining = totalMonthlyQuotaRemaining;
        let rechargeRemaining = 0;
        if (remaining > 0) {
            const balance = await this.getOrCreateBalance(userId);
            if (balance.balanceTokens >= remaining) {
                balance.balanceTokens -= remaining;
                balance.usedTokens += remaining;
                balance.totalTokens += tokenConsumed;
                await this.balanceRepo.save(balance);
                remaining = 0;
            }
            else {
                return {
                    success: false,
                    tokenConsumed: 0,
                    costYuan: 0,
                    quotaRemaining,
                    rechargeRemaining: Number(balance.balanceTokens) || 0,
                    message: '套餐配额和充值余额不足，请购买套餐或充值',
                };
            }
            rechargeRemaining = Number(balance.balanceTokens) || 0;
        }
        else {
            const balance = await this.getOrCreateBalance(userId);
            balance.totalTokens += tokenConsumed;
            await this.balanceRepo.save(balance);
            rechargeRemaining = Number(balance.balanceTokens) || 0;
        }
        await this.usageLogRepo.save({
            userId,
            provider,
            model,
            promptTokens: metadata.promptTokens || 0,
            completionTokens: metadata.completionTokens || 0,
            tokenConsumed,
            apiCoefficient: coefficient,
            costYuan,
            createdAt: new Date(),
        });
        return {
            success: true,
            tokenConsumed,
            costYuan,
            quotaRemaining,
            rechargeRemaining,
        };
    }
    async getOrCreateBalance(userId) {
        let balance = await this.balanceRepo.findOne({
            where: { userId },
        });
        if (!balance) {
            balance = this.balanceRepo.create({
                userId,
                totalTokens: 0,
                usedTokens: 0,
                balanceTokens: 0,
                freeTokensRemaining: 0,
            });
            await this.balanceRepo.save(balance);
        }
        return balance;
    }
    async rechargeTokens(userId, tokens) {
        const balance = await this.getOrCreateBalance(userId);
        balance.balanceTokens += tokens;
        balance.totalTokens += tokens;
        return this.balanceRepo.save(balance);
    }
    async getBalance(userId) {
        const balance = await this.getOrCreateBalance(userId);
        return {
            balanceTokens: Number(balance.balanceTokens) || 0,
            freeTokensRemaining: Number(balance.freeTokensRemaining) || 0,
            totalTokens: Number(balance.totalTokens) || 0,
            usedTokens: Number(balance.usedTokens) || 0,
        };
    }
    async canUse(userId, estimatedTokens) {
        const activeSubscriptions = await this.subscriptionRepo.find({
            where: { userId, status: 'active' },
        });
        let totalQuotaAvailable = 0;
        for (const sub of activeSubscriptions) {
            const plan = await this.planRepo.findOne({ where: { id: sub.planId } });
            if (plan && plan.type === 'monthly') {
                totalQuotaAvailable += Math.max(0, sub.totalQuota - sub.usedQuota);
            }
        }
        if (totalQuotaAvailable >= estimatedTokens)
            return true;
        const balance = await this.getOrCreateBalance(userId);
        const rechargeAvailable = Number(balance.balanceTokens) || 0;
        return (totalQuotaAvailable + rechargeAvailable) >= estimatedTokens;
    }
    async getUsageLogs(userId, limit = 50) {
        return this.usageLogRepo.find({
            where: { userId },
            order: { createdAt: 'DESC' },
            take: limit,
        });
    }
};
exports.TokenBillingService = TokenBillingService;
exports.TokenBillingService = TokenBillingService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(api_config_entity_1.ApiConfig)),
    __param(1, (0, typeorm_1.InjectRepository)(token_pricing_entity_1.TokenPricing)),
    __param(2, (0, typeorm_1.InjectRepository)(user_token_balance_entity_1.UserTokenBalance)),
    __param(3, (0, typeorm_1.InjectRepository)(api_usage_log_entity_1.ApiUsageLog)),
    __param(4, (0, typeorm_1.InjectRepository)(subscription_entity_1.Subscription)),
    __param(5, (0, typeorm_1.InjectRepository)(plan_entity_1.Plan)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], TokenBillingService);
//# sourceMappingURL=token-billing.service.js.map