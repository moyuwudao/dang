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
const uuid_1 = require("uuid");
const user_entity_1 = require("../auth/entities/user.entity");
const plan_entity_1 = require("../subscription/entities/plan.entity");
const subscription_entity_1 = require("../subscription/entities/subscription.entity");
const api_key_entity_1 = require("../api-key/entities/api-key.entity");
const user_balance_entity_1 = require("../subscription/entities/user-balance.entity");
const recharge_record_entity_1 = require("../subscription/entities/recharge-record.entity");
const subscription_service_1 = require("../subscription/subscription.service");
let AdminService = class AdminService {
    constructor(userRepo, planRepo, subscriptionRepo, apiKeyRepo, balanceRepo, rechargeRepo, subscriptionService) {
        this.userRepo = userRepo;
        this.planRepo = planRepo;
        this.subscriptionRepo = subscriptionRepo;
        this.apiKeyRepo = apiKeyRepo;
        this.balanceRepo = balanceRepo;
        this.rechargeRepo = rechargeRepo;
        this.subscriptionService = subscriptionService;
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
    async updateUser(userId, data) {
        await this.userRepo.update(userId, data);
        return this.userRepo.findOne({ where: { id: userId } });
    }
    async deleteUser(userId) {
        await this.userRepo.delete(userId);
        return { success: true };
    }
    async getPlans() {
        return this.planRepo.find({ order: { priceCents: 'ASC' } });
    }
    async createPlan(data) {
        if (!data.id) {
            data.id = (0, uuid_1.v4)();
        }
        const plan = this.planRepo.create(data);
        return this.planRepo.save(plan);
    }
    async updatePlan(planId, data) {
        await this.planRepo.update(planId, data);
        return this.planRepo.findOne({ where: { id: planId } });
    }
    async deletePlan(planId) {
        await this.planRepo.delete(planId);
        return { success: true };
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
};
exports.AdminService = AdminService;
exports.AdminService = AdminService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __param(1, (0, typeorm_1.InjectRepository)(plan_entity_1.Plan)),
    __param(2, (0, typeorm_1.InjectRepository)(subscription_entity_1.Subscription)),
    __param(3, (0, typeorm_1.InjectRepository)(api_key_entity_1.ApiKey)),
    __param(4, (0, typeorm_1.InjectRepository)(user_balance_entity_1.UserBalance)),
    __param(5, (0, typeorm_1.InjectRepository)(recharge_record_entity_1.RechargeRecord)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        subscription_service_1.SubscriptionService])
], AdminService);
//# sourceMappingURL=admin.service.js.map