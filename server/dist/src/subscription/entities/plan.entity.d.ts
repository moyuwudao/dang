import { PlanFeatureQuota } from './plan-feature-quota.entity';
export declare class Plan {
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
    allowedModels: string[];
    featureQuotas: PlanFeatureQuota[];
}
