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
let SubscriptionService = class SubscriptionService {
    constructor(subscriptionRepository, planRepository, userTokenBalanceRepository, rechargeRecordRepository, apiUsageLogRepository, planService) {
        this.subscriptionRepository = subscriptionRepository;
        this.planRepository = planRepository;
        this.userTokenBalanceRepository = userTokenBalanceRepository;
        this.rechargeRecordRepository = rechargeRecordRepository;
        this.apiUsageLogRepository = apiUsageLogRepository;
        this.planService = planService;
    }
    async getSubscription(userId) {
        const subscription = await this.subscriptionRepository.findOne({
            where: { userId, status: 'active' },
            order: { expiresAt: 'DESC' },
        });
        const tokenBalance = await this.userTokenBalanceRepository.findOne({
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
                    tokenQuota: 0,
                    usedTokens: 0,
                    balanceTokens: tokenBalance?.balanceTokens || 0,
                    freeTokensRemaining: tokenBalance?.freeTokensRemaining || 500,
                },
            };
        }
        const plan = await this.planRepository.findOne({
            where: { id: subscription.planId },
        });
        return {
            code: 200,
            message: 'success',
            data: {
                planId: subscription.planId,
                planName: plan?.name || '未知套餐',
                status: subscription.status,
                expiresAt: subscription.expiresAt,
                tokenQuota: subscription.tokenQuota,
                usedTokens: subscription.usedTokens,
                balanceTokens: tokenBalance?.balanceTokens || 0,
                freeTokensRemaining: tokenBalance?.freeTokensRemaining || 0,
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
            tokenQuota: plan.tokenQuota || 0,
            usedTokens: 0,
            balanceTokens: plan.tokenQuota || 0,
            type: plan.type || 'monthly',
        });
        await this.subscriptionRepository.save(subscription);
        if (plan.type === 'monthly' && plan.tokenQuota) {
            let balance = await this.userTokenBalanceRepository.findOne({ where: { userId } });
            if (!balance) {
                balance = this.userTokenBalanceRepository.create({
                    userId,
                    totalTokens: plan.tokenQuota,
                    usedTokens: 0,
                    balanceTokens: plan.tokenQuota,
                    freeTokensRemaining: 500,
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
            allowedModels: dto.allowedModels || [],
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
                freeTokensRemaining: 500,
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
        const tokenBalance = await this.userTokenBalanceRepository.findOne({
            where: { userId },
        });
        return {
            code: 200,
            message: 'success',
            data: {
                balanceTokens: tokenBalance?.balanceTokens || 0,
                freeTokensRemaining: tokenBalance?.freeTokensRemaining || 0,
                totalTokens: tokenBalance?.totalTokens || 0,
                usedTokens: tokenBalance?.usedTokens || 0,
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
            tokenQuota: trialData.totalQuota,
            usedTokens: trialData.usedQuota,
            balanceTokens: trialData.totalQuota - trialData.usedQuota,
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
        plan_service_1.PlanService])
], SubscriptionService);
//# sourceMappingURL=subscription.service.js.map