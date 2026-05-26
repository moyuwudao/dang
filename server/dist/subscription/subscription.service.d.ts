import { Repository } from 'typeorm';
import { Subscription } from './entities/subscription.entity';
import { Plan } from './entities/plan.entity';
import { UserBalance } from './entities/user-balance.entity';
import { RechargeRecord } from './entities/recharge-record.entity';
import { CreatePlanDto, RechargeDto, RefundDto } from './dto';
export declare class SubscriptionService {
    private subscriptionRepository;
    private planRepository;
    private userBalanceRepository;
    private rechargeRecordRepository;
    constructor(subscriptionRepository: Repository<Subscription>, planRepository: Repository<Plan>, userBalanceRepository: Repository<UserBalance>, rechargeRecordRepository: Repository<RechargeRecord>);
    getSubscription(userId: string): Promise<{
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
        };
    }>;
    getPlans(type?: string): Promise<{
        code: number;
        message: string;
        data: Plan[];
    }>;
    createSubscription(userId: string, planId: string): Promise<{
        code: number;
        message: string;
        data: Subscription;
    }>;
    createPlan(dto: CreatePlanDto): Promise<{
        code: number;
        message: string;
        data: Plan;
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
}
