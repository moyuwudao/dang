import { Repository } from 'typeorm';
import { User } from '../auth/entities/user.entity';
import { Plan } from '../subscription/entities/plan.entity';
import { Subscription } from '../subscription/entities/subscription.entity';
import { ApiKey } from '../api-key/entities/api-key.entity';
import { UserBalance } from '../subscription/entities/user-balance.entity';
import { RechargeRecord } from '../subscription/entities/recharge-record.entity';
import { ApiUsageLog } from '../subscription/entities/api-usage-log.entity';
import { PlanDefaultConfig } from '../subscription/entities/plan-default-config.entity';
import { PlanFeatureQuota } from '../subscription/entities/plan-feature-quota.entity';
import { TokenPricing } from '../subscription/entities/token-pricing.entity';
import { BillingStandard } from '../subscription/entities/billing-standard.entity';
import { PlanApiPolicy } from '../subscription/entities/plan-api-policy.entity';
import { UserFeatureUsage } from '../subscription/entities/user-feature-usage.entity';
import { SubscriptionService } from '../subscription/subscription.service';
import { PlanService } from '../plan/plan.service';
export declare class AdminService {
    private userRepo;
    private subscriptionRepo;
    private apiKeyRepo;
    private balanceRepo;
    private rechargeRepo;
    private apiUsageLogRepo;
    private planDefaultConfigRepo;
    private planFeatureQuotaRepo;
    private tokenPricingRepo;
    private billingStandardRepo;
    private planApiPolicyRepo;
    private userFeatureUsageRepo;
    private subscriptionService;
    private planService;
    constructor(userRepo: Repository<User>, subscriptionRepo: Repository<Subscription>, apiKeyRepo: Repository<ApiKey>, balanceRepo: Repository<UserBalance>, rechargeRepo: Repository<RechargeRecord>, apiUsageLogRepo: Repository<ApiUsageLog>, planDefaultConfigRepo: Repository<PlanDefaultConfig>, planFeatureQuotaRepo: Repository<PlanFeatureQuota>, tokenPricingRepo: Repository<TokenPricing>, billingStandardRepo: Repository<BillingStandard>, planApiPolicyRepo: Repository<PlanApiPolicy>, userFeatureUsageRepo: Repository<UserFeatureUsage>, subscriptionService: SubscriptionService, planService: PlanService);
    getStats(): Promise<{
        totalUsers: number;
        activeSubscriptions: number;
        apiKeyCount: number;
        totalRevenue: number;
    }>;
    getUsers(page?: number, limit?: number, search?: string): Promise<{
        items: {
            id: string;
            phone: string;
            email: string;
            nickname: string;
            status: string;
            role: string;
            createdAt: Date;
            subscriptionCount: number;
            balance: number;
        }[];
        total: number;
        page: number;
        totalPages: number;
    }>;
    createUser(data: {
        phone: string;
        password: string;
        nickname?: string;
        role?: string;
        status?: string;
    }): Promise<User>;
    getUserById(userId: string): Promise<User>;
    updateUser(userId: string, data: Partial<User>): Promise<User>;
    deleteUser(userId: string): Promise<{
        success: boolean;
    }>;
    getPlans(): Promise<{
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
    }[]>;
    createPlan(data: Partial<Plan>): Promise<{
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
    }>;
    updatePlan(planId: string, data: Partial<Plan>): Promise<{
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
    }>;
    deletePlan(planId: string): Promise<{
        success: boolean;
    }>;
    getSubscriptions(page?: number, limit?: number, status?: string): Promise<{
        items: {
            id: string;
            userId: string;
            userPhone: string;
            userNickname: string;
            planId: string;
            planName: string;
            status: string;
            startedAt: Date;
            expiresAt: Date;
            totalQuota: number;
            usedQuota: number;
            createdAt: Date;
        }[];
        total: number;
        page: number;
        totalPages: number;
    }>;
    updateSubscription(subId: string, data: Partial<Subscription>): Promise<Subscription>;
    getRechargeRecords(page?: number, limit?: number): Promise<{
        items: {
            id: string;
            userId: string;
            userPhone: string;
            amountCents: number;
            type: string;
            paymentMethod: string;
            status: string;
            remark: string;
            createdAt: Date;
        }[];
        total: number;
        page: number;
        totalPages: number;
    }>;
    getUserGrowth(days?: number): Promise<any[]>;
    assignPlanToUser(userId: string, planId: string): Promise<{
        id: string;
        userId: string;
        userPhone: string;
        userNickname: string;
        planId: string;
        planName: string;
        status: string;
        startedAt: Date;
        expiresAt: Date;
        totalQuota: number;
        usedQuota: number;
    }>;
    getRevenueTrend(days?: number): Promise<any[]>;
    getApiUsageLogs(page?: number, limit?: number, userId?: string, provider?: string): Promise<{
        items: {
            id: string;
            userId: string;
            userPhone: string;
            provider: string;
            model: string;
            promptTokens: number;
            completionTokens: number;
            quotaConsumed: number;
            createdAt: Date;
        }[];
        total: number;
        page: number;
        totalPages: number;
    }>;
    adjustUserQuota(userId: string, amount: number, reason?: string): Promise<{
        userId: string;
        amount: number;
        newTotalQuota: number;
        newRemainingQuota: number;
    }>;
    getRevenueStats(startDate?: string, endDate?: string): Promise<{
        totalRevenue: number;
        totalOrders: number;
        byPaymentMethod: {
            method: any;
            amount: number;
            count: number;
        }[];
        byDay: {
            date: any;
            amount: number;
            count: number;
        }[];
    }>;
    getPlanDefaultConfigs(planId: string): Promise<PlanDefaultConfig[]>;
    setPlanDefaultConfig(planId: string, data: {
        functionType: string;
        modelPattern: string;
        isActive?: boolean;
    }): Promise<PlanDefaultConfig>;
    deletePlanDefaultConfig(configId: string): Promise<{
        success: boolean;
    }>;
    getTokenPricing(): Promise<TokenPricing[]>;
    createTokenPricing(data: Partial<TokenPricing>): Promise<TokenPricing>;
    updateTokenPricing(id: string, data: Partial<TokenPricing>): Promise<TokenPricing>;
    deleteTokenPricing(id: string): Promise<{
        success: boolean;
    }>;
    getBillingStandards(): Promise<BillingStandard[]>;
    createBillingStandard(data: Partial<BillingStandard>): Promise<BillingStandard>;
    updateBillingStandard(id: string, data: Partial<BillingStandard>): Promise<BillingStandard>;
    deleteBillingStandard(id: string): Promise<{
        success: boolean;
    }>;
    getApiPolicies(planId?: string): Promise<PlanApiPolicy[]>;
    createApiPolicy(data: Partial<PlanApiPolicy>): Promise<PlanApiPolicy>;
    updateApiPolicy(id: string, data: Partial<PlanApiPolicy>): Promise<PlanApiPolicy>;
    deleteApiPolicy(id: string): Promise<{
        success: boolean;
    }>;
    getUserFeatureUsage(userId: string): Promise<{
        userId: string;
        subscriptions: {
            id: string;
            planId: string;
            planName: string;
            type: string;
            status: string;
            expiresAt: Date;
        }[];
        featureUsage: {
            featureType: string;
            usedAmount: number;
            totalAmount: number;
            remaining: number;
            unit: string;
        }[];
    }>;
}
