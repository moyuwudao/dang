import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiConfig } from '../entities/api-config.entity';
import { TokenPricing } from '../entities/token-pricing.entity';
import { UserTokenBalance } from '../entities/user-token-balance.entity';
import { ApiUsageLog } from '../entities/api-usage-log.entity';
import { Subscription } from '../entities/subscription.entity';
import { Plan } from '../entities/plan.entity';

export interface ConsumeTokenResult {
  success: boolean;
  tokenConsumed: number;
  costYuan: number;
  quotaRemaining: number;       // 套餐配额剩余
  rechargeRemaining: number;    // 充值包余额剩余
  message?: string;
}

export interface TokenUsageMetadata {
  provider: string;
  model: string;
  rawAmount: number;
  promptTokens?: number;
  completionTokens?: number;
}

@Injectable()
export class TokenBillingService {
  constructor(
    @InjectRepository(ApiConfig)
    private apiConfigRepo: Repository<ApiConfig>,
    @InjectRepository(TokenPricing)
    private pricingRepo: Repository<TokenPricing>,
    @InjectRepository(UserTokenBalance)
    private balanceRepo: Repository<UserTokenBalance>,
    @InjectRepository(ApiUsageLog)
    private usageLogRepo: Repository<ApiUsageLog>,
    @InjectRepository(Subscription)
    private subscriptionRepo: Repository<Subscription>,
    @InjectRepository(Plan)
    private planRepo: Repository<Plan>,
  ) {}

  /**
   * 统一Token计费接口
   * 计费模型：套餐配额为主 + 充值包补充
   * 1. 优先扣月度套餐配额（subscriptions.totalQuota - usedQuota）
   * 2. 配额不足时扣充值包余额（user_token_balances.balanceTokens）
   * 3. 都不足则拒绝
   */
  async consumeToken(
    userId: string,
    metadata: TokenUsageMetadata,
  ): Promise<ConsumeTokenResult> {
    const { provider, model, rawAmount } = metadata;

    // 1. 查询API配置获取基础系数
    const apiConfig = await this.apiConfigRepo.findOne({
      where: { provider, modelPattern: model, isActive: true },
    });

    const coefficient = apiConfig?.baseCoefficient ?? 1.0;

    // 2. 计算Token消耗 = 实际Token × API系数
    const tokenConsumed = Math.ceil(rawAmount * coefficient);

    // 3. 查询Token单价（仅用于费用计算/展示）
    const pricing = await this.pricingRepo.findOne({
      where: { provider, modelPattern: model, isActive: true },
    });
    const pricePerToken = pricing?.pricePerToken ?? 0.002;
    const costYuan = tokenConsumed * pricePerToken;

    // 4. 查找可用套餐配额（月度套餐优先，按到期时间排序）
    const activeSubscriptions = await this.subscriptionRepo.find({
      where: { userId, status: 'active' },
      order: { expiresAt: 'ASC' }, // 先到期的先扣
    });

    let remaining = tokenConsumed;
    let quotaRemaining = 0;

    // 4a. 优先扣月度套餐配额
    for (const sub of activeSubscriptions) {
      if (remaining <= 0) break;
      const plan = await this.planRepo.findOne({ where: { id: sub.planId } });
      // 只扣月度套餐配额
      if (plan && plan.type === 'monthly') {
        const available = sub.totalQuota - sub.usedQuota;
        if (available > 0) {
          const deduct = Math.min(remaining, available);
          sub.usedQuota += deduct;
          remaining -= deduct;
          await this.subscriptionRepo.save(sub);
        }
      }
    }

    // 计算月度套餐总剩余配额
    let totalMonthlyQuotaRemaining = 0;
    for (const sub of activeSubscriptions) {
      const plan = await this.planRepo.findOne({ where: { id: sub.planId } });
      if (plan && plan.type === 'monthly') {
        totalMonthlyQuotaRemaining += Math.max(0, sub.totalQuota - sub.usedQuota);
      }
    }
    quotaRemaining = totalMonthlyQuotaRemaining;

    // 4b. 月度配额不足时，扣充值包余额
    let rechargeRemaining = 0;
    if (remaining > 0) {
      const balance = await this.getOrCreateBalance(userId);
      if (balance.balanceTokens >= remaining) {
        balance.balanceTokens -= remaining;
        balance.usedTokens += remaining;
        balance.totalTokens += tokenConsumed;
        await this.balanceRepo.save(balance);
        remaining = 0;
      } else {
        // 充值包也不足
        return {
          success: false,
          tokenConsumed: 0,
          costYuan: 0,
          quotaRemaining,
          rechargeRemaining: Number(balance.balanceTokens) || 0,
          message: '套餐配额和充值余额不足，请购买套餐或充值',
        };
      }
      rechargeRemaining = Number(balance.balanceTokens) || 0;
    } else {
      // 月度配额够扣，也要更新 balance 的 totalTokens 统计
      const balance = await this.getOrCreateBalance(userId);
      balance.totalTokens += tokenConsumed;
      await this.balanceRepo.save(balance);
      rechargeRemaining = Number(balance.balanceTokens) || 0;
    }

    // 5. 记录使用日志
    await this.usageLogRepo.save({
      userId,
      provider,
      model,
      promptTokens: metadata.promptTokens || 0,
      completionTokens: metadata.completionTokens || 0,
      tokenConsumed,
      quotaConsumed: tokenConsumed, // 计费消耗量 = tokenConsumed
      apiCoefficient: coefficient,
      costYuan,
      createdAt: new Date(),
    });

    return {
      success: true,
      tokenConsumed,
      costYuan,
      quotaRemaining,
      rechargeRemaining,
    };
  }

