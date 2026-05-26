export declare class CreateApiKeyDto {
    provider: string;
    apiKey: string;
    model: string;
    rateLimitPerMin?: number;
    isActive?: boolean;
}
