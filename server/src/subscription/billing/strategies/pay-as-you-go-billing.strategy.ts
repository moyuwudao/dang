import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BillingStrategy, ConsumeResult } from '../interfaces/billing-strategy.interface';
import { UserBalance } from '../../entities/user-balance.entity';
import { TokenPricing } from '../../entities/token-pricing.entity';
import { ApiUsageLog } from '../../entities/api-usage-log.entity';

@Injectable()
export class PayAsYouGoBillingStrategy implements BillingStrategy {
  constructor(
    @InjectRepository(UserBalance)
    private balanceRepo: Repository<UserBalance>,
    @InjectRepository(TokenPricing)
    private pricingRepo: Repository<TokenPricing>,
    @InjectRepository(ApiUsageLog)
    private usageLogRepo: Repository<ApiUsageLog>,
  ) {}

  async canUse(userId: string, featureType: string, amount: number): Promise<boolean> {
    const balance = await this.balanceRepo.findOne({ where: { userId } });
    if (!balance || balance.balanceCents <= 0) return false;

    const estimatedCost = await this.calculateCost(featureType, amount);
    return balance.balanceCents >= estimatedCost;
  }

  async consume(userId: string, featureType: string, amount: number, metadata?: any): Promise<ConsumeResult> {
    const balance = await this.balanceRepo.findOne({ where: { userId } });
    if (!balance) {
      return { success: false, consumed: 0, remaining: 0, message: '余额不足' };
    }

    const costCents = await this.calculateCost(featureType, amount, metadata);
    if (balance.balanceCents < costCents) {
      return { success: false, consumed: 0, remaining: balance.balanceCents, message: '余额不足' };
    }

    balance.balanceCents -= costCents;
    await this.balanceRepo.save(balance);

    await this.usageLogRepo.save({
      userId,
      provider: metadata?.provider || 'unknown',
      model: metadata?.model || 'unknown',
      featureType,
      resourceConsumed: amount,
      costCents,
      promptTokens: metadata?.promptTokens,
      completionTokens: metadata?.completionTokens,
      totalTokens: metadata?.totalTokens,
    });

    return {
      success: true,
      consumed: amount,
      remaining: balance.balanceCents,
      costCents,
    };
  }

  async getRemaining(userId: string): Promise<number> {
    const balance = await this.balanceRepo.findOne({ where: { userId } });
    return balance?.balanceCents || 0;
  }

  private async calculateCost(featureType: string, amount: number, metadata?: any): Promise<number> {
    switch (featureType) {
      case 'ai_chat':
        return this.calculateTokenCost(metadata?.provider, metadata?.model, metadata?.promptTokens, metadata?.completionTokens);
      case 'transcription':
        return Math.ceil(amount * 5);
      case 'realtime_transcription':
        return Math.ceil(amount * 8);
      case 'text_analysis':
        return Math.ceil(amount * 2);
      case 'image_recognition':
        return Math.ceil(amount * 10);
      case 'ocr':
        return Math.ceil(amount * 5);
      case 'tts':
        return Math.ceil(amount * 3);
      default:
        return 0;
    }
  }

  private async calculateTokenCost(provider: string, model: string, promptTokens: number, completionTokens: number): Promise<number> {
    const pricing = await this.pricingRepo.findOne({
      where: { provider, modelPattern: model, isActive: true },
    });

    if (!pricing) {
      return Math.ceil((promptTokens + completionTokens) * 0.01);
    }

    const promptCost = (promptTokens / 1000) * pricing.promptPricePer1k;
    const completionCost = (completionTokens / 1000) * pricing.completionPricePer1k;
    return Math.ceil(promptCost + completionCost);
  }
}
