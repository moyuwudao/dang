import { Repository } from 'typeorm';
import { Subscription } from './entities/subscription.entity';
import { Plan } from './entities/plan.entity';
import { UserTokenBalance } from './entities/user-token-balance.entity';
import { RechargeRecord } from './entities/recharge-record.entity';
import { ApiUsageLog } from './entities/api-usage-log.entity';
import { CreatePlanDto, RechargeDto } from './dto';
import { PlanService } from '../plan/plan.service';
export declare class SubscriptionService {
    private subscriptionRepository;
    private planRepository;
    private userTokenBalanceRepository;
    private rechargeRecordRepository;
    private apiUsageLogRepository;
    private planService;
    constructor(subscriptionRepository: Repository<Subscription>, planRepository: Repository<Plan>, userTokenBalanceRepository: Repository<UserTokenBalance>, rechargeRecordRepository: Repository<RechargeRecord>, apiUsageLogRepository: Repository<ApiUsageLog>, planService: PlanService);
    getSubscription(userId: string): Promise<{
        code: number;
        message: string;
        data: {
            planId: string;
            planName: string;
            status: string;
            expiresAt: Date;
            tokenQuota: number;
            usedTokens: number;
            balanceTokens: number;
            freeTokensRemaining: number;
        };
    }>;
    getPlans(type?: string): Promise<{
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
    createSubscription(userId: string, planId: string): Promise<{
        code: number;
        message: string;
        data: Subscription;
    }>;
    createPlan(dto: CreatePlanDto): Promise<{
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
    rechargeTokens(userId: string, dto: RechargeDto): Promise<{
        code: number;
        message: string;
        data: {
            tokensAdded: number;
            balanceTokens: number;
            amountCents: number;
        };
    }>;
    getBalance(userId: string): Promise<{
        code: number;
        message: string;
        data: {
            balanceTokens: number;
            freeTokensRemaining: number;
            totalTokens: number;
            usedTokens: number;
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
}
