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
exports.PackageBillingStrategy = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const subscription_entity_1 = require("../../entities/subscription.entity");
const user_feature_usage_entity_1 = require("../../entities/user-feature-usage.entity");
const plan_feature_quota_entity_1 = require("../../entities/plan-feature-quota.entity");
let PackageBillingStrategy = class PackageBillingStrategy {
    constructor(subscriptionRepo, featureUsageRepo, planFeatureQuotaRepo) {
        this.subscriptionRepo = subscriptionRepo;
        this.featureUsageRepo = featureUsageRepo;
        this.planFeatureQuotaRepo = planFeatureQuotaRepo;
    }
    async canUse(userId, featureType, amount) {
        const packages = await this.getActivePackages(userId);
        for (const pkg of packages) {
            const usage = await this.getFeatureUsage(userId, pkg.id, featureType);
            if (usage && (usage.usedAmount + amount) <= usage.totalAmount) {
                return true;
            }
        }
        return false;
    }
    async consume(userId, featureType, amount) {
        const packages = await this.getActivePackages(userId);
        for (const pkg of packages) {
            const usage = await this.getFeatureUsage(userId, pkg.id, featureType);
            if (usage && (usage.usedAmount + amount) <= usage.totalAmount) {
                usage.usedAmount += amount;
                await this.featureUsageRepo.save(usage);
                if (usage.usedAmount >= usage.totalAmount) {
                    pkg.status = 'expired';
                    await this.subscriptionRepo.save(pkg);
                }
                return {
                    success: true,
                    consumed: amount,
                    remaining: usage.totalAmount - usage.usedAmount,
                };
            }
        }
        return { success: false, consumed: 0, remaining: 0, message: '无有效资源包' };
    }
    async getRemaining(userId, featureType) {
        const packages = await this.getActivePackages(userId);
        let total = 0;
        for (const pkg of packages) {
            const usage = await this.getFeatureUsage(userId, pkg.id, featureType);
            if (usage) {
                total += (usage.totalAmount - usage.usedAmount);
            }
        }
        return total;
    }
    async getActivePackages(userId) {
        return this.subscriptionRepo.find({
            where: {
                userId,
                type: 'package',
                status: 'active',
            },
            order: { createdAt: 'ASC' },
        });
    }
    async getFeatureUsage(userId, subscriptionId, featureType) {
        let usage = await this.featureUsageRepo.findOne({
            where: { userId, subscriptionId, featureType },
        });
        if (!usage) {
            const subscription = await this.subscriptionRepo.findOne({ where: { id: subscriptionId } });
            if (!subscription)
                return null;
            const quota = await this.planFeatureQuotaRepo.findOne({
                where: { planId: subscription.planId, featureType },
            });
            if (!quota)
                return null;
            usage = this.featureUsageRepo.create({
                userId,
                subscriptionId,
                featureType,
                usedAmount: 0,
                totalAmount: quota.quotaValue,
                unit: quota.quotaUnit,
            });
            await this.featureUsageRepo.save(usage);
        }
        return usage;
    }
};
exports.PackageBillingStrategy = PackageBillingStrategy;
exports.PackageBillingStrategy = PackageBillingStrategy = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(subscription_entity_1.Subscription)),
    __param(1, (0, typeorm_1.InjectRepository)(user_feature_usage_entity_1.UserFeatureUsage)),
    __param(2, (0, typeorm_1.InjectRepository)(plan_feature_quota_entity_1.PlanFeatureQuota)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], PackageBillingStrategy);
//# sourceMappingURL=package-billing.strategy.js.map