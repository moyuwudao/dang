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
            expiresAt: Date;
            tokenQuota: number;
            usedTokens: number;
            balanceTokens: number;
            freeTokensRemaining: number;
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
    getBalance(req: any): Promise<{
        code: number;
        message: string;
        data: {
            balanceTokens: number;
            freeTokensRemaining: number;
            totalTokens: number;
            usedTokens: number;
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
}
