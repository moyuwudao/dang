import { SubscriptionService } from './subscription.service';
import { CreateSubscriptionDto, CreatePlanDto, RechargeDto } from './dto';
export declare class SubscriptionController {
    private readonly subscriptionService;
    constructor(subscriptionService: SubscriptionService);
    getSubscription(req: any): Promise<{
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
    createSubscription(req: any, dto: CreateSubscriptionDto): Promise<{
        code: number;
        message: string;
        data: import("./entities/subscription.entity").Subscription;
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
    getBalance(req: any): Promise<{
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
    recharge(req: any, dto: RechargeDto): Promise<{
        code: number;
        message: string;
        data: {
            tokensAdded: number;
            balanceTokens: number;
            amountCents: number;
        };
    }>;
    getRechargeRecords(req: any): Promise<{
        code: number;
        message: string;
        data: import("./entities/recharge-record.entity").RechargeRecord[];
    }>;
    switchSubscription(req: any, subscriptionId: string): Promise<{
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
}
