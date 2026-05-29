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
exports.SubscriptionService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const subscription_entity_1 = require("./entities/subscription.entity");
const plan_entity_1 = require("./entities/plan.entity");
const user_balance_entity_1 = require("./entities/user-balance.entity");
const recharge_record_entity_1 = require("./entities/recharge-record.entity");
const plan_api_policy_entity_1 = require("./entities/plan-api-policy.entity");
const api_usage_log_entity_1 = require("./entities/api-usage-log.entity");
const plan_default_config_entity_1 = require("./entities/plan-default-config.entity");
const plan_feature_quota_entity_1 = require("./entities/plan-feature-quota.entity");
const user_feature_usage_entity_1 = require("./entities/user-feature-usage.entity");
const plan_service_1 = require("../plan/plan.service");
const billing_strategy_factory_1 = require("./billing/billing-strategy.factory");
let SubscriptionService = class SubscriptionService {
    constructor(subscriptionRepository, planRepository, userBalanceRepository, rechargeRecordRepository, planApiPolicyRepository, apiUsageLogRepository, planDefaultConfigRepository, planFeatureQuotaRepository, userFeatureUsageRepository, planService, billingStrategyFactory) {
        this.subscriptionRepository = subscriptionRepository;
        this.planRepository = planRepository;
        this.userBalanceRepository = userBalanceRepository;
        this.rechargeRecordRepository = rechargeRecordRepository;
        this.planApiPolicyRepository = planApiPolicyRepository;
        this.apiUsageLogRepository = apiUsageLogRepository;
        this.planDefaultConfigRepository = planDefaultConfigRepository;
        this.planFeatureQuotaRepository = planFeatureQuotaRepository;
        this.userFeatureUsageRepository = userFeatureUsageRepository;
        this.planService = planService;
        this.billingStrategyFactory = billingStrategyFactory;
    }
    async getSubscription(userId) {
        const subscription = await this.subscriptionRepository.findOne({
            where: { userId, status: 'active' },
            order: { expiresAt: 'DESC' },
        });
        const userBalance = await this.userBalanceRepository.findOne({
            where: { userId },
        });
        if (!subscription) {
            return {
                code: 200,
                message: 'success',
                data: {
                    planId: 'free',
                    planName: '免费版',
                    status: 'active',
                    expiresAt: null,
                    totalQuota: 30,
                    usedQuota: 0,
                    remainingQuota: 30,
                    balanceCents: userBalance?.balanceCents || 0,
                },
            };
        }
        const plan = await this.planRepository.findOne({
            where: { id: subscription.planId },
        });
        const remainingQuota = subscription.totalQuota - subscription.usedQuota;
        const apiPolicies = await this.planApiPolicyRepository.find({
            where: { planId: subscription.planId },
        });
        const defaultConfigs = await this.planDefaultConfigRepository.find({
            where: { planId: subscription.planId, isActive: true },
        });
        return {
            code: 200,
            message: 'success',
            data: {
                planId: subscription.planId,
                planName: plan?.name || '未知套餐',
                status: subscription.status,
                expiresAt: subscription.expiresAt,
                totalQuota: subscription.totalQuota,
                usedQuota: subscription.usedQuota,
                remainingQuota: Math.max(0, remainingQuota),
                balanceCents: userBalance?.balanceCents || 0,
                apiPolicies: apiPolicies
                    .filter(p => p.isAllowed && p.modelPattern)
                    .map(p => {
                    const parts = p.modelPattern.split(':');
                    const modelProvider = parts.length > 1 ? parts[0] : p.provider;
                    const modelName = parts.length > 1 ? parts.slice(1).join(':') : p.modelPattern;
                    return {
                        provider: modelProvider,
                        model: modelName,
                        modelPattern: p.modelPattern,
                        multiplier: Number(p.multiplier),
                        isAllowed: p.isAllowed,
                    };
                }),
                defaultConfigs: defaultConfigs.map(c => ({
                    functionType: c.functionType,
                    modelPattern: c.modelPattern,
                })),
            },
        };
    }
    async getPlans(type) {
        const plans = await this.planService.getPlans(false);
        return {
            code: 200,
            message: 'success',
            data: plans,
        };
    }
    async createSubscription(userId, planId) {
        const plan = await this.planRepository.findOne({
            where: { id: planId },
        });
        if (!plan) {
            return {
                code: 400,
                message: '套餐不存在',
                data: null,
            };
        }
        const userBalance = await this.userBalanceRepository.findOne({
            where: { userId },
        });
        if (userBalance && userBalance.balanceCents >= plan.priceCents) {
            userBalance.balanceCents -= plan.priceCents;
            await this.userBalanceRepository.save(userBalance);
        }
        const now = new Date();
        const expiresAt = new Date(now.getTime() + plan.durationDays * 24 * 60 * 60 * 1000);
        await this.subscriptionRepository.update({ userId, status: 'active' }, { status: 'expired' });
        const subscription = this.subscriptionRepository.create({
            userId,
            planId,
            status: 'active',
            startedAt: now,
            expiresAt,
            totalQuota: plan.quotaValue || 0,
            usedQuota: 0,
        });
        await this.subscriptionRepository.save(subscription);
        return {
            code: 200,
            message: '订阅创建成功',
            data: subscription,
        };
    }
    async createPlan(dto) {
        const existingPlan = await this.planService.getPlanById(dto.id);
        if (existingPlan) {
            return {
                code: 400,
                message: '套餐ID已存在',
                data: null,
            };
        }
        const plan = await this.planService.createPlan({
            id: dto.id,
            name: dto.name,
            description: dto.description,
            priceCents: dto.priceCents,
            durationDays: dto.durationDays,
            features: dto.features || [],
            isRecommended: dto.isRecommended || false,
            quotaType: dto.quotaType,
            quotaValue: dto.quotaValue,
            isActive: dto.isActive ?? true,
            allowedModels: dto.allowedModels || [],
        });
        return {
            code: 200,
            message: '套餐创建成功',
            data: plan,
        };
    }
    async useQuota(userId, amount) {
        const subscription = await this.subscriptionRepository.findOne({
            where: { userId, status: 'active' },
        });
        if (!subscription) {
            const defaultQuota = 30;
            if (amount > defaultQuota) {
                throw new common_1.BadRequestException('配额不足');
            }
            return {
                code: 200,
                message: 'success',
                data: {
                    planId: 'free',
                    usedQuota: amount,
                    remainingQuota: defaultQuota - amount,
                },
            };
        }
        const remainingQuota = subscription.totalQuota - subscription.usedQuota;
        if (remainingQuota < amount) {
            throw new common_1.BadRequestException('配额不足');
        }
        subscription.usedQuota += amount;
        await this.subscriptionRepository.save(subscription);
    }
    async updateQuotaUsage(userId, amount) {
        const subscription = await this.subscriptionRepository.findOne({
            where: { userId, status: 'active' },
        });
        if (!subscription) {
            throw new common_1.BadRequestException('无有效订阅');
        }
        const remainingQuota = subscription.totalQuota - subscription.usedQuota;
        if (remainingQuota < amount) {
            throw new common_1.BadRequestException('配额不足');
        }
        subscription.usedQuota += amount;
        await this.subscriptionRepository.save(subscription);
        return {
            code: 200,
            message: 'success',
            data: {
                usedQuota: subscription.usedQuota,
                remainingQuota: subscription.totalQuota - subscription.usedQuota,
            },
        };
        return {
            code: 200,
            message: '配额使用成功',
            data: {
                planId: subscription.planId,
                usedQuota: subscription.usedQuota,
                remainingQuota: subscription.totalQuota - subscription.usedQuota,
            },
        };
    }
    async getBalance(userId) {
        const userBalance = await this.userBalanceRepository.findOne({
            where: { userId },
        });
        return {
            code: 200,
            message: 'success',
            data: {
                balanceCents: userBalance?.balanceCents || 0,
                totalRechargedCents: userBalance?.totalRechargedCents || 0,
                totalRefundedCents: userBalance?.totalRefundedCents || 0,
            },
        };
    }
    async recharge(userId, dto) {
        let userBalance = await this.userBalanceRepository.findOne({
            where: { userId },
        });
        if (!userBalance) {
            userBalance = this.userBalanceRepository.create({
                userId,
                balanceCents: 0,
                totalRechargedCents: 0,
                totalRefundedCents: 0,
            });
        }
        userBalance.balanceCents += dto.amountCents;
        userBalance.totalRechargedCents += dto.amountCents;
        await this.userBalanceRepository.save(userBalance);
        const record = this.rechargeRecordRepository.create({
            userId,
            amountCents: dto.amountCents,
            type: 'recharge',
            paymentMethod: dto.paymentMethod,
            status: 'completed',
        });
        await this.rechargeRecordRepository.save(record);
        return {
            code: 200,
            message: '充值成功',
            data: {
                balanceCents: userBalance.balanceCents,
                amountCents: dto.amountCents,
            },
        };
    }
    async refund(userId, dto) {
        const userBalance = await this.userBalanceRepository.findOne({
            where: { userId },
        });
        if (!userBalance || userBalance.balanceCents < dto.amountCents) {
            throw new common_1.BadRequestException('余额不足，无法退款');
        }
        userBalance.balanceCents -= dto.amountCents;
        userBalance.totalRefundedCents += dto.amountCents;
        await this.userBalanceRepository.save(userBalance);
        const record = this.rechargeRecordRepository.create({
            userId,
            amountCents: dto.amountCents,
            type: 'refund',
            status: 'completed',
            remark: dto.reason,
        });
        await this.rechargeRecordRepository.save(record);
        return {
            code: 200,
            message: '退款成功',
            data: {
                balanceCents: userBalance.balanceCents,
                amountCents: dto.amountCents,
            },
        };
    }
    async getRechargeRecords(userId) {
        const records = await this.rechargeRecordRepository.find({
            where: { userId },
            order: { createdAt: 'DESC' },
        });
        return {
            code: 200,
            message: 'success',
            data: records,
        };
    }
    async createTrialSubscription(userId, trialData) {
        let trialPlan = await this.planRepository.findOne({ where: { id: trialData.planId } });
        if (!trialPlan) {
            trialPlan = this.planRepository.create({
                id: trialData.planId,
                name: trialData.planName,
                description: '新用户注册赠送',
                priceCents: 0,
                durationDays: 7,
                quotaType: 'minutes',
                quotaValue: trialData.totalQuota,
                isActive: true,
            });
            await this.planRepository.save(trialPlan);
        }
        const subscription = this.subscriptionRepository.create({
            userId,
            planId: trialData.planId,
            status: 'active',
            startedAt: new Date(),
            expiresAt: trialData.expiresAt,
            totalQuota: trialData.totalQuota,
            usedQuota: trialData.usedQuota,
        });
        await this.subscriptionRepository.save(subscription);
        return subscription;
    }
    async initUserBalance(userId) {
        const existing = await this.userBalanceRepository.findOne({
            where: { userId },
        });
        if (!existing) {
            const userBalance = this.userBalanceRepository.create({
                userId,
                balanceCents: 0,
                totalRechargedCents: 0,
                totalRefundedCents: 0,
            });
            await this.userBalanceRepository.save(userBalance);
        }
    }
    async getPlanApiPolicies(planId) {
        return this.planApiPolicyRepository.find({
            where: { planId },
        });
    }
    async setPlanApiPolicy(planId, provider, multiplier, modelPattern) {
        const searchPattern = modelPattern || '*';
        let policy = await this.planApiPolicyRepository.findOne({
            where: { planId, provider, modelPattern: searchPattern },
        });
        if (policy) {
            policy.multiplier = multiplier;
        }
        else {
            policy = this.planApiPolicyRepository.create({
                planId,
                provider,
                multiplier,
                modelPattern: searchPattern,
                isAllowed: true,
            });
        }
        return this.planApiPolicyRepository.save(policy);
    }
    async deletePlanApiPolicy(policyId) {
        await this.planApiPolicyRepository.delete(policyId);
    }
    async calculateQuotaConsumption(userId, provider, model) {
        const subscription = await this.subscriptionRepository.findOne({
            where: { userId, status: 'active' },
            order: { expiresAt: 'DESC' },
        });
        if (!subscription) {
            return 1;
        }
        const policies = await this.planApiPolicyRepository.find({
            where: { planId: subscription.planId },
        });
        const policy = policies.find(p => {
            if (p.provider !== provider && p.provider !== 'all')
                return false;
            if (!p.modelPattern)
                return true;
            const pattern = p.modelPattern.replace('*', '.*');
            const regex = new RegExp(`^${pattern}$`);
            return regex.test(model);
        });
        return policy ? policy.multiplier : 1;
    }
    async consumeQuotaWithApi(userId, provider, model, tokens) {
        const multiplier = await this.calculateQuotaConsumption(userId, provider, model);
        const consumed = Math.ceil(multiplier);
        const subscription = await this.subscriptionRepository.findOne({
            where: { userId, status: 'active' },
            order: { expiresAt: 'DESC' },
        });
        const log = this.apiUsageLogRepository.create({
            userId,
            subscriptionId: subscription?.id,
            provider,
            model,
            promptTokens: tokens?.prompt || 0,
            completionTokens: tokens?.completion || 0,
            quotaConsumed: consumed,
        });
        await this.apiUsageLogRepository.save(log);
        if (subscription) {
            subscription.usedQuota += consumed;
            subscription.balanceQuota = Math.max(0, subscription.totalQuota - subscription.usedQuota);
            await this.subscriptionRepository.save(subscription);
        }
        return {
            consumed,
            multiplier,
            remaining: subscription ? subscription.balanceQuota : 0,
        };
    }
    async canUseApi(userId, provider, model) {
        const subscription = await this.subscriptionRepository.findOne({
            where: { userId, status: 'active' },
            order: { expiresAt: 'DESC' },
        });
        if (!subscription) {
            const domesticProviders = ['qwen', 'deepseek'];
            if (!domesticProviders.includes(provider)) {
                return { allowed: false, reason: '免费用户仅可使用国产API，请升级套餐' };
            }
            return { allowed: true };
        }
        if (new Date() > subscription.expiresAt) {
            return { allowed: false, reason: '套餐已过期，请续费' };
        }
        if (subscription.balanceQuota <= 0) {
            return { allowed: false, reason: '配额已用完，请充值或升级套餐' };
        }
        const policies = await this.planApiPolicyRepository.find({
            where: { planId: subscription.planId },
        });
        if (policies.length === 0) {
            return { allowed: true };
        }
        const allowed = policies.some(p => {
            if (p.provider === 'all')
                return true;
            if (p.provider !== provider)
                return false;
            if (!p.modelPattern)
                return p.isAllowed;
            const pattern = p.modelPattern.replace('*', '.*');
            const regex = new RegExp(`^${pattern}$`);
            return regex.test(model) && p.isAllowed;
        });
        if (!allowed) {
            return { allowed: false, reason: '当前套餐不支持使用该API，请升级套餐' };
        }
        return { allowed: true };
    }
    async canUseFeature(userId, featureType, amount) {
        const strategy = await this.billingStrategyFactory.getStrategy(userId, featureType);
        const canUse = await strategy.canUse(userId, featureType, amount);
        if (!canUse) {
            return { canUse: false, reason: '配额不足或余额不足' };
        }
        return { canUse: true };
    }
    async consumeFeature(userId, featureType, amount, metadata) {
        const strategy = await this.billingStrategyFactory.getStrategy(userId, featureType);
        const result = await strategy.consume(userId, featureType, amount, metadata);
        return result;
    }
    async getFeatureRemaining(userId, featureType) {
        const strategy = await this.billingStrategyFactory.getStrategy(userId, featureType);
        return strategy.getRemaining(userId, featureType);
    }
    async getFeatureUsage(userId) {
        const featureTypes = ['transcription', 'realtime_transcription', 'text_analysis', 'image_recognition', 'ocr', 'ai_chat', 'tts'];
        const usage = {};
        for (const featureType of featureTypes) {
            const remaining = await this.getFeatureRemaining(userId, featureType);
            usage[featureType] = {
                remaining,
                unit: this.getFeatureUnit(featureType),
            };
        }
        return usage;
    }
    getFeatureUnit(featureType) {
        const unitMap = {
            transcription: 'minutes',
            realtime_transcription: 'minutes',
            text_analysis: 'thousand_chars',
            image_recognition: 'images',
            ocr: 'images',
            ai_chat: 'tokens',
            tts: 'thousand_chars',
        };
        return unitMap[featureType] || 'unknown';
    }
    async purchaseWithBalance(userId, planId) {
        const plan = await this.planService.getPlanById(planId);
        if (!plan) {
            return { success: false, message: '套餐不存在' };
        }
        const balance = await this.userBalanceRepository.findOne({ where: { userId } });
        if (!balance || balance.balanceCents < plan.priceCents) {
            return { success: false, message: '余额不足' };
        }
        balance.balanceCents -= plan.priceCents;
        await this.userBalanceRepository.save(balance);
        const subscription = await this.createSubscription(userId, planId);
        await this.rechargeRecordRepository.save({
            userId,
            amountCents: -plan.priceCents,
            paymentMethod: 'balance_conversion',
            status: 'success',
            remark: `余额购买套餐: ${plan.name}`,
        });
        return { success: true, message: '购买成功', subscription: subscription.data };
    }
};
exports.SubscriptionService = SubscriptionService;
exports.SubscriptionService = SubscriptionService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(subscription_entity_1.Subscription)),
    __param(1, (0, typeorm_1.InjectRepository)(plan_entity_1.Plan)),
    __param(2, (0, typeorm_1.InjectRepository)(user_balance_entity_1.UserBalance)),
    __param(3, (0, typeorm_1.InjectRepository)(recharge_record_entity_1.RechargeRecord)),
    __param(4, (0, typeorm_1.InjectRepository)(plan_api_policy_entity_1.PlanApiPolicy)),
    __param(5, (0, typeorm_1.InjectRepository)(api_usage_log_entity_1.ApiUsageLog)),
    __param(6, (0, typeorm_1.InjectRepository)(plan_default_config_entity_1.PlanDefaultConfig)),
    __param(7, (0, typeorm_1.InjectRepository)(plan_feature_quota_entity_1.PlanFeatureQuota)),
    __param(8, (0, typeorm_1.InjectRepository)(user_feature_usage_entity_1.UserFeatureUsage)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        plan_service_1.PlanService,
        billing_strategy_factory_1.BillingStrategyFactory])
], SubscriptionService);
//# sourceMappingURL=subscription.service.js.map