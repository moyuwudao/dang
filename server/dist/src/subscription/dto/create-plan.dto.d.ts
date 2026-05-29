export declare class PlanFeatureQuotaDto {
    featureType: string;
    quotaValue: number;
    quotaUnit: string;
    multiplier?: number;
}
export declare class CreatePlanDto {
    id: string;
    name: string;
    description?: string;
    priceCents: number;
    durationDays: number;
    type?: string;
    features?: string[];
    isRecommended?: boolean;
    quotaType: string;
    quotaValue?: number;
    isActive?: boolean;
    allowedModels?: string[];
    featureQuotas?: PlanFeatureQuotaDto[];
}
