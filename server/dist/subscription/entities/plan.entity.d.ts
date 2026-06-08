export declare class Plan {
    id: string;
    name: string;
    description: string;
    priceCents: number;
    tokenQuota: number;
    durationDays: number;
    type: string;
    isActive: boolean;
    isRecommended: boolean;
    quotaType: string;
    quotaValue: number;
    features: string;
    allowedModels: string;
    defaultConfigs: Record<string, string>;
    apiPolicies: Array<{
        provider: string;
        model?: string;
        modelPattern?: string;
        multiplier: number;
        isAllowed?: boolean;
    }>;
}
