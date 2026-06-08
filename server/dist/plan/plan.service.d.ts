import { Repository } from 'typeorm';
import { Plan } from '../subscription/entities/plan.entity';
export declare class PlanService {
    private planRepo;
    private readonly logger;
    constructor(planRepo: Repository<Plan>);
    getPlans(includeInactive?: boolean): Promise<{
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
    }[]>;
    getPlanById(planId: string): Promise<{
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
    }>;
    private normalizePlan;
    createPlan(data: Partial<Plan>): Promise<{
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
    }>;
    updatePlan(planId: string, data: Partial<Plan>): Promise<{
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
    }>;
    private toSnakeCase;
    private toColumnName;
    deletePlan(planId: string): Promise<{
        success: boolean;
    }>;
}
