export declare class ApiUsageLog {
    id: string;
    userId: string;
    provider: string;
    model: string;
    promptTokens: number;
    completionTokens: number;
    tokenConsumed: number;
    apiCoefficient: number;
    costYuan: number;
    createdAt: Date;
}
