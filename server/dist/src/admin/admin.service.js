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
exports.AdminService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const bcrypt = require("bcryptjs");
const user_entity_1 = require("../auth/entities/user.entity");
const subscription_entity_1 = require("../subscription/entities/subscription.entity");
const api_key_entity_1 = require("../api-key/entities/api-key.entity");
const user_balance_entity_1 = require("../subscription/entities/user-balance.entity");
const recharge_record_entity_1 = require("../subscription/entities/recharge-record.entity");
const api_usage_log_entity_1 = require("../subscription/entities/api-usage-log.entity");
const plan_default_config_entity_1 = require("../subscription/entities/plan-default-config.entity");
const plan_feature_quota_entity_1 = require("../subscription/entities/plan-feature-quota.entity");
const token_pricing_entity_1 = require("../subscription/entities/token-pricing.entity");
const billing_standard_entity_1 = require("../subscription/entities/billing-standard.entity");
const plan_api_policy_entity_1 = require("../subscription/entities/plan-api-policy.entity");
const user_feature_usage_entity_1 = require("../subscription/entities/user-feature-usage.entity");
const subscription_service_1 = require("../subscription/subscription.service");
const plan_service_1 = require("../plan/plan.service");
let AdminService = class AdminService {
    constructor(userRepo, subscriptionRepo, apiKeyRepo, balanceRepo, rechargeRepo, apiUsageLogRepo, planDefaultConfigRepo, planFeatureQuotaRepo, tokenPricingRepo, billingStandardRepo, planApiPolicyRepo, userFeatureUsageRepo, subscriptionService, planService) {
        this.userRepo = userRepo;
        this.subscriptionRepo = subscriptionRepo;
        this.apiKeyRepo = apiKeyRepo;
        this.balanceRepo = balanceRepo;
        this.rechargeRepo = rechargeRepo;
        this.apiUsageLogRepo = apiUsageLogRepo;
        this.planDefaultConfigRepo = planDefaultConfigRepo;
        this.planFeatureQuotaRepo = planFeatureQuotaRepo;
        this.tokenPricingRepo = tokenPricingRepo;
        this.billingStandardRepo = billingStandardRepo;
        this.planApiPolicyRepo = planApiPolicyRepo;
        this.userFeatureUsageRepo = userFeatureUsageRepo;
        this.subscriptionService = subscriptionService;
        this.planService = planService;
    }
    async getStats() {
        const [totalUsers, activeSubscriptions, apiKeyCount, totalRevenue,] = await Promise.all([
            this.userRepo.count(),
            this.subscriptionRepo.count({ where: { status: 'active' } }),
            this.apiKeyRepo.count(),
            this.rechargeRepo
                .createQueryBuilder('r')
                .where('r.type = :type', { type: 'recharge' })
                .andWhere('r.status = :status', { status: 'completed' })
                .select('COALESCE(SUM(r.amountCents), 0)', 'sum')
                .getRawOne()
                .then(r => parseInt(r.sum, 10)),
        ]);
        return {
            totalUsers,
            activeSubscriptions,
            apiKeyCount,
            totalRevenue,
        };
    }
    async getUsers(page = 1, limit = 20, search) {
        const qb = this.userRepo.createQueryBuilder('u')
            .leftJoinAndSelect('u.subscriptions', 's')
            .leftJoinAndSelect('u.balance', 'b')
            .orderBy('u.createdAt', 'DESC')
            .skip((page - 1) * limit)
            .take(limit);
        if (search) {
            qb.where('u.phone LIKE :search OR u.nickname LIKE :search OR u.email LIKE :search', {
                search: `%${search}%`,
            });
        }
        const [users, total] = await qb.getManyAndCount();
        return {
            items: users.map(u => ({
                id: u.id,
                phone: u.phone,
                email: u.email,
                nickname: u.nickname,
                status: u.status,
                role: u.role,
                createdAt: u.createdAt,
                subscriptionCount: u.subscriptions?.length || 0,
                balance: u.balance?.balanceCents || 0,
            })),
            total,
            page,
            totalPages: Math.ceil(total / limit),
        };
    }
    async createUser(data) {
        const existingUser = await this.userRepo.findOne({
            where: { phone: data.phone },
        });
        if (existingUser) {
            throw new common_1.BadRequestException('手机号已存在');
        }
        const passwordHash = await bcrypt.hash(data.password, 12);
        const user = this.userRepo.create({
            phone: data.phone,
            passwordHash,
            nickname: data.nickname || '用户',
            role: data.role || 'user',
            status: data.status || 'active',
        });
        await this.userRepo.save(user);
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
        return user;
    }
    async getUserById(userId) {
        return this.userRepo.findOne({ where: { id: userId } });
    }
    async updateUser(userId, data) {
        await this.userRepo.update(userId, data);
        return this.userRepo.findOne({ where: { id: userId } });
    }
    async deleteUser(userId) {
        await this.userRepo.delete(userId);
        return { success: true };
    }
    async getPlans() {
        return this.planService.getPlans(true);
    }
    async createPlan(data) {
        return this.planService.createPlan(data);
    }
    async updatePlan(planId, data) {
        return this.planService.updatePlan(planId, data);
    }
    async deletePlan(planId) {
        return this.planService.deletePlan(planId);
    }
    async getSubscriptions(page = 1, limit = 20, status) {
        const qb = this.subscriptionRepo.createQueryBuilder('s')
            .leftJoinAndSelect('s.user', 'u')
            .leftJoinAndSelect('s.plan', 'p')
            .orderBy('s.createdAt', 'DESC')
            .skip((page - 1) * limit)
            .take(limit);
        if (status) {
            qb.where('s.status = :status', { status });
        }
        const [subscriptions, total] = await qb.getManyAndCount();
        return {
            items: subscriptions.map(s => ({
                id: s.id,
                userId: s.userId,
                userPhone: s.user?.phone,
                userNickname: s.user?.nickname,
                planId: s.planId,
                planName: s.plan?.name,
                status: s.status,
                startedAt: s.startedAt,
                expiresAt: s.expiresAt,
                totalQuota: s.totalQuota,
                usedQuota: s.usedQuota,
                createdAt: s.createdAt,
            })),
            total,
            page,
            totalPages: Math.ceil(total / limit),
        };
    }
    async updateSubscription(subId, data) {
        await this.subscriptionRepo.update(subId, data);
        return this.subscriptionRepo.findOne({ where: { id: subId }, relations: ['user', 'plan'] });
    }
    async getRechargeRecords(page = 1, limit = 20) {
        const [records, total] = await this.rechargeRepo.findAndCount({
            order: { createdAt: 'DESC' },
            skip: (page - 1) * limit,
            take: limit,
            relations: ['user'],
        });
        return {
            items: records.map(r => ({
                id: r.id,
                userId: r.userId,
                userPhone: r.user?.phone,
                amountCents: r.amountCents,
                type: r.type,
                paymentMethod: r.paymentMethod,
                status: r.status,
                remark: r.remark,
                createdAt: r.createdAt,
            })),
            total,
            page,
            totalPages: Math.ceil(total / limit),
        };
    }
    async getUserGrowth(days = 7) {
        const endDate = new Date();
        const startDate = new Date();
        startDate.setDate(startDate.getDate() - days + 1);
        const result = await this.userRepo
            .createQueryBuilder('u')
            .select('DATE(u.createdAt)', 'date')
            .addSelect('COUNT(u.id)', 'count')
            .where('u.createdAt BETWEEN :start AND :end', { start: startDate, end: endDate })
            .groupBy('DATE(u.createdAt)')
            .orderBy('DATE(u.createdAt)', 'ASC')
            .getRawMany();
        const dataMap = new Map();
        result.forEach(r => {
            dataMap.set(r.date, parseInt(r.count, 10));
        });
        const data = [];
        for (let i = 0; i < days; i++) {
            const date = new Date(startDate);
            date.setDate(startDate.getDate() + i);
            const dateStr = date.toISOString().split('T')[0];
            data.push({
                date: dateStr,
                value: dataMap.get(dateStr) || 0,
            });
        }
        return data;
    }
    async assignPlanToUser(userId, planId) {
        const plan = await this.planService.getPlanById(planId);
        if (!plan) {
            throw new common_1.BadRequestException('套餐不存在');
        }
        const user = await this.userRepo.findOne({ where: { id: userId } });
        if (!user) {
            throw new common_1.BadRequestException('用户不存在');
        }
        await this.subscriptionRepo.update({ userId, status: 'active' }, { status: 'expired' });
        const now = new Date();
        const expiresAt = new Date(now.getTime() + plan.durationDays * 24 * 60 * 60 * 1000);
        const subscription = this.subscriptionRepo.create({
            userId,
            planId,
            status: 'active',
            startedAt: now,
            expiresAt,
            totalQuota: plan.quotaValue || 0,
            usedQuota: 0,
        });
        await this.subscriptionRepo.save(subscription);
        return {
            id: subscription.id,
            userId,
            userPhone: user.phone,
            userNickname: user.nickname,
            planId,
            planName: plan.name,
            status: 'active',
            startedAt: now,
            expiresAt,
            totalQuota: plan.quotaValue || 0,
            usedQuota: 0,
        };
    }
    async getRevenueTrend(days = 7) {
        const endDate = new Date();
        const startDate = new Date();
        startDate.setDate(startDate.getDate() - days + 1);
        const result = await this.rechargeRepo
            .createQueryBuilder('r')
            .select('DATE(r.createdAt)', 'date')
            .addSelect('COALESCE(SUM(r.amountCents), 0)', 'count')
            .where('r.createdAt BETWEEN :start AND :end', { start: startDate, end: endDate })
            .andWhere('r.type = :type', { type: 'recharge' })
            .andWhere('r.status = :status', { status: 'completed' })
            .groupBy('DATE(r.createdAt)')
            .orderBy('DATE(r.createdAt)', 'ASC')
            .getRawMany();
        const dataMap = new Map();
        result.forEach(r => {
            dataMap.set(r.date, parseInt(r.count, 10));
        });
        const data = [];
        for (let i = 0; i < days; i++) {
            const date = new Date(startDate);
            date.setDate(startDate.getDate() + i);
            const dateStr = date.toISOString().split('T')[0];
            data.push({
                date: dateStr,
                value: dataMap.get(dateStr) || 0,
            });
        }
        return data;
    }
    async getApiUsageLogs(page = 1, limit = 20, userId, provider) {
        const qb = this.apiUsageLogRepo.createQueryBuilder('log')
            .leftJoinAndSelect('log.user', 'u')
            .orderBy('log.createdAt', 'DESC')
            .skip((page - 1) * limit)
            .take(limit);
        if (userId) {
            qb.where('log.userId = :userId', { userId });
        }
        if (provider) {
            qb.andWhere('log.provider = :provider', { provider });
        }
        const [logs, total] = await qb.getManyAndCount();
        return {
            items: logs.map(log => ({
                id: log.id,
                userId: log.userId,
                userPhone: log.user?.phone,
                provider: log.provider,
                model: log.model,
                promptTokens: log.promptTokens,
                completionTokens: log.completionTokens,
                quotaConsumed: log.quotaConsumed,
                createdAt: log.createdAt,
            })),
            total,
            page,
            totalPages: Math.ceil(total / limit),
        };
    }
    async adjustUserQuota(userId, amount, reason) {
        const user = await this.userRepo.findOne({ where: { id: userId } });
        if (!user) {
            throw new common_1.BadRequestException('用户不存在');
        }
        const subscription = await this.subscriptionRepo.findOne({
            where: { userId, status: 'active' },
        });
        if (!subscription) {
            throw new common_1.BadRequestException('用户无有效订阅');
        }
        subscription.totalQuota += amount;
        await this.subscriptionRepo.save(subscription);
        const record = this.rechargeRepo.create({
            userId,
            amountCents: 0,
            type: 'adjustment',
            status: 'completed',
            remark: reason || `手动调整配额: ${amount > 0 ? '+' : ''}${amount}`,
        });
        await this.rechargeRepo.save(record);
        return {
            userId,
            amount,
            newTotalQuota: subscription.totalQuota,
            newRemainingQuota: subscription.totalQuota - subscription.usedQuota,
        };
    }
    async getRevenueStats(startDate, endDate) {
        const qb = this.rechargeRepo.createQueryBuilder('r')
            .where('r.type = :type', { type: 'recharge' })
            .andWhere('r.status = :status', { status: 'completed' });
        if (startDate) {
            qb.andWhere('r.createdAt >= :start', { start: new Date(startDate) });
        }
        if (endDate) {
            qb.andWhere('r.createdAt <= :end', { end: new Date(endDate) });
        }
        const totalRevenue = await qb
            .clone()
            .select('COALESCE(SUM(r.amountCents), 0)', 'sum')
            .getRawOne()
            .then(r => parseInt(r.sum, 10));
        const totalOrders = await qb
            .clone()
            .getCount();
        const byPaymentMethod = await qb
            .clone()
            .select('r.paymentMethod', 'method')
            .addSelect('COALESCE(SUM(r.amountCents), 0)', 'sum')
            .addSelect('COUNT(r.id)', 'count')
            .groupBy('r.paymentMethod')
            .getRawMany();
        const byDay = await qb
            .clone()
            .select('DATE(r.createdAt)', 'date')
            .addSelect('COALESCE(SUM(r.amountCents), 0)', 'sum')
            .addSelect('COUNT(r.id)', 'count')
            .groupBy('DATE(r.createdAt)')
            .orderBy('DATE(r.createdAt)', 'DESC')
            .limit(30)
            .getRawMany();
        return {
            totalRevenue,
            totalOrders,
            byPaymentMethod: byPaymentMethod.map(r => ({
                method: r.method || 'unknown',
                amount: parseInt(r.sum, 10),
                count: parseInt(r.count, 10),
            })),
            byDay: byDay.map(r => ({
                date: r.date,
                amount: parseInt(r.sum, 10),
                count: parseInt(r.count, 10),
            })),
        };
    }
    async getPlanDefaultConfigs(planId) {
        const configs = await this.planDefaultConfigRepo.find({
            where: { planId },
            order: { functionType: 'ASC' },
        });
        return configs;
    }
    async setPlanDefaultConfig(planId, data) {
        let config = await this.planDefaultConfigRepo.findOne({
            where: { planId, functionType: data.functionType },
        });
        if (config) {
            config.modelPattern = data.modelPattern;
            config.isActive = data.isActive ?? true;
        }
        else {
            config = this.planDefaultConfigRepo.create({
                planId,
                functionType: data.functionType,
                modelPattern: data.modelPattern,
                isActive: data.isActive ?? true,
            });
        }
        return this.planDefaultConfigRepo.save(config);
    }
    async deletePlanDefaultConfig(configId) {
        await this.planDefaultConfigRepo.delete(configId);
        return { success: true };
    }
    async getTokenPricing() {
        return this.tokenPricingRepo.find({
            order: { provider: 'ASC', modelPattern: 'ASC' },
        });
    }
    async createTokenPricing(data) {
        const pricing = this.tokenPricingRepo.create({
            ...data,
            isActive: data.isActive ?? true,
        });
        return this.tokenPricingRepo.save(pricing);
    }
    async updateTokenPricing(id, data) {
        await this.tokenPricingRepo.update(id, data);
        return this.tokenPricingRepo.findOne({ where: { id } });
    }
    async deleteTokenPricing(id) {
        await this.tokenPricingRepo.delete(id);
        return { success: true };
    }
    async getBillingStandards() {
        return this.billingStandardRepo.find({
            order: { functionType: 'ASC', tier: 'ASC' },
        });
    }
    async createBillingStandard(data) {
        const standard = this.billingStandardRepo.create({
            ...data,
            isActive: data.isActive ?? true,
        });
        return this.billingStandardRepo.save(standard);
    }
    async updateBillingStandard(id, data) {
        await this.billingStandardRepo.update(id, data);
        return this.billingStandardRepo.findOne({ where: { id } });
    }
    async deleteBillingStandard(id) {
        await this.billingStandardRepo.delete(id);
        return { success: true };
    }
    async getApiPolicies(planId) {
        const where = planId ? { planId } : {};
        return this.planApiPolicyRepo.find({
            where,
            order: { provider: 'ASC', modelPattern: 'ASC' },
        });
    }
    async createApiPolicy(data) {
        const policy = this.planApiPolicyRepo.create({
            ...data,
            isAllowed: data.isAllowed ?? true,
        });
        return this.planApiPolicyRepo.save(policy);
    }
    async updateApiPolicy(id, data) {
        await this.planApiPolicyRepo.update(id, data);
        return this.planApiPolicyRepo.findOne({ where: { id } });
    }
    async deleteApiPolicy(id) {
        await this.planApiPolicyRepo.delete(id);
        return { success: true };
    }
    async getUserFeatureUsage(userId) {
        const usage = await this.userFeatureUsageRepo.find({
            where: { userId },
            order: { featureType: 'ASC' },
        });
        const subscriptions = await this.subscriptionRepo.find({
            where: { userId },
            relations: ['plan'],
        });
        return {
            userId,
            subscriptions: subscriptions.map(s => ({
                id: s.id,
                planId: s.planId,
                planName: s.plan?.name,
                type: s.type,
                status: s.status,
                expiresAt: s.expiresAt,
            })),
            featureUsage: usage.map(u => ({
                featureType: u.featureType,
                usedAmount: u.usedAmount,
                totalAmount: u.totalAmount,
                remaining: u.totalAmount - u.usedAmount,
                unit: u.unit,
            })),
        };
    }
};
exports.AdminService = AdminService;
exports.AdminService = AdminService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __param(1, (0, typeorm_1.InjectRepository)(subscription_entity_1.Subscription)),
    __param(2, (0, typeorm_1.InjectRepository)(api_key_entity_1.ApiKey)),
    __param(3, (0, typeorm_1.InjectRepository)(user_balance_entity_1.UserBalance)),
    __param(4, (0, typeorm_1.InjectRepository)(recharge_record_entity_1.RechargeRecord)),
    __param(5, (0, typeorm_1.InjectRepository)(api_usage_log_entity_1.ApiUsageLog)),
    __param(6, (0, typeorm_1.InjectRepository)(plan_default_config_entity_1.PlanDefaultConfig)),
    __param(7, (0, typeorm_1.InjectRepository)(plan_feature_quota_entity_1.PlanFeatureQuota)),
    __param(8, (0, typeorm_1.InjectRepository)(token_pricing_entity_1.TokenPricing)),
    __param(9, (0, typeorm_1.InjectRepository)(billing_standard_entity_1.BillingStandard)),
    __param(10, (0, typeorm_1.InjectRepository)(plan_api_policy_entity_1.PlanApiPolicy)),
    __param(11, (0, typeorm_1.InjectRepository)(user_feature_usage_entity_1.UserFeatureUsage)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        subscription_service_1.SubscriptionService,
        plan_service_1.PlanService])
], AdminService);
//# sourceMappingURL=admin.service.js.map