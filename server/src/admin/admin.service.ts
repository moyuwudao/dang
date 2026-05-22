import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../auth/entities/user.entity';
import { Plan } from '../subscription/entities/plan.entity';
import { Subscription } from '../subscription/entities/subscription.entity';
import { ApiKey } from '../api-key/entities/api-key.entity';
import { UserBalance } from '../subscription/entities/user-balance.entity';
import { RechargeRecord } from '../subscription/entities/recharge-record.entity';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User)
    private userRepo: Repository<User>,
    @InjectRepository(Plan)
    private planRepo: Repository<Plan>,
    @InjectRepository(Subscription)
    private subscriptionRepo: Repository<Subscription>,
    @InjectRepository(ApiKey)
    private apiKeyRepo: Repository<ApiKey>,
    @InjectRepository(UserBalance)
    private balanceRepo: Repository<UserBalance>,
    @InjectRepository(RechargeRecord)
    private rechargeRepo: Repository<RechargeRecord>,
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
    return this.planRepo.find({ order: { priceCents: 'ASC' } });
  }

  // 创建套餐
  async createPlan(data: Partial<Plan>) {
    const plan = this.planRepo.create(data);
    return this.planRepo.save(plan);
  }

  // 更新套餐
  async updatePlan(planId: string, data: Partial<Plan>) {
    await this.planRepo.update(planId, data);
    return this.planRepo.findOne({ where: { id: planId } });
  }

  // 删除套餐
  async deletePlan(planId: string) {
    await this.planRepo.delete(planId);
    return { success: true };
  }

  // 订阅列表
  async getSubscriptions(page = 1, limit = 20, status?: string) {
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

  // 更新订阅
  async updateSubscription(subId: string, data: Partial<Subscription>) {
    await this.subscriptionRepo.update(subId, data);
    return this.subscriptionRepo.findOne({ where: { id: subId }, relations: ['user', 'plan'] });
  }

  // 充值记录
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
}
