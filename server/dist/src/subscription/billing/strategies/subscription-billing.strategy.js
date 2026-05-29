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
exports.SubscriptionBillingStrategy = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const subscription_entity_1 = require("../../entities/subscription.entity");
const user_feature_usage_entity_1 = require("../../entities/user-feature-usage.entity");
const plan_feature_quota_entity_1 = require("../../entities/plan-feature-quota.entity");
let SubscriptionBillingStrategy = class SubscriptionBillingStrategy {
    constructor(subscriptionRepo, featureUsageRepo, planFeatureQuotaRepo) {
        this.subscriptionRepo = subscriptionRepo;
        this.featureUsageRepo = featureUsageRepo;
        this.planFeatureQuotaRepo = planFeatureQuotaRepo;
    }
    async canUse(userId, featureType, amount) {
        const subscription = await this.getActiveSubscription(userId);
        if (!subscription)
            return false;
        const featureQuota = await this.getFeatureQuota(subscription.planId, featureType);
        if (!featureQuota)
            return false;
        const usage = await this.getFeatureUsage(userId, subscription.id, featureType);
        return (usage.usedAmount + amount) <= usage.totalAmount;
    }
    async consume(userId, featureType, amount) {
        const subscription = await this.getActiveSubscription(userId);
        if (!subscription) {
            return { success: false, consumed: 0, remaining: 0, message: '无有效订阅' };
        }
        const usage = await this.getFeatureUsage(userId, subscription.id, featureType);
        if (usage.usedAmount + amount > usage.totalAmount) {
            return { success: false, consumed: 0, remaining: usage.totalAmount - usage.usedAmount, message: '配额不足' };
        }
        usage.usedAmount += amount;
        await this.featureUsageRepo.save(usage);
        return {
            success: true,
            consumed: amount,
            remaining: usage.totalAmount - usage.usedAmount,
        };
    }
    async getRemaining(userId, featureType) {
        const subscription = await this.getActiveSubscription(userId);
        if (!subscription)
            return 0;
        const usage = await this.getFeatureUsage(userId, subscription.id, featureType);
        return usage.totalAmount - usage.usedAmount;
    }
    async getActiveSubscription(userId) {
        return this.subscriptionRepo.findOne({
            where: {
                userId,
                type: 'subscription',
                status: 'active',
                expiresAt: (0, typeorm_2.MoreThan)(new Date()),
            },
            order: { expiresAt: 'DESC' },
        });
    }
    async getFeatureQuota(planId, featureType) {
        return this.planFeatureQuotaRepo.findOne({
            where: { planId, featureType },
        });
    }
    async getFeatureUsage(userId, subscriptionId, featureType) {
        let usage = await this.featureUsageRepo.findOne({
            where: { userId, subscriptionId, featureType },
        });
        if (!usage) {
            const subscription = await this.subscriptionRepo.findOne({ where: { id: subscriptionId } });
            const quota = await this.getFeatureQuota(subscription.planId, featureType);
            usage = this.featureUsageRepo.create({
                userId,
                subscriptionId,
                featureType,
                usedAmount: 0,
                totalAmount: quota?.quotaValue || 0,
                unit: quota?.quotaUnit || 'minutes',
            });
            await this.featureUsageRepo.save(usage);
        }
        return usage;
    }
};
exports.SubscriptionBillingStrategy = SubscriptionBillingStrategy;
exports.SubscriptionBillingStrategy = SubscriptionBillingStrategy = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(subscription_entity_1.Subscription)),
    __param(1, (0, typeorm_1.InjectRepository)(user_feature_usage_entity_1.UserFeatureUsage)),
    __param(2, (0, typeorm_1.InjectRepository)(plan_feature_quota_entity_1.PlanFeatureQuota)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], SubscriptionBillingStrategy);
//# sourceMappingURL=subscription-billing.strategy.js.map