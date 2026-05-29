"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const testing_1 = require("@nestjs/testing");
const typeorm_1 = require("@nestjs/typeorm");
const subscription_billing_strategy_1 = require("../../src/subscription/billing/strategies/subscription-billing.strategy");
const package_billing_strategy_1 = require("../../src/subscription/billing/strategies/package-billing.strategy");
const pay_as_you_go_billing_strategy_1 = require("../../src/subscription/billing/strategies/pay-as-you-go-billing.strategy");
const billing_strategy_factory_1 = require("../../src/subscription/billing/billing-strategy.factory");
const subscription_entity_1 = require("../../src/subscription/entities/subscription.entity");
const user_feature_usage_entity_1 = require("../../src/subscription/entities/user-feature-usage.entity");
const plan_feature_quota_entity_1 = require("../../src/subscription/entities/plan-feature-quota.entity");
const user_balance_entity_1 = require("../../src/subscription/entities/user-balance.entity");
const token_pricing_entity_1 = require("../../src/subscription/entities/token-pricing.entity");
const api_usage_log_entity_1 = require("../../src/subscription/entities/api-usage-log.entity");
describe('Billing Strategies', () => {
    let subscriptionStrategy;
    let packageStrategy;
    let payAsYouGoStrategy;
    let strategyFactory;
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
        const module = await testing_1.Test.createTestingModule({
            providers: [
                subscription_billing_strategy_1.SubscriptionBillingStrategy,
                package_billing_strategy_1.PackageBillingStrategy,
                pay_as_you_go_billing_strategy_1.PayAsYouGoBillingStrategy,
                billing_strategy_factory_1.BillingStrategyFactory,
                {
                    provide: (0, typeorm_1.getRepositoryToken)(subscription_entity_1.Subscription),
                    useValue: mockSubscriptionRepo,
                },
                {
                    provide: (0, typeorm_1.getRepositoryToken)(user_feature_usage_entity_1.UserFeatureUsage),
                    useValue: mockFeatureUsageRepo,
                },
                {
                    provide: (0, typeorm_1.getRepositoryToken)(plan_feature_quota_entity_1.PlanFeatureQuota),
                    useValue: mockPlanFeatureQuotaRepo,
                },
                {
                    provide: (0, typeorm_1.getRepositoryToken)(user_balance_entity_1.UserBalance),
                    useValue: mockBalanceRepo,
                },
                {
                    provide: (0, typeorm_1.getRepositoryToken)(token_pricing_entity_1.TokenPricing),
                    useValue: mockPricingRepo,
                },
                {
                    provide: (0, typeorm_1.getRepositoryToken)(api_usage_log_entity_1.ApiUsageLog),
                    useValue: mockUsageLogRepo,
                },
            ],
        }).compile();
        subscriptionStrategy = module.get(subscription_billing_strategy_1.SubscriptionBillingStrategy);
        packageStrategy = module.get(package_billing_strategy_1.PackageBillingStrategy);
        payAsYouGoStrategy = module.get(pay_as_you_go_billing_strategy_1.PayAsYouGoBillingStrategy);
        strategyFactory = module.get(billing_strategy_factory_1.BillingStrategyFactory);
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
            expect(result.remaining).toBe(950);
            expect(result.costCents).toBe(50);
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
            expect(strategy).toBeInstanceOf(subscription_billing_strategy_1.SubscriptionBillingStrategy);
        });
        it('should return pay-as-you-go strategy when no subscription', async () => {
            mockSubscriptionRepo.findOne.mockResolvedValue(null);
            mockBalanceRepo.findOne.mockResolvedValue({
                userId: 'user-1',
                balanceCents: 1000,
            });
            const strategy = await strategyFactory.getStrategy('user-1', 'transcription');
            expect(strategy).toBeInstanceOf(pay_as_you_go_billing_strategy_1.PayAsYouGoBillingStrategy);
        });
    });
});
//# sourceMappingURL=billing-strategy.spec.js.map