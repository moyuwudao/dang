import { Repository } from 'typeorm';
import { Subscription } from './entities/subscription.entity';
import { Plan } from './entities/plan.entity';
import { UserTokenBalance } from './entities/user-token-balance.entity';
import { RechargeRecord } from './entities/recharge-record.entity';
import { ApiUsageLog } from './entities/api-usage-log.entity';
import { CreatePlanDto, RechargeDto } from './dto';
import { PlanService } from '../plan/plan.service';
import { TokenBillingService } from './services/token-billing.service';
export declare class SubscriptionService {
    private subscriptionRepository;
    private planRepository;
    private userTokenBalanceRepository;
    private rechargeRecordRepository;
    private apiUsageLogRepository;
    private planService;
    private tokenBillingService;
    constructor(subscriptionRepository: Repository<Subscription>, planRepository: Repository<Plan>, userTokenBalanceRepository: Repository<UserTokenBalance>, rechargeRecordRepository: Repository<RechargeRecord>, apiUsageLogRepository: Repository<ApiUsageLog>, planService: PlanService, tokenBillingService: TokenBillingService);
    private pickApiPolicies;
    private buildDefaultConfigsArray;
    private deriveApiPoliciesFromPlan;
    getSubscription(userId: string): Promise<{
        code: number;
        message: string;
        data: {
            planId: string;
            planName: string;
            status: string;
            expiresAt: any;
            tokenQuota: number;
            usedTokens: number;
            totalQuota: number;
            usedQuota: number;
            quotaRemaining: number;
            balanceTokens: number;
            freeTokensRemaining: number;
            apiPolicies: any[];
            defaultConfigs: {
                functionType: string;
                modelPattern: string;
            }[];
            subscriptions: any[];
            rechargeBalance?: undefined;
        };
    } | {
        code: number;
        message: string;
        data: {
            planId: string;
            planName: any;
            status: string;
            expiresAt: Date;
            totalQuota: number;
            usedQuota: number;
            quotaRemaining: number;
            rechargeBalance: number;
            balanceTokens: number;
            freeTokensRemaining: number;
            apiPolicies: any[];
            defaultConfigs: {
                functionType: string;
                modelPattern: string;
            }[];
            subscriptions: any[];
            tokenQuota?: undefined;
            usedTokens?: undefined;
        };
    }>;
    private computeExpiresAt;
    private normalizePlan;
    getSubscriptionById(userId: string, subscriptionId: string): Promise<{
        code: number;
        message: string;
        data: {
            subscriptionId: string;
            planId: string;
            planName: any;
            status: string;
            expiresAt: Date;
            totalQuota: number;
            usedQuota: number;
            balanceTokens: number;
            freeTokensRemaining: number;
            apiPolicies: any[];
            defaultConfigs: {
                functionType: string;
                modelPattern: string;
            }[];
            allowedModels: any;
        };
    }>;
    getPlans(type?: string): Promise<{
        code: number;
        message: string;
        data: {
            allowedModels: string[];
            features: string[];
            defaultConfigs: Record<string, string>;
            apiPolicies: {
                provider: string;
                model?: string;
                modelPattern?: string;
                multiplier: number;
                isAllowed?: boolean;
            }[];
            description: string;
            id: string;
            name: string;
            priceCents: number;
            tokenQuota: number;
            durationDays: number;
            type: string;
            isActive: boolean;
            isRecommended: boolean;
            quotaType: string;
            quotaValue: number;
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
            features: string[];
            defaultConfigs: Record<string, string>;
            apiPolicies: {
                provider: string;
                model?: string;
                modelPattern?: string;
                multiplier: number;
                isAllowed?: boolean;
            }[];
            description: string;
            id: string;
            name: string;
            priceCents: number;
            tokenQuota: number;
            durationDays: number;
            type: string;
            isActive: boolean;
            isRecommended: boolean;
            quotaType: string;
            quotaValue: number;
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
            totalQuota: number;
            usedQuota: number;
            quotaRemaining: number;
            rechargeBalance: number;
            balanceTokens: number;
            freeTokensRemaining: number;
            totalTokens: number;
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
