import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcryptjs';
import { User } from '../auth/entities/user.entity';
import { Plan } from '../subscription/entities/plan.entity';
import { Subscription } from '../subscription/entities/subscription.entity';
import { ApiKey } from '../api-key/entities/api-key.entity';
import { RechargeRecord } from '../subscription/entities/recharge-record.entity';
import { ApiUsageLog } from '../subscription/entities/api-usage-log.entity';
import { TokenPricing } from '../subscription/entities/token-pricing.entity';
import { ApiConfig } from '../subscription/entities/api-config.entity';
import { UserTokenBalance } from '../subscription/entities/user-token-balance.entity';
import { SubscriptionService } from '../subscription/subscription.service';
import { PlanService } from '../plan/plan.service';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User)
    private userRepo: Repository<User>,
    @InjectRepository(Subscription)
    private subscriptionRepo: Repository<Subscription>,
    @InjectRepository(ApiKey)
    private apiKeyRepo: Repository<ApiKey>,
    @InjectRepository(RechargeRecord)
    private rechargeRepo: Repository<RechargeRecord>,
    @InjectRepository(ApiUsageLog)
    private apiUsageLogRepo: Repository<ApiUsageLog>,
    @InjectRepository(TokenPricing)
    private tokenPricingRepo: Repository<TokenPricing>,
    @InjectRepository(ApiConfig)
    private apiConfigRepo: Repository<ApiConfig>,
    @InjectRepository(UserTokenBalance)
    private userTokenBalanceRepo: Repository<UserTokenBalance>,
    private subscriptionService: SubscriptionService,
    private planService: PlanService,
  ) {}

  // 统计
  async getStats() {
    const [
      totalUsers,
      activeSubscriptions,
      apiKeyCount,
      totalRevenue,
    ] = await Promise.all([
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

  // 用户列表
  async getUsers(page = 1, limit = 20, search?: string) {
    const qb = this.userRepo.createQueryBuilder('u')
      .leftJoinAndSelect('u.subscriptions', 's')
      .leftJoinAndSelect(UserTokenBalance, 'tb', 'tb.user_id = u.id')
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
        balanceTokens: 0,
      })),
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }

  // 创建用户
  async createUser(data: {
    phone: string;
    password: string;
    nickname?: string;
    role?: string;
    status?: string;
  }) {
    const existingUser = await this.userRepo.findOne({
      where: { phone: data.phone },
    });

    if (existingUser) {
      throw new BadRequestException('手机号已存在');
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

    // 初始化用户Token余额
    const balance = this.userTokenBalanceRepo.create({
      userId: user.id,
      totalTokens: 0,
      usedTokens: 0,
      balanceTokens: 0,
      freeTokensRemaining: 500,
    });
    await this.userTokenBalanceRepo.save(balance);

    // 创建新手体验订阅
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

  // 获取用户详情
  async getUserById(userId: string) {
    return this.userRepo.findOne({ where: { id: userId } });
  }

  // 更新用户
  async updateUser(userId: string, data: Partial<User>) {
    await this.userRepo.update(userId, data);
    return this.userRepo.findOne({ where: { id: userId } });
  }

  // 删除用户
  async deleteUser(userId: string) {
    await this.userRepo.delete(userId);
    return { success: true };
  }

  // 套餐列表
  async getPlans() {
    return this.planService.getPlans(true);
  }

  // 创建套餐
  async createPlan(data: Partial<Plan>) {
    return this.planService.createPlan(data);
  }

  // 更新套餐
  async updatePlan(planId: string, data: Partial<Plan>) {
    return this.planService.updatePlan(planId, data);
  }

  // 删除套餐
  async deletePlan(planId: string) {
    return this.planService.deletePlan(planId);
  }

  // 订阅列表
  async getSubscriptions(page = 1, limit = 20, status?: string) {
    const qb = this.subscriptionRepo.createQueryBuilder('s')
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
        planId: s.planId,
        status: s.status,
        startedAt: s.startedAt,
        expiresAt: s.expiresAt,
        tokenQuota: s.tokenQuota,
        usedTokens: s.usedTokens,
        balanceTokens: s.balanceTokens,
        createdAt: s.createdAt,
      })),
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }

  // 更新订阅
  async updateSubscription(subId: string, data: Partial<Subscription>) {
    await this.subscriptionRepo.update(subId, data);
    return this.subscriptionRepo.findOne({ where: { id: subId } });
  }

  // 充值记录
  async getRechargeRecords(page = 1, limit = 20) {
    const [records, total] = await this.rechargeRepo.findAndCount({
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });

    return {
      items: records.map(r => ({
        id: r.id,
        userId: r.userId,
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

  // 图表数据 - 用户增长趋势
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

  // 管理员为用户分配套餐
  async assignPlanToUser(userId: string, planId: string) {
    const plan = await this.planService.getPlanById(planId);
    if (!plan) {
      throw new BadRequestException('套餐不存在');
    }

    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) {
      throw new BadRequestException('用户不存在');
    }

    // 将用户当前活跃订阅设为过期
    await this.subscriptionRepo.update(
      { userId, status: 'active' },
      { status: 'expired' },
    );

    // 创建新订阅
    const now = new Date();
    const expiresAt = new Date(now.getTime() + plan.durationDays * 24 * 60 * 60 * 1000);

    const subscription = this.subscriptionRepo.create({
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
      tokenQuota: plan.tokenQuota || 0,
      usedTokens: 0,
    };
  }

  // 图表数据 - 收入趋势
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

  // API 调用日志查询
  async getApiUsageLogs(
    page = 1,
    limit = 20,
    userId?: string,
    provider?: string,
  ) {
    const qb = this.apiUsageLogRepo.createQueryBuilder('log')
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
        provider: log.provider,
        model: log.model,
        promptTokens: log.promptTokens,
        completionTokens: log.completionTokens,
        tokenConsumed: log.tokenConsumed,
        apiCoefficient: log.apiCoefficient,
        costYuan: log.costYuan,
        createdAt: log.createdAt,
      })),
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }

  // 手动调整用户Token余额
  async adjustUserTokens(userId: string, amount: number, reason?: string) {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) {
      throw new BadRequestException('用户不存在');
    }

    let balance = await this.userTokenBalanceRepo.findOne({ where: { userId } });
    if (!balance) {
      balance = this.userTokenBalanceRepo.create({
        userId,
        totalTokens: amount,
        usedTokens: 0,
        balanceTokens: amount,
        freeTokensRemaining: 500,
      });
    } else {
      balance.balanceTokens += amount;
      balance.totalTokens += amount;
    }

    await this.userTokenBalanceRepo.save(balance);

    // 记录调整日志
    const record = this.rechargeRepo.create({
      userId,
      amountCents: 0,
      type: 'adjustment',
      status: 'completed',
      remark: reason || `手动调整Token: ${amount > 0 ? '+' : ''}${amount}`,
    });
    await this.rechargeRepo.save(record);

    return {
      userId,
      amount,
      newBalanceTokens: balance.balanceTokens,
    };
  }

  // 收入统计
  async getRevenueStats(startDate?: string, endDate?: string) {
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

  // Token单价管理
  async getTokenPricing() {
    return this.tokenPricingRepo.find({
      order: { provider: 'ASC', modelPattern: 'ASC' },
    });
  }

  async createTokenPricing(data: Partial<TokenPricing>) {
    const pricing = this.tokenPricingRepo.create({
      ...data,
      isActive: data.isActive ?? true,
    });
    return this.tokenPricingRepo.save(pricing);
  }

  async updateTokenPricing(id: string, data: Partial<TokenPricing>) {
    await this.tokenPricingRepo.update(id, data);
    return this.tokenPricingRepo.findOne({ where: { id } });
  }

  async deleteTokenPricing(id: string) {
    await this.tokenPricingRepo.delete(id);
    return { success: true };
  }

  // API配置管理（含基础系数）
  async getApiConfigs() {
    return this.apiConfigRepo.find({
      order: { provider: 'ASC', modelPattern: 'ASC' },
    });
  }

  async createApiConfig(data: Partial<ApiConfig>) {
    const config = this.apiConfigRepo.create({
      ...data,
      isActive: data.isActive ?? true,
    });
    return this.apiConfigRepo.save(config);
  }

  async updateApiConfig(id: string, data: Partial<ApiConfig>) {
    await this.apiConfigRepo.update(id, data);
    return this.apiConfigRepo.findOne({ where: { id } });
  }

  async deleteApiConfig(id: string) {
    await this.apiConfigRepo.delete(id);
    return { success: true };
  }
}
