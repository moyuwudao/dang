import { Repository } from 'typeorm';
import { User } from '../auth/entities/user.entity';
import { Plan } from '../subscription/entities/plan.entity';
import { Subscription } from '../subscription/entities/subscription.entity';
import { ApiKey } from '../api-key/entities/api-key.entity';
import { UserBalance } from '../subscription/entities/user-balance.entity';
import { RechargeRecord } from '../subscription/entities/recharge-record.entity';
import { SubscriptionService } from '../subscription/subscription.service';
export declare class AdminService {
    private userRepo;
    private planRepo;
    private subscriptionRepo;
    private apiKeyRepo;
    private balanceRepo;
    private rechargeRepo;
    private subscriptionService;
    constructor(userRepo: Repository<User>, planRepo: Repository<Plan>, subscriptionRepo: Repository<Subscription>, apiKeyRepo: Repository<ApiKey>, balanceRepo: Repository<UserBalance>, rechargeRepo: Repository<RechargeRecord>, subscriptionService: SubscriptionService);
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
    updateUser(userId: string, data: Partial<User>): Promise<User>;
    deleteUser(userId: string): Promise<{
        success: boolean;
    }>;
    getPlans(): Promise<Plan[]>;
    createPlan(data: Partial<Plan>): Promise<Plan>;
    updatePlan(planId: string, data: Partial<Plan>): Promise<Plan>;
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
    getRevenueTrend(days?: number): Promise<any[]>;
}
