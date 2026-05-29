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
            expiresAt: any;
            totalQuota: number;
            usedQuota: number;
            remainingQuota: number;
            balanceCents: number;
            apiPolicies?: undefined;
            defaultConfigs?: undefined;
        };
    } | {
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
            apiPolicies: {
                provider: string;
                model: string;
                modelPattern: string;
                multiplier: number;
                isAllowed: boolean;
            }[];
            defaultConfigs: {
                functionType: string;
                modelPattern: string;
            }[];
        };
    }>;
    createSubscription(req: any, dto: CreateSubscriptionDto): Promise<{
        code: number;
        message: string;
        data: import("./entities/subscription.entity").Subscription;
    }>;
    getPlanApiPolicies(planId: string): Promise<{
        code: number;
        message: string;
        data: import("./entities/plan-api-policy.entity").PlanApiPolicy[];
    }>;
    setPlanApiPolicy(planId: string, body: {
        provider: string;
        multiplier: number;
        modelPattern?: string;
    }): Promise<{
        code: number;
        message: string;
        data: import("./entities/plan-api-policy.entity").PlanApiPolicy;
    }>;
    deletePlanApiPolicy(planId: string, policyId: string): Promise<{
        code: number;
        message: string;
    }>;
    getPlans(type?: string): Promise<{
        code: number;
        message: string;
        data: {
            allowedModels: string[];
            featureQuotas: import("./entities/plan-feature-quota.entity").PlanFeatureQuota[];
            id: string;
            name: string;
            description: string;
            priceCents: number;
            durationDays: number;
            type: string;
            apiPolicyType: string;
            features: string[];
            isRecommended: boolean;
            quotaType: string;
            quotaValue: number;
            isActive: boolean;
        }[];
    }>;
    createPlan(dto: CreatePlanDto): Promise<{
        code: number;
        message: string;
        data: {
            allowedModels: string[];
            featureQuotas: import("./entities/plan-feature-quota.entity").PlanFeatureQuota[];
            id: string;
            name: string;
            description: string;
            priceCents: number;
            durationDays: number;
            type: string;
            apiPolicyType: string;
            features: string[];
            isRecommended: boolean;
            quotaType: string;
            quotaValue: number;
            isActive: boolean;
        };
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
    checkApiPermission(req: any, body: {
        provider: string;
        model: string;
    }): Promise<{
        code: number;
        message: string;
        data: {
            allowed: boolean;
            reason?: string;
        };
    }>;
    consumeQuotaWithApi(req: any, body: {
        provider: string;
        model: string;
        tokens?: {
            prompt: number;
            completion: number;
        };
    }): Promise<{
        code: number;
        message: string;
        data: {
            consumed: number;
            multiplier: number;
            remaining: number;
        };
    }>;
    checkFeature(req: any, body: {
        featureType: string;
        amount: number;
    }): Promise<{
        code: number;
        message: string;
        data: {
            canUse: boolean;
            reason?: string;
        };
    }>;
    consumeFeature(req: any, body: {
        featureType: string;
        amount: number;
        provider?: string;
        model?: string;
        tokens?: {
            prompt: number;
            completion: number;
        };
    }): Promise<{
        code: number;
        message: string;
        data: {
            success: boolean;
            consumed: number;
            remaining: number;
            costCents?: number;
            message?: string;
        };
    }>;
    getFeatureUsage(req: any): Promise<{
        code: number;
        message: string;
        data: any;
    }>;
    purchaseWithBalance(req: any, body: {
        planId: string;
    }): Promise<{
        code: number;
        message: string;
        data: {
            success: boolean;
            message: string;
            subscription?: import("./entities/subscription.entity").Subscription;
        };
    }>;
}
