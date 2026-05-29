import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SubscriptionBillingStrategy } from '../../src/subscription/billing/strategies/subscription-billing.strategy';
import { PackageBillingStrategy } from '../../src/subscription/billing/strategies/package-billing.strategy';
import { PayAsYouGoBillingStrategy } from '../../src/subscription/billing/strategies/pay-as-you-go-billing.strategy';
import { BillingStrategyFactory } from '../../src/subscription/billing/billing-strategy.factory';
import { Subscription } from '../../src/subscription/entities/subscription.entity';
import { UserFeatureUsage } from '../../src/subscription/entities/user-feature-usage.entity';
import { PlanFeatureQuota } from '../../src/subscription/entities/plan-feature-quota.entity';
import { UserBalance } from '../../src/subscription/entities/user-balance.entity';
import { TokenPricing } from '../../src/subscription/entities/token-pricing.entity';
import { ApiUsageLog } from '../../src/subscription/entities/api-usage-log.entity';

describe('Billing Strategies', () => {
  let subscriptionStrategy: SubscriptionBillingStrategy;
  let packageStrategy: PackageBillingStrategy;
  let payAsYouGoStrategy: PayAsYouGoBillingStrategy;
  let strategyFactory: BillingStrategyFactory;

  const mockSubscriptionRepo = {
    findOne: jest.fn(),
    find: jest.fn(),
  };

  const mockFeatureUsageRepo = {
    findOne: jest.fn(),
    save: jest.fn(),
    create: jest.fn(),
  };

  const mockPlanFeatureQuotaRepo = {
    findOne: jest.fn(),
  };

  const mockBalanceRepo = {
    findOne: jest.fn(),
    save: jest.fn(),
  };

  const mockPricingRepo = {
    findOne: jest.fn(),
  };

  const mockUsageLogRepo = {
    save: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SubscriptionBillingStrategy,
        PackageBillingStrategy,
        PayAsYouGoBillingStrategy,
        BillingStrategyFactory,
        {
          provide: getRepositoryToken(Subscription),
          useValue: mockSubscriptionRepo,
        },
        {
          provide: getRepositoryToken(UserFeatureUsage),
          useValue: mockFeatureUsageRepo,
        },
        {
          provide: getRepositoryToken(PlanFeatureQuota),
          useValue: mockPlanFeatureQuotaRepo,
        },
        {
          provide: getRepositoryToken(UserBalance),
          useValue: mockBalanceRepo,
        },
        {
          provide: getRepositoryToken(TokenPricing),
          useValue: mockPricingRepo,
        },
        {
          provide: getRepositoryToken(ApiUsageLog),
          useValue: mockUsageLogRepo,
        },
      ],
    }).compile();

    subscriptionStrategy = module.get<SubscriptionBillingStrategy>(SubscriptionBillingStrategy);
    packageStrategy = module.get<PackageBillingStrategy>(PackageBillingStrategy);
    payAsYouGoStrategy = module.get<PayAsYouGoBillingStrategy>(PayAsYouGoBillingStrategy);
    strategyFactory = module.get<BillingStrategyFactory>(BillingStrategyFactory);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('SubscriptionBillingStrategy', () => {
    it('should allow usage when subscription has enough quota', async () => {
      mockSubscriptionRepo.findOne.mockResolvedValue({
        id: 'sub-1',
        userId: 'user-1',
        planId: 'plan-1',
        type: 'subscription',
        status: 'active',
        expiresAt: new Date(Date.now() + 86400000),
      });

      mockPlanFeatureQuotaRepo.findOne.mockResolvedValue({
        planId: 'plan-1',
        featureType: 'transcription',
        quotaValue: 100,
        quotaUnit: 'minutes',
      });

      mockFeatureUsageRepo.findOne.mockResolvedValue({
        userId: 'user-1',
        subscriptionId: 'sub-1',
        featureType: 'transcription',
        usedAmount: 10,
        totalAmount: 100,
        unit: 'minutes',
      });

      const result = await subscriptionStrategy.canUse('user-1', 'transcription', 50);
      expect(result).toBe(true);
    });

    it('should deny usage when quota is exhausted', async () => {
      mockSubscriptionRepo.findOne.mockResolvedValue({
        id: 'sub-1',
        userId: 'user-1',
        planId: 'plan-1',
        type: 'subscription',
        status: 'active',
        expiresAt: new Date(Date.now() + 86400000),
      });

      mockPlanFeatureQuotaRepo.findOne.mockResolvedValue({
        planId: 'plan-1',
        featureType: 'transcription',
        quotaValue: 100,
        quotaUnit: 'minutes',
      });

      mockFeatureUsageRepo.findOne.mockResolvedValue({
        userId: 'user-1',
        subscriptionId: 'sub-1',
        featureType: 'transcription',
        usedAmount: 90,
        totalAmount: 100,
        unit: 'minutes',
      });

      const result = await subscriptionStrategy.canUse('user-1', 'transcription', 20);
      expect(result).toBe(false);
    });

    it('should consume quota successfully', async () => {
      mockSubscriptionRepo.findOne.mockResolvedValue({
        id: 'sub-1',
        userId: 'user-1',
        planId: 'plan-1',
        type: 'subscription',
        status: 'active',
        expiresAt: new Date(Date.now() + 86400000),
      });

      mockFeatureUsageRepo.findOne.mockResolvedValue({
        userId: 'user-1',
        subscriptionId: 'sub-1',
        featureType: 'transcription',
        usedAmount: 10,
        totalAmount: 100,
        unit: 'minutes',
      });

      const result = await subscriptionStrategy.consume('user-1', 'transcription', 30);
      expect(result.success).toBe(true);
      expect(result.consumed).toBe(30);
      expect(result.remaining).toBe(60);
    });
  });

  describe('PayAsYouGoBillingStrategy', () => {
    it('should allow usage when balance is sufficient', async () => {
      mockBalanceRepo.findOne.mockResolvedValue({
        userId: 'user-1',
        balanceCents: 1000,
      });

      const result = await payAsYouGoStrategy.canUse('user-1', 'transcription', 10);
      expect(result).toBe(true);
    });

    it('should deny usage when balance is insufficient', async () => {
      mockBalanceRepo.findOne.mockResolvedValue({
        userId: 'user-1',
        balanceCents: 10,
      });

      const result = await payAsYouGoStrategy.canUse('user-1', 'transcription', 10);
      expect(result).toBe(false);
    });

    it('should consume balance and log usage', async () => {
      mockBalanceRepo.findOne.mockResolvedValue({
        userId: 'user-1',
        balanceCents: 1000,
      });

      const result = await payAsYouGoStrategy.consume('user-1', 'transcription', 10);
      expect(result.success).toBe(true);
      expect(result.consumed).toBe(10);
      expect(result.remaining).toBe(950); // 1000 - 10 * 5
      expect(result.costCents).toBe(50); // 10 minutes * 5 cents
    });
  });

  describe('BillingStrategyFactory', () => {
    it('should return subscription strategy when subscription is active', async () => {
      mockSubscriptionRepo.findOne.mockResolvedValue({
        id: 'sub-1',
        userId: 'user-1',
        planId: 'plan-1',
        type: 'subscription',
        status: 'active',
        expiresAt: new Date(Date.now() + 86400000),
      });

      mockPlanFeatureQuotaRepo.findOne.mockResolvedValue({
        planId: 'plan-1',
        featureType: 'transcription',
        quotaValue: 100,
        quotaUnit: 'minutes',
      });

      mockFeatureUsageRepo.findOne.mockResolvedValue({
        userId: 'user-1',
        subscriptionId: 'sub-1',
        featureType: 'transcription',
        usedAmount: 10,
        totalAmount: 100,
        unit: 'minutes',
      });

      const strategy = await strategyFactory.getStrategy('user-1', 'transcription');
      expect(strategy).toBeInstanceOf(SubscriptionBillingStrategy);
    });

    it('should return pay-as-you-go strategy when no subscription', async () => {
      mockSubscriptionRepo.findOne.mockResolvedValue(null);
      mockBalanceRepo.findOne.mockResolvedValue({
        userId: 'user-1',
        balanceCents: 1000,
      });

      const strategy = await strategyFactory.getStrategy('user-1', 'transcription');
      expect(strategy).toBeInstanceOf(PayAsYouGoBillingStrategy);
    });
  });
});