  /**
   * 获取或创建用户余额（充值包余额）
   * 不再默认赠送500免费额度，免费额度由套餐配额决定
   */
  async getOrCreateBalance(userId: string): Promise<UserTokenBalance> {
    let balance = await this.balanceRepo.findOne({
      where: { userId },
    });

    if (!balance) {
      balance = this.balanceRepo.create({
        userId,
        totalTokens: 0,
        usedTokens: 0,
        balanceTokens: 0,
        freeTokensRemaining: 0, // 不再默认赠送500
      });
      await this.balanceRepo.save(balance);
    }

    return balance;
  }

  /**
   * 充值Token（充值包）
   */
  async rechargeTokens(userId: string, tokens: number): Promise<UserTokenBalance> {
    const balance = await this.getOrCreateBalance(userId);
    balance.balanceTokens += tokens;
    balance.totalTokens += tokens;
    return this.balanceRepo.save(balance);
  }

  /**
   * 获取用户余额（充值包余额）
   */
  async getBalance(userId: string): Promise<{ balanceTokens: number; freeTokensRemaining: number; totalTokens: number; usedTokens: number }> {
    const balance = await this.getOrCreateBalance(userId);
    return {
      balanceTokens: Number(balance.balanceTokens) || 0,
      freeTokensRemaining: Number(balance.freeTokensRemaining) || 0,
      totalTokens: Number(balance.totalTokens) || 0,
      usedTokens: Number(balance.usedTokens) || 0,
    };
  }

  /**
   * 检查是否可以使用（套餐配额 + 充值包余额）
   */
  async canUse(userId: string, estimatedTokens: number): Promise<boolean> {
    // 1. 检查月度套餐配额
    const activeSubscriptions = await this.subscriptionRepo.find({
      where: { userId, status: 'active' },
    });

    let totalQuotaAvailable = 0;
    for (const sub of activeSubscriptions) {
      const plan = await this.planRepo.findOne({ where: { id: sub.planId } });
      if (plan && plan.type === 'monthly') {
        totalQuotaAvailable += Math.max(0, sub.totalQuota - sub.usedQuota);
      }
    }

    if (totalQuotaAvailable >= estimatedTokens) return true;

    // 2. 配额不足时检查充值包余额
    const balance = await this.getOrCreateBalance(userId);
    const rechargeAvailable = Number(balance.balanceTokens) || 0;

    return (totalQuotaAvailable + rechargeAvailable) >= estimatedTokens;
  }

  /**
   * 获取使用记录
   */
  async getUsageLogs(userId: string, limit: number = 50): Promise<ApiUsageLog[]> {
    return this.usageLogRepo.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: limit,
    });
  }
}
