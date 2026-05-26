export declare class ApiKey {
    id: string;
    provider: string;
    apiKeyEncrypted: string;
    model: string;
    isActive: boolean;
    rateLimitPerMin: number;
    createdAt: Date;
}
