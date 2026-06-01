import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiConfig } from '../entities/api-config.entity';
import { TokenPricing } from '../entities/token-pricing.entity';
import { UserTokenBalance } from '../entities/user-token-balance.entity';
import { ApiUsageLog } from '../entities/api-usage-log.entity';

export interface ConsumeTokenResult {
  success: boolean;
  tokenConsumed: number;
  costYuan: number;
  balanceRemaining: number;
  freeTokensRemaining: number;
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
  ) {}

  /**
   * 统一Token计费接口
   * 计费公式: Token消耗 = 实际Token数 × API系数
   *          费用 = Token消耗 × Token单价（仅展示）
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

    // 4. 检查并扣除余额
    const balance = await this.getOrCreateBalance(userId);

    // 优先使用免费额度
    let actualCostTokens = tokenConsumed;
    let freeTokensUsed = 0;

    if (balance.freeTokensRemaining > 0) {
      freeTokensUsed = Math.min(tokenConsumed, balance.freeTokensRemaining);
      balance.freeTokensRemaining -= freeTokensUsed;
      actualCostTokens = tokenConsumed - freeTokensUsed;
    }

    // 检查付费余额
    if (actualCostTokens > 0 && balance.balanceTokens < actualCostTokens) {
      return {
        success: false,
        tokenConsumed: 0,
        costYuan: 0,
        balanceRemaining: balance.balanceTokens,
        freeTokensRemaining: balance.freeTokensRemaining,
        message: 'Token余额不足，请充值',
      };
    }

    // 扣除付费余额
    if (actualCostTokens > 0) {
      balance.balanceTokens -= actualCostTokens;
      balance.usedTokens += actualCostTokens;
    }

    // 累计消耗（包含免费额度部分）
    balance.totalTokens += tokenConsumed;
    await this.balanceRepo.save(balance);

    // 5. 记录使用日志
    await this.usageLogRepo.save({
      userId,
      provider,
      model,
      promptTokens: metadata.promptTokens || 0,
      completionTokens: metadata.completionTokens || 0,
      tokenConsumed,
      apiCoefficient: coefficient,
      costYuan,
      createdAt: new Date(),
    });

    return {
      success: true,
      tokenConsumed,
      costYuan,
      balanceRemaining: balance.balanceTokens,
      freeTokensRemaining: balance.freeTokensRemaining,
    };
  }

  /**
   * 获取或创建用户余额
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
        freeTokensRemaining: 500,
      });
      await this.balanceRepo.save(balance);
    }

    return balance;
  }

  /**
   * 充值Token
   */
  async rechargeTokens(userId: string, tokens: number): Promise<UserTokenBalance> {
    const balance = await this.getOrCreateBalance(userId);
    balance.balanceTokens += tokens;
    balance.totalTokens += tokens;
    return this.balanceRepo.save(balance);
  }

  /**
   * 获取用户余额
   */
  async getBalance(userId: string): Promise<{ balanceTokens: number; freeTokensRemaining: number; totalTokens: number; usedTokens: number }> {
    const balance = await this.getOrCreateBalance(userId);
    return {
      balanceTokens: balance.balanceTokens,
      freeTokensRemaining: balance.freeTokensRemaining,
      totalTokens: balance.totalTokens,
      usedTokens: balance.usedTokens,
    };
  }

  /**
   * 检查是否可以使用
   */
  async canUse(userId: string, estimatedTokens: number): Promise<boolean> {
    const balance = await this.getOrCreateBalance(userId);
    return (balance.balanceTokens + balance.freeTokensRemaining) >= estimatedTokens;
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
