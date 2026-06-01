import { AdminService } from './admin.service';
import { PlanService } from '../plan/plan.service';
import { ApiKeyService } from '../api-key/api-key.service';
import { MonitorService } from '../monitor/monitor.service';
import { MetricsService } from '../monitor/metrics.service';
import { CreateApiKeyDto } from '../api-key/dto';
export declare class AdminController {
    private readonly adminService;
    private readonly planService;
    private readonly apiKeyService;
    private readonly monitorService?;
    private readonly metricsService?;
    constructor(adminService: AdminService, planService: PlanService, apiKeyService: ApiKeyService, monitorService?: MonitorService, metricsService?: MetricsService);
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
                balanceTokens: number;
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
            description: string;
            id: string;
            name: string;
            priceCents: number;
            tokenQuota: number;
            durationDays: number;
            type: string;
            isActive: boolean;
            allowedModels: string[];
        }[];
    }>;
    getPlanById(id: string): Promise<{
        code: number;
        message: string;
        data: {
            description: string;
            id: string;
            name: string;
            priceCents: number;
            tokenQuota: number;
            durationDays: number;
            type: string;
            isActive: boolean;
            allowedModels: string[];
        };
    }>;
    createPlan(data: any): Promise<{
        code: number;
        message: string;
        data: {
            description: string;
            id: string;
            name: string;
            priceCents: number;
            tokenQuota: number;
            durationDays: number;
            type: string;
            isActive: boolean;
            allowedModels: string[];
        };
    }>;
    updatePlan(id: string, data: any): Promise<{
        code: number;
        message: string;
        data: {
            description: string;
            id: string;
            name: string;
            priceCents: number;
            tokenQuota: number;
            durationDays: number;
            type: string;
            isActive: boolean;
            allowedModels: string[];
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
            tokenQuota: number;
            usedTokens: number;
        };
    }>;
    getRechargeRecords(page?: string, limit?: string): Promise<{
        code: number;
        message: string;
        data: {
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
        };
    }>;
    adjustUserTokens(userId: string, data: {
        amount: number;
        reason?: string;
    }): Promise<{
        code: number;
        message: string;
        data: {
            userId: string;
            amount: number;
            newBalanceTokens: number;
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
    getApiConfigs(): Promise<{
        code: number;
        message: string;
        data: import("../subscription/entities/api-config.entity").ApiConfig[];
    }>;
    createApiConfig(data: any): Promise<{
        code: number;
        message: string;
        data: import("../subscription/entities/api-config.entity").ApiConfig;
    }>;
    updateApiConfig(id: string, data: any): Promise<{
        code: number;
        message: string;
        data: import("../subscription/entities/api-config.entity").ApiConfig;
    }>;
    deleteApiConfig(id: string): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    getApiKeys(): Promise<{
        code: number;
        message: string;
        data: {
            id: string;
            provider: import("../api-key/entities/api-key.entity").ApiKeyProvider;
            name: string;
            description: string;
            model: string;
            status: import("../api-key/entities/api-key.entity").ApiKeyStatus;
            scopes: import("../api-key/entities/api-key.entity").ApiKeyScope[];
            rateLimitPerMin: number;
            maxConcurrentRequests: number;
            dailyQuota: number;
            dailyUsage: number;
            expiresAt: Date;
            isDefault: boolean;
            lastUsedAt: Date;
            lastHealthCheckAt: Date;
            lastHealthCheckStatus: string;
            createdAt: Date;
            updatedAt: Date;
        }[];
    }>;
    getApiKeyStats(): Promise<{
        code: number;
        message: string;
        data: {
            total: number;
            active: number;
            inactive: number;
            expired: number;
            providers: {
                provider: import("../api-key/entities/api-key.entity").ApiKeyProvider;
                count: number;
            }[];
        };
    }>;
    createApiKey(dto: CreateApiKeyDto): Promise<{
        code: number;
        message: string;
        data: {
            id: string;
            provider: import("../api-key/entities/api-key.entity").ApiKeyProvider;
            name: string;
            model: string;
            status: import("../api-key/entities/api-key.entity").ApiKeyStatus;
        };
    }>;
    batchCreateApiKeys(body: {
        keys: CreateApiKeyDto[];
    }): Promise<{
        code: number;
        message: string;
        data: any[];
    }>;
    testApiKey(id: string): Promise<{
        code: number;
        message: string;
        data: {
            status: string;
            provider: import("../api-key/entities/api-key.entity").ApiKeyProvider;
            model: string;
            responseTime: number;
            details: any;
            error?: undefined;
        };
    } | {
        code: number;
        message: string;
        data: {
            status: string;
            provider: import("../api-key/entities/api-key.entity").ApiKeyProvider;
            model: string;
            error: any;
            responseTime?: undefined;
            details?: undefined;
        };
    }>;
    updateApiKey(id: string, dto: Partial<CreateApiKeyDto>): Promise<{
        code: number;
        message: string;
        data: {
            id: string;
            provider: import("../api-key/entities/api-key.entity").ApiKeyProvider;
            name: string;
            status: import("../api-key/entities/api-key.entity").ApiKeyStatus;
        };
    }>;
    deleteApiKey(id: string): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    getRealtimeMetrics(): Promise<{
        code: number;
        message: string;
        data: import("../monitor/metrics.service").MetricsData;
    }>;
    getTrendData(days?: string): Promise<{
        code: number;
        message: string;
        data: any[];
    }>;
    getSystemInfo(): Promise<{
        code: number;
        message: string;
        data: {
            hostname: string;
            platform: string;
            uptime: number;
            cpu: {
                usage: number;
                cores: number;
                model: string;
            };
            memory: {
                total: number;
                used: number;
                free: number;
                usagePercent: number;
            };
            disk: {
                total: number;
                used: number;
                free: number;
                usagePercent: number;
            };
            load: number[];
            timestamp: number;
        };
    }>;
    getServices(): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    getMonitorLogs(service: string, lines?: string): Promise<{
        code: number;
        message: string;
        data: {
            logs: any;
        };
    }>;
    executeCommand(body: {
        command: string;
        timeout?: number;
    }): Promise<{
        code: number;
        message: string;
        data: {
            output: any;
        };
    }>;
}
