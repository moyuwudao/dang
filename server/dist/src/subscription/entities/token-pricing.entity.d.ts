export declare class TokenPricing {
    id: string;
    provider: string;
    modelPattern: string;
    modelName: string;
    featureType: string;
    billingUnit: string;
    promptPricePer1k: number;
    completionPricePer1k: number;
    currency: string;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
}
