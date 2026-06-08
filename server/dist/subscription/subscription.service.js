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
const user_token_balance_entity_1 = require("./entities/user-token-balance.entity");
const recharge_record_entity_1 = require("./entities/recharge-record.entity");
const api_usage_log_entity_1 = require("./entities/api-usage-log.entity");
const plan_service_1 = require("../plan/plan.service");
const token_billing_service_1 = require("./services/token-billing.service");
let SubscriptionService = class SubscriptionService {
    constructor(subscriptionRepository, planRepository, userTokenBalanceRepository, rechargeRecordRepository, apiUsageLogRepository, planService, tokenBillingService) {
        this.subscriptionRepository = subscriptionRepository;
        this.planRepository = planRepository;
        this.userTokenBalanceRepository = userTokenBalanceRepository;
        this.rechargeRecordRepository = rechargeRecordRepository;
        this.apiUsageLogRepository = apiUsageLogRepository;
        this.planService = planService;
        this.tokenBillingService = tokenBillingService;
    }
    pickApiPolicies(plan) {
        const allowedModels = Array.isArray(plan?.allowedModels) ? plan.allowedModels : [];
        if (allowedModels.length > 0) {
            return this.deriveApiPoliciesFromPlan(plan);
        }
        if (Array.isArray(plan?.apiPolicies) && plan.apiPolicies.length > 0) {
            return plan.apiPolicies
                .filter((p) => p && p.isAllowed !== false)
                .map((p) => ({
                provider: String(p.provider || ''),
                model: p.model ? String(p.model) : (p.modelPattern ? String(p.modelPattern).split(':').pop() : ''),
                modelPattern: p.modelPattern ? String(p.modelPattern) : (p.model ? String(p.model) : ''),
                multiplier: typeof p.multiplier === 'number' ? p.multiplier : Number(p.multiplier || 1),
                isAllowed: p.isAllowed !== false,
            }));
        }
        return [];
    }
    buildDefaultConfigsArray(defaultConfigs, apiPolicies = []) {
        if (!defaultConfigs || typeof defaultConfigs !== 'object')
            return [];
        const providerByModel = new Map();
        for (const p of apiPolicies) {
            const model = p?.model || p?.modelPattern;
            if (model) {
                providerByModel.set(String(model), String(p.provider || 'alibabaQwen'));
            }
        }
        return Object.entries(defaultConfigs)
            .filter(([k, v]) => !!k && !!v)
            .map(([functionType, modelValue]) => {
            const modelPattern = modelValue.includes(':')
                ? modelValue
                : `${providerByModel.get(modelValue) || 'alibabaQwen'}:${modelValue}`;
            return { functionType, modelPattern };
        });
    }
    deriveApiPoliciesFromPlan(plan) {
        const allowedModels = Array.isArray(plan?.allowedModels) ? plan.allowedModels : [];
        const apiPolicies = Array.isArray(plan?.apiPolicies) ? plan.apiPolicies : [];
        const policyByModel = new Map();
        for (const p of apiPolicies) {
            const key = p?.model || p?.modelPattern;
            if (key)
                policyByModel.set(String(key), p);
        }
        return allowedModels.map((m) => {
            const found = policyByModel.get(String(m));
            return {
                provider: found?.provider ? String(found.provider) : 'alibabaQwen',
                model: String(m),
                modelPattern: found?.modelPattern ? String(found.modelPattern) : String(m),
                multiplier: typeof found?.multiplier === 'number' ? found.multiplier : 1.0,
                isAllowed: found?.isAllowed !== false,
            };
        });
    }
    async getSubscription(userId) {
        const subscriptions = await this.subscriptionRepository.find({
            where: { userId, status: 'active' },
            order: { expiresAt: 'DESC' },
        });
        const tokenBalance = await this.userTokenBalanceRepository.findOne({
            where: { userId },
        });
        if (subscriptions.length === 0) {
            return {
                code: 200,
                message: 'success',
                data: {
                    planId: 'free',
                    planName: '免费版',
                    status: 'active',
                    expiresAt: null,
                    tokenQuota: 0,
                    usedTokens: 0,
                    totalQuota: 0,
                    usedQuota: 0,
                    quotaRemaining: 0,
                    balanceTokens: tokenBalance?.balanceTokens || 0,
                    freeTokensRemaining: 0,
                    apiPolicies: [],
                    defaultConfigs: this.buildDefaultConfigsArray({}),
                    subscriptions: [],
                },
            };
        }
        const activeSub = subscriptions[0];
        const plan = await this.planRepository.findOne({ where: { id: activeSub.planId } });
        const planData = plan ? this.normalizePlan(plan) : null;
        const allSubscriptions = [];
        for (const sub of subscriptions) {
            const subPlan = await this.planRepository.findOne({ where: { id: sub.planId } });
            if (!subPlan)
                continue;
            const subPlanData = this.normalizePlan(subPlan);
            allSubscriptions.push({
                subscriptionId: sub.id,
                planId: sub.planId,
                planName: subPlanData.name,
                expiresAt: this.computeExpiresAt(sub.startedAt, subPlanData.durationDays, sub.expiresAt),
                startedAt: sub.startedAt,
                status: sub.status,
                defaultConfigs: this.buildDefaultConfigsArray(subPlanData.defaultConfigs, subPlanData.apiPolicies),
                apiPolicies: this.pickApiPolicies(subPlanData),
                allowedModels: subPlanData.allowedModels || [],
            });
        }
        return {
            code: 200,
            message: 'success',
            data: {
                planId: activeSub.planId,
                planName: planData?.name || '未知套餐',
                status: activeSub.status,
                expiresAt: this.computeExpiresAt(activeSub.startedAt, planData?.durationDays, activeSub.expiresAt),
                totalQuota: activeSub.totalQuota,
                usedQuota: activeSub.usedQuota,
                quotaRemaining: activeSub.totalQuota - activeSub.usedQuota,
                rechargeBalance: Number(tokenBalance?.balanceTokens) || 0,
                balanceTokens: Number(tokenBalance?.balanceTokens) || 0,
                freeTokensRemaining: Number(tokenBalance?.freeTokensRemaining) || 0,
                apiPolicies: planData ? this.pickApiPolicies(planData) : [],
                defaultConfigs: planData ? this.buildDefaultConfigsArray(planData.defaultConfigs, planData.apiPolicies) : [],
                subscriptions: allSubscriptions,
            },
        };
    }
    computeExpiresAt(startedAt, planDurationDays, fallback) {
        if (!startedAt || !planDurationDays || planDurationDays <= 0) {
            return fallback;
        }
        return new Date(new Date(startedAt).getTime() + planDurationDays * 24 * 60 * 60 * 1000);
    }
    normalizePlan(plan) {
        return {
            ...plan,
            allowedModels: plan.allowedModels
                ? String(plan.allowedModels).split(',').map((s) => s.trim()).filter(Boolean)
                : [],
            defaultConfigs: plan.defaultConfigs || {},
            apiPolicies: Array.isArray(plan.apiPolicies) ? plan.apiPolicies : [],
        };
    }
    async getSubscriptionById(userId, subscriptionId) {
        const subscription = await this.subscriptionRepository.findOne({
            where: { id: subscriptionId, userId, status: 'active' },
        });
        if (!subscription) {
            return {
                code: 404,
                message: '订阅不存在或已过期',
                data: null,
            };
        }
        const plan = await this.planRepository.findOne({ where: { id: subscription.planId } });
        const planData = plan ? this.normalizePlan(plan) : null;
        const tokenBalance = await this.userTokenBalanceRepository.findOne({ where: { userId } });
        return {
            code: 200,
            message: 'success',
            data: {
                subscriptionId: subscription.id,
                planId: subscription.planId,
                planName: planData?.name || '未知套餐',
                status: subscription.status,
                expiresAt: this.computeExpiresAt(subscription.startedAt, planData?.durationDays, subscription.expiresAt),
                totalQuota: subscription.totalQuota,
                usedQuota: subscription.usedQuota,
                balanceTokens: tokenBalance?.balanceTokens || 0,
                freeTokensRemaining: tokenBalance?.freeTokensRemaining || 0,
                apiPolicies: planData ? this.pickApiPolicies(planData) : [],
                defaultConfigs: planData ? this.buildDefaultConfigsArray(planData.defaultConfigs, planData.apiPolicies) : [],
                allowedModels: planData?.allowedModels || [],
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
        const now = new Date();
        const expiresAt = new Date(now.getTime() + plan.durationDays * 24 * 60 * 60 * 1000);
        await this.subscriptionRepository.update({ userId, status: 'active' }, { status: 'expired' });
        const subscription = this.subscriptionRepository.create({
            userId,
            planId,
            status: 'active',
            startedAt: now,
            expiresAt,
            totalQuota: plan.tokenQuota || 0,
            usedQuota: 0,
            type: plan.type || 'monthly',
        });
        await this.subscriptionRepository.save(subscription);
        if (plan.type === 'recharge' && plan.tokenQuota) {
            let balance = await this.userTokenBalanceRepository.findOne({ where: { userId } });
            if (!balance) {
                balance = this.userTokenBalanceRepository.create({
                    userId,
                    totalTokens: plan.tokenQuota,
                    usedTokens: 0,
                    balanceTokens: plan.tokenQuota,
                    freeTokensRemaining: 0,
                });
            }
            else {
                balance.totalTokens += plan.tokenQuota;
                balance.balanceTokens += plan.tokenQuota;
            }
            await this.userTokenBalanceRepository.save(balance);
        }
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
            tokenQuota: dto.tokenQuota,
            durationDays: dto.durationDays,
            type: dto.type || 'monthly',
            isActive: dto.isActive ?? true,
            allowedModels: Array.isArray(dto.allowedModels)
                ? dto.allowedModels.filter((m) => m).join(',')
                : (dto.allowedModels || ''),
        });
        return {
            code: 200,
            message: '套餐创建成功',
            data: plan,
        };
    }
    async rechargeTokens(userId, dto) {
        const globalPricePerToken = 0.01;
        const tokens = Math.floor(dto.amountCents / 100 / globalPricePerToken);
        let balance = await this.userTokenBalanceRepository.findOne({ where: { userId } });
        if (!balance) {
            balance = this.userTokenBalanceRepository.create({
                userId,
                totalTokens: tokens,
                usedTokens: 0,
                balanceTokens: tokens,
                freeTokensRemaining: 0,
            });
        }
        else {
            balance.totalTokens += tokens;
            balance.balanceTokens += tokens;
        }
        await this.userTokenBalanceRepository.save(balance);
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
                tokensAdded: tokens,
                balanceTokens: balance.balanceTokens,
                amountCents: dto.amountCents,
            },
        };
    }
    async getBalance(userId) {
        const balance = await this.tokenBillingService.getOrCreateBalance(userId);
        const activeSubscriptions = await this.subscriptionRepository.find({
            where: { userId, status: 'active' },
        });
        let totalQuota = 0;
        let usedQuota = 0;
        for (const sub of activeSubscriptions) {
            const plan = await this.planRepository.findOne({ where: { id: sub.planId } });
            if (plan && plan.type === 'monthly') {
                totalQuota += sub.totalQuota;
                usedQuota += sub.usedQuota;
            }
        }
        return {
            code: 200,
            message: 'success',
            data: {
                totalQuota,
                usedQuota,
                quotaRemaining: totalQuota - usedQuota,
                rechargeBalance: Number(balance.balanceTokens) || 0,
                balanceTokens: Number(balance.balanceTokens) || 0,
                freeTokensRemaining: Number(balance.freeTokensRemaining) || 0,
                totalTokens: Number(balance.totalTokens) || 0,
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
                tokenQuota: trialData.totalQuota,
                type: 'monthly',
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
            type: 'monthly',
        });
        await this.subscriptionRepository.save(subscription);
        return subscription;
    }
};
exports.SubscriptionService = SubscriptionService;
exports.SubscriptionService = SubscriptionService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(subscription_entity_1.Subscription)),
    __param(1, (0, typeorm_1.InjectRepository)(plan_entity_1.Plan)),
    __param(2, (0, typeorm_1.InjectRepository)(user_token_balance_entity_1.UserTokenBalance)),
    __param(3, (0, typeorm_1.InjectRepository)(recharge_record_entity_1.RechargeRecord)),
    __param(4, (0, typeorm_1.InjectRepository)(api_usage_log_entity_1.ApiUsageLog)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        plan_service_1.PlanService,
        token_billing_service_1.TokenBillingService])
], SubscriptionService);
//# sourceMappingURL=subscription.service.js.map