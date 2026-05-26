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
let SubscriptionService = class SubscriptionService {
    constructor(subscriptionRepository, planRepository, userBalanceRepository, rechargeRecordRepository) {
        this.subscriptionRepository = subscriptionRepository;
        this.planRepository = planRepository;
        this.userBalanceRepository = userBalanceRepository;
        this.rechargeRecordRepository = rechargeRecordRepository;
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
            },
        };
    }
    async getPlans(type) {
        const where = { isActive: true };
        const plans = await this.planRepository.find({ where });
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
        const existingPlan = await this.planRepository.findOne({
            where: { id: dto.id },
        });
        if (existingPlan) {
            return {
                code: 400,
                message: '套餐ID已存在',
                data: null,
            };
        }
        const plan = this.planRepository.create({
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
        });
        await this.planRepository.save(plan);
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
};
exports.SubscriptionService = SubscriptionService;
exports.SubscriptionService = SubscriptionService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(subscription_entity_1.Subscription)),
    __param(1, (0, typeorm_1.InjectRepository)(plan_entity_1.Plan)),
    __param(2, (0, typeorm_1.InjectRepository)(user_balance_entity_1.UserBalance)),
    __param(3, (0, typeorm_1.InjectRepository)(recharge_record_entity_1.RechargeRecord)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], SubscriptionService);
//# sourceMappingURL=subscription.service.js.map