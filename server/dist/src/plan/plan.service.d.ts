import { Repository } from 'typeorm';
import { Plan } from '../subscription/entities/plan.entity';
import { PlanApiPolicy } from '../subscription/entities/plan-api-policy.entity';
import { PlanFeatureQuota } from '../subscription/entities/plan-feature-quota.entity';
export declare class PlanService {
    private planRepo;
    private planApiPolicyRepo;
    private planFeatureQuotaRepo;
    constructor(planRepo: Repository<Plan>, planApiPolicyRepo: Repository<PlanApiPolicy>, planFeatureQuotaRepo: Repository<PlanFeatureQuota>);
    getPlans(includeInactive?: boolean): Promise<{
        allowedModels: string[];
        featureQuotas: PlanFeatureQuota[];
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
    }[]>;
    getPlanById(planId: string): Promise<{
        allowedModels: string[];
        featureQuotas: PlanFeatureQuota[];
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
    }>;
    createPlan(data: Partial<Plan> & {
        featureQuotas?: any[];
    }): Promise<{
        allowedModels: string[];
        featureQuotas: PlanFeatureQuota[];
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
    }>;
    updatePlan(planId: string, data: Partial<Plan> & {
        featureQuotas?: any[];
    }): Promise<{
        allowedModels: string[];
        featureQuotas: PlanFeatureQuota[];
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
    }>;
    deletePlan(planId: string): Promise<{
        success: boolean;
    }>;
    getPlanFeatureQuotas(planId: string): Promise<PlanFeatureQuota[]>;
    setPlanFeatureQuota(planId: string, data: {
        featureType: string;
        quotaValue: number;
        quotaUnit: string;
        multiplier?: number;
    }): Promise<PlanFeatureQuota>;
    deletePlanFeatureQuota(quotaId: string): Promise<{
        success: boolean;
    }>;
    private enrichPlansWithModels;
}
