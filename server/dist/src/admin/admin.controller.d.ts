import { AdminService } from './admin.service';
import { PlanService } from '../plan/plan.service';
export declare class AdminController {
    private readonly adminService;
    private readonly planService;
    constructor(adminService: AdminService, planService: PlanService);
    getStats(): Promise<{
        code: number;
        message: string;
        data: {
            totalUsers: number;
            activeSubscriptions: number;
            apiKeyCount: number;
            totalRevenue: number;
        };
    }>;
    getUsers(page?: string, limit?: string, search?: string): Promise<{
        code: number;
        message: string;
        data: {
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
        };
    }>;
    createUser(data: any): Promise<{
        code: number;
        message: string;
        data: import("../auth/entities/user.entity").User;
    }>;
    getUserById(id: string): Promise<{
        code: number;
        message: string;
        data: import("../auth/entities/user.entity").User;
    }>;
    updateUser(id: string, data: any): Promise<{
        code: number;
        message: string;
        data: import("../auth/entities/user.entity").User;
    }>;
    deleteUser(id: string): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    getPlans(): Promise<{
        code: number;
        message: string;
        data: {
            allowedModels: string[];
            featureQuotas: import("../subscription/entities/plan-feature-quota.entity").PlanFeatureQuota[];
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
    createPlan(data: any): Promise<{
        code: number;
        message: string;
        data: {
            allowedModels: string[];
            featureQuotas: import("../subscription/entities/plan-feature-quota.entity").PlanFeatureQuota[];
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
    updatePlan(id: string, data: any): Promise<{
        code: number;
        message: string;
        data: {
            allowedModels: string[];
            featureQuotas: import("../subscription/entities/plan-feature-quota.entity").PlanFeatureQuota[];
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
    deletePlan(id: string): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    getSubscriptions(page?: string, limit?: string, status?: string): Promise<{
        code: number;
        message: string;
        data: {
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
        };
    }>;
    updateSubscription(id: string, data: any): Promise<{
        code: number;
        message: string;
        data: import("../subscription/entities/subscription.entity").Subscription;
    }>;
    assignPlanToUser(userId: string, data: {
        planId: string;
    }): Promise<{
        code: number;
        message: string;
        data: {
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
        };
    }>;
    getRechargeRecords(page?: string, limit?: string): Promise<{
        code: number;
        message: string;
        data: {
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
        };
    }>;
    getUserGrowth(days?: string): Promise<{
        code: number;
        message: string;
        data: any[];
    }>;
    getRevenueTrend(days?: string): Promise<{
        code: number;
        message: string;
        data: any[];
    }>;
    getApiUsageLogs(page?: string, limit?: string, userId?: string, provider?: string): Promise<{
        code: number;
        message: string;
        data: {
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
        };
    }>;
    adjustUserQuota(userId: string, data: {
        amount: number;
        reason?: string;
    }): Promise<{
        code: number;
        message: string;
        data: {
            userId: string;
            amount: number;
            newTotalQuota: number;
            newRemainingQuota: number;
        };
    }>;
    getRevenueStats(startDate?: string, endDate?: string): Promise<{
        code: number;
        message: string;
        data: {
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
        };
    }>;
    getPlanDefaultConfigs(planId: string): Promise<{
        code: number;
        message: string;
        data: import("../subscription/entities/plan-default-config.entity").PlanDefaultConfig[];
    }>;
    setPlanDefaultConfig(planId: string, data: {
        functionType: string;
        modelPattern: string;
        isActive?: boolean;
    }): Promise<{
        code: number;
        message: string;
        data: import("../subscription/entities/plan-default-config.entity").PlanDefaultConfig;
    }>;
    deletePlanDefaultConfig(configId: string): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    getPlanFeatureQuotas(planId: string): Promise<{
        code: number;
        message: string;
        data: import("../subscription/entities/plan-feature-quota.entity").PlanFeatureQuota[];
    }>;
    setPlanFeatureQuota(planId: string, data: {
        featureType: string;
        quotaValue: number;
        quotaUnit: string;
        multiplier?: number;
    }): Promise<{
        code: number;
        message: string;
        data: import("../subscription/entities/plan-feature-quota.entity").PlanFeatureQuota;
    }>;
    deletePlanFeatureQuota(quotaId: string): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    getTokenPricing(): Promise<{
        code: number;
        message: string;
        data: import("../subscription/entities/token-pricing.entity").TokenPricing[];
    }>;
    createTokenPricing(data: any): Promise<{
        code: number;
        message: string;
        data: import("../subscription/entities/token-pricing.entity").TokenPricing;
    }>;
    updateTokenPricing(id: string, data: any): Promise<{
        code: number;
        message: string;
        data: import("../subscription/entities/token-pricing.entity").TokenPricing;
    }>;
    deleteTokenPricing(id: string): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    getUserFeatureUsage(userId: string): Promise<{
        code: number;
        message: string;
        data: {
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
        };
    }>;
}
