import { AdminService } from './admin.service';
export declare class AdminController {
    private readonly adminService;
    constructor(adminService: AdminService);
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
        data: import("../subscription/entities/plan.entity").Plan[];
    }>;
    createPlan(data: any): Promise<{
        code: number;
        message: string;
        data: import("../subscription/entities/plan.entity").Plan;
    }>;
    updatePlan(id: string, data: any): Promise<{
        code: number;
        message: string;
        data: import("../subscription/entities/plan.entity").Plan;
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
}
