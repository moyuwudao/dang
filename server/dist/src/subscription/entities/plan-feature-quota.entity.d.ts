import { Plan } from './plan.entity';
export declare class PlanFeatureQuota {
    id: string;
    planId: string;
    featureType: string;
    quotaValue: number;
    quotaUnit: string;
    multiplier: number;
    plan: Plan;
}
