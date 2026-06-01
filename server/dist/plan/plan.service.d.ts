import { Repository } from 'typeorm';
import { Plan } from '../subscription/entities/plan.entity';
export declare class PlanService {
    private planRepo;
    constructor(planRepo: Repository<Plan>);
    getPlans(includeInactive?: boolean): Promise<{
        description: string;
        id: string;
        name: string;
        priceCents: number;
        tokenQuota: number;
        durationDays: number;
        type: string;
        isActive: boolean;
        allowedModels: string[];
    }[]>;
    getPlanById(planId: string): Promise<{
        description: string;
        id: string;
        name: string;
        priceCents: number;
        tokenQuota: number;
        durationDays: number;
        type: string;
        isActive: boolean;
        allowedModels: string[];
    }>;
    createPlan(data: Partial<Plan>): Promise<{
        description: string;
        id: string;
        name: string;
        priceCents: number;
        tokenQuota: number;
        durationDays: number;
        type: string;
        isActive: boolean;
        allowedModels: string[];
    }>;
    updatePlan(planId: string, data: Partial<Plan>): Promise<{
        description: string;
        id: string;
        name: string;
        priceCents: number;
        tokenQuota: number;
        durationDays: number;
        type: string;
        isActive: boolean;
        allowedModels: string[];
    }>;
    deletePlan(planId: string): Promise<{
        success: boolean;
    }>;
}
