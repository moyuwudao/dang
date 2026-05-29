import { Repository } from 'typeorm';
import { Subscription } from './entities/subscription.entity';
import { Plan } from './entities/plan.entity';
import { UserBalance } from './entities/user-balance.entity';
import { RechargeRecord } from './entities/recharge-record.entity';
import { PlanApiPolicy } from './entities/plan-api-policy.entity';
import { ApiUsageLog } from './entities/api-usage-log.entity';
import { PlanDefaultConfig } from './entities/plan-default-config.entity';
import { PlanFeatureQuota } from './entities/plan-feature-quota.entity';
import { UserFeatureUsage } from './entities/user-feature-usage.entity';
import { CreatePlanDto, RechargeDto, RefundDto } from './dto';
import { PlanService } from '../plan/plan.service';
import { BillingStrategyFactory } from './billing/billing-strategy.factory';
export declare class SubscriptionService {
    private subscriptionRepository;
    private planRepository;
    private userBalanceRepository;
    private rechargeRecordRepository;
    private planApiPolicyRepository;
    private apiUsageLogRepository;
    private planDefaultConfigRepository;
    private planFeatureQuotaRepository;
    private userFeatureUsageRepository;
    private planService;
    private billingStrategyFactory;
    constructor(subscriptionRepository: Repository<Subscription>, planRepository: Repository<Plan>, userBalanceRepository: Repository<UserBalance>, rechargeRecordRepository: Repository<RechargeRecord>, planApiPolicyRepository: Repository<PlanApiPolicy>, apiUsageLogRepository: Repository<ApiUsageLog>, planDefaultConfigRepository: Repository<PlanDefaultConfig>, planFeatureQuotaRepository: Repository<PlanFeatureQuota>, userFeatureUsageRepository: Repository<UserFeatureUsage>, planService: PlanService, billingStrategyFactory: BillingStrategyFactory);
    getSubscription(userId: string): Promise<{
        code: number;
        message: string;
        data: {
            planId: string;
            planName: string;
            status: string;
            expiresAt: any;
            totalQuota: number;
            usedQuota: number;
            remainingQuota: number;
            balanceCents: number;
            apiPolicies?: undefined;
            defaultConfigs?: undefined;
        };
    } | {
        code: number;
        message: string;
        data: {
            planId: string;
            planName: string;
            status: string;
            expiresAt: Date;
            totalQuota: number;
            usedQuota: number;
            remainingQuota: number;
            balanceCents: number;
            apiPolicies: {
                provider: string;
                model: string;
                modelPattern: string;
                multiplier: number;
                isAllowed: boolean;
            }[];
            defaultConfigs: {
                functionType: string;
                modelPattern: string;
            }[];
        };
    }>;
    getPlans(type?: string): Promise<{
        code: number;
        message: string;
        data: {
            allowedModels: string[];
            featureQuotas: PlanFeatureQuota[];
            id: string;
            name: string;
            description: string;
            priceCents: number;
            durationDays: number;
            type: string;
            apiPolicyType: string;
            features: string[];
            isRecommended: boolean;
            quotaType: string;
            quotaValue: number;
            isActive: boolean;
        }[];
    }>;
    createSubscription(userId: string, planId: string): Promise<{
        code: number;
        message: string;
        data: Subscription;
    }>;
    createPlan(dto: CreatePlanDto): Promise<{
        code: number;
        message: string;
        data: {
            allowedModels: string[];
            featureQuotas: PlanFeatureQuota[];
            id: string;
            name: string;
            description: string;
            priceCents: number;
            durationDays: number;
            type: string;
            apiPolicyType: string;
            features: string[];
            isRecommended: boolean;
            quotaType: string;
            quotaValue: number;
            isActive: boolean;
        };
    }>;
    useQuota(userId: string, amount: number): Promise<{
        code: number;
        message: string;
        data: {
            planId: string;
            usedQuota: number;
            remainingQuota: number;
        };
    }>;
    updateQuotaUsage(userId: string, amount: number): Promise<{
        code: number;
        message: string;
        data: {
            usedQuota: number;
            remainingQuota: number;
            planId?: undefined;
        };
    } | {
        code: number;
        message: string;
        data: {
            planId: string;
            usedQuota: number;
            remainingQuota: number;
        };
    }>;
    getBalance(userId: string): Promise<{
        code: number;
        message: string;
        data: {
            balanceCents: number;
            totalRechargedCents: number;
            totalRefundedCents: number;
        };
    }>;
    recharge(userId: string, dto: RechargeDto): Promise<{
        code: number;
        message: string;
        data: {
            balanceCents: number;
            amountCents: number;
        };
    }>;
    refund(userId: string, dto: RefundDto): Promise<{
        code: number;
        message: string;
        data: {
            balanceCents: number;
            amountCents: number;
        };
    }>;
    getRechargeRecords(userId: string): Promise<{
        code: number;
        message: string;
        data: RechargeRecord[];
    }>;
    createTrialSubscription(userId: string, trialData: {
        planId: string;
        planName: string;
        totalQuota: number;
        usedQuota: number;
        expiresAt: Date;
    }): Promise<Subscription>;
    initUserBalance(userId: string): Promise<void>;
    getPlanApiPolicies(planId: string): Promise<PlanApiPolicy[]>;
    setPlanApiPolicy(planId: string, provider: string, multiplier: number, modelPattern?: string): Promise<PlanApiPolicy>;
    deletePlanApiPolicy(policyId: string): Promise<void>;
    calculateQuotaConsumption(userId: string, provider: string, model: string): Promise<number>;
    consumeQuotaWithApi(userId: string, provider: string, model: string, tokens?: {
        prompt: number;
        completion: number;
    }): Promise<{
        consumed: number;
        multiplier: number;
        remaining: number;
    }>;
    canUseApi(userId: string, provider: string, model: string): Promise<{
        allowed: boolean;
        reason?: string;
    }>;
    canUseFeature(userId: string, featureType: string, amount: number): Promise<{
        canUse: boolean;
        reason?: string;
    }>;
    consumeFeature(userId: string, featureType: string, amount: number, metadata?: any): Promise<{
        success: boolean;
        consumed: number;
        remaining: number;
        costCents?: number;
        message?: string;
    }>;
    getFeatureRemaining(userId: string, featureType: string): Promise<number>;
    getFeatureUsage(userId: string): Promise<any>;
    private getFeatureUnit;
    purchaseWithBalance(userId: string, planId: string): Promise<{
        success: boolean;
        message: string;
        subscription?: Subscription;
    }>;
}
