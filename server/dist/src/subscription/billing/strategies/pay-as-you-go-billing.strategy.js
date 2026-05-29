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
exports.PayAsYouGoBillingStrategy = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const user_balance_entity_1 = require("../../entities/user-balance.entity");
const token_pricing_entity_1 = require("../../entities/token-pricing.entity");
const api_usage_log_entity_1 = require("../../entities/api-usage-log.entity");
let PayAsYouGoBillingStrategy = class PayAsYouGoBillingStrategy {
    constructor(balanceRepo, pricingRepo, usageLogRepo) {
        this.balanceRepo = balanceRepo;
        this.pricingRepo = pricingRepo;
        this.usageLogRepo = usageLogRepo;
    }
    async canUse(userId, featureType, amount) {
        const balance = await this.balanceRepo.findOne({ where: { userId } });
        if (!balance || balance.balanceCents <= 0)
            return false;
        const estimatedCost = await this.calculateCost(featureType, amount);
        return balance.balanceCents >= estimatedCost;
    }
    async consume(userId, featureType, amount, metadata) {
        const balance = await this.balanceRepo.findOne({ where: { userId } });
        if (!balance) {
            return { success: false, consumed: 0, remaining: 0, message: '余额不足' };
        }
        const costCents = await this.calculateCost(featureType, amount, metadata);
        if (balance.balanceCents < costCents) {
            return { success: false, consumed: 0, remaining: balance.balanceCents, message: '余额不足' };
        }
        balance.balanceCents -= costCents;
        await this.balanceRepo.save(balance);
        await this.usageLogRepo.save({
            userId,
            provider: metadata?.provider || 'unknown',
            model: metadata?.model || 'unknown',
            featureType,
            resourceConsumed: amount,
            costCents,
            promptTokens: metadata?.promptTokens,
            completionTokens: metadata?.completionTokens,
            totalTokens: metadata?.totalTokens,
        });
        return {
            success: true,
            consumed: amount,
            remaining: balance.balanceCents,
            costCents,
        };
    }
    async getRemaining(userId) {
        const balance = await this.balanceRepo.findOne({ where: { userId } });
        return balance?.balanceCents || 0;
    }
    async calculateCost(featureType, amount, metadata) {
        switch (featureType) {
            case 'ai_chat':
                return this.calculateTokenCost(metadata?.provider, metadata?.model, metadata?.promptTokens, metadata?.completionTokens);
            case 'transcription':
                return Math.ceil(amount * 5);
            case 'realtime_transcription':
                return Math.ceil(amount * 8);
            case 'text_analysis':
                return Math.ceil(amount * 2);
            case 'image_recognition':
                return Math.ceil(amount * 10);
            case 'ocr':
                return Math.ceil(amount * 5);
            case 'tts':
                return Math.ceil(amount * 3);
            default:
                return 0;
        }
    }
    async calculateTokenCost(provider, model, promptTokens, completionTokens) {
        const pricing = await this.pricingRepo.findOne({
            where: { provider, modelPattern: model, isActive: true },
        });
        if (!pricing) {
            return Math.ceil((promptTokens + completionTokens) * 0.01);
        }
        const promptCost = (promptTokens / 1000) * pricing.promptPricePer1k;
        const completionCost = (completionTokens / 1000) * pricing.completionPricePer1k;
        return Math.ceil(promptCost + completionCost);
    }
};
exports.PayAsYouGoBillingStrategy = PayAsYouGoBillingStrategy;
exports.PayAsYouGoBillingStrategy = PayAsYouGoBillingStrategy = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(user_balance_entity_1.UserBalance)),
    __param(1, (0, typeorm_1.InjectRepository)(token_pricing_entity_1.TokenPricing)),
    __param(2, (0, typeorm_1.InjectRepository)(api_usage_log_entity_1.ApiUsageLog)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], PayAsYouGoBillingStrategy);
//# sourceMappingURL=pay-as-you-go-billing.strategy.js.map