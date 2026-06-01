import { Repository } from 'typeorm';
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
export declare class AdminService {
    private userRepo;
    private subscriptionRepo;
    private apiKeyRepo;
    private rechargeRepo;
    private apiUsageLogRepo;
    private tokenPricingRepo;
    private apiConfigRepo;
    private userTokenBalanceRepo;
    private subscriptionService;
    private planService;
    constructor(userRepo: Repository<User>, subscriptionRepo: Repository<Subscription>, apiKeyRepo: Repository<ApiKey>, rechargeRepo: Repository<RechargeRecord>, apiUsageLogRepo: Repository<ApiUsageLog>, tokenPricingRepo: Repository<TokenPricing>, apiConfigRepo: Repository<ApiConfig>, userTokenBalanceRepo: Repository<UserTokenBalance>, subscriptionService: SubscriptionService, planService: PlanService);
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
            balanceTokens: number;
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
        description: string;
        id: string;
        name: string;
        priceCents: number;
        tokenQuota: number;
        durationDays: number;
        type: string;
        isActive: boolean;
        allowedModels: string[];
    }[]>;
    createPlan(data: Partial<Plan>): Promise<{
        description: string;
        id: string;
        name: string;
        priceCents: number;
        tokenQuota: number;
        durationDays: number;
        type: string;
        isActive: boolean;
        allowedModels: string[];
    }>;
    updatePlan(planId: string, data: Partial<Plan>): Promise<{
        description: string;
        id: string;
        name: string;
        priceCents: number;
        tokenQuota: number;
        durationDays: number;
        type: string;
        isActive: boolean;
        allowedModels: string[];
    }>;
    deletePlan(planId: string): Promise<{
        success: boolean;
    }>;
    getSubscriptions(page?: number, limit?: number, status?: string): Promise<{
        items: {
            id: string;
            userId: string;
            planId: string;
            status: string;
            startedAt: Date;
            expiresAt: Date;
            tokenQuota: number;
            usedTokens: number;
            balanceTokens: number;
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
        tokenQuota: number;
        usedTokens: number;
    }>;
    getRevenueTrend(days?: number): Promise<any[]>;
    getApiUsageLogs(page?: number, limit?: number, userId?: string, provider?: string): Promise<{
        items: {
            id: string;
            userId: string;
            provider: string;
            model: string;
            promptTokens: number;
            completionTokens: number;
            tokenConsumed: number;
            apiCoefficient: number;
            costYuan: number;
            createdAt: Date;
        }[];
        total: number;
        page: number;
        totalPages: number;
    }>;
    adjustUserTokens(userId: string, amount: number, reason?: string): Promise<{
        userId: string;
        amount: number;
        newBalanceTokens: number;
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
    getTokenPricing(): Promise<TokenPricing[]>;
    createTokenPricing(data: Partial<TokenPricing>): Promise<TokenPricing>;
    updateTokenPricing(id: string, data: Partial<TokenPricing>): Promise<TokenPricing>;
    deleteTokenPricing(id: string): Promise<{
        success: boolean;
    }>;
    getApiConfigs(): Promise<ApiConfig[]>;
    createApiConfig(data: Partial<ApiConfig>): Promise<ApiConfig>;
    updateApiConfig(id: string, data: Partial<ApiConfig>): Promise<ApiConfig>;
    deleteApiConfig(id: string): Promise<{
        success: boolean;
    }>;
}
