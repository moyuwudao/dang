import { SubscriptionService } from './subscription.service';
import { CreateSubscriptionDto, CreatePlanDto, RechargeDto, RefundDto } from './dto';
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
            totalQuota: number;
            usedQuota: number;
            remainingQuota: number;
            balanceCents: number;
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
        data: import("./entities/plan.entity").Plan[];
    }>;
    createPlan(dto: CreatePlanDto): Promise<{
        code: number;
        message: string;
        data: import("./entities/plan.entity").Plan;
    }>;
    useQuota(req: any, body: {
        amount: number;
    }): Promise<{
        code: number;
        message: string;
        data: {
            planId: string;
            usedQuota: number;
            remainingQuota: number;
        };
    }>;
    getBalance(req: any): Promise<{
        code: number;
        message: string;
        data: {
            balanceCents: number;
            totalRechargedCents: number;
            totalRefundedCents: number;
        };
    }>;
    recharge(req: any, dto: RechargeDto): Promise<{
        code: number;
        message: string;
        data: {
            balanceCents: number;
            amountCents: number;
        };
    }>;
    refund(req: any, dto: RefundDto): Promise<{
        code: number;
        message: string;
        data: {
            balanceCents: number;
            amountCents: number;
        };
    }>;
    getRechargeRecords(req: any): Promise<{
        code: number;
        message: string;
        data: import("./entities/recharge-record.entity").RechargeRecord[];
    }>;
}
