import { AiService } from './ai.service';
export declare class AiController {
    private readonly aiService;
    constructor(aiService: AiService);
    chat(req: any, body: {
        messages: Array<{
            role: string;
            content: string;
        }>;
        provider?: string;
        model?: string;
        stream?: boolean;
    }): Promise<{
        code: number;
        message: string;
        data: {
            content: any;
            model: any;
            provider: import("../api-key/entities/api-key.entity").ApiKeyProvider;
        };
        usage: {
            promptTokens: any;
            completionTokens: any;
            totalTokens: any;
            tokenConsumed: number;
            costYuan: number;
            balanceRemaining: number;
            freeTokensRemaining: number;
        };
    }>;
    transcribe(req: any, body: {
        audioUrl: string;
        provider?: string;
        language?: string;
    }): Promise<{
        code: number;
        message: string;
        data: {
            content: any;
            model: any;
            provider: import("../api-key/entities/api-key.entity").ApiKeyProvider;
        };
        usage: {
            promptTokens: any;
            completionTokens: any;
            totalTokens: any;
            tokenConsumed: number;
            costYuan: number;
            balanceRemaining: number;
            freeTokensRemaining: number;
        };
    }>;
    getUsage(req: any, startDate?: string, endDate?: string): Promise<{
        code: number;
        message: string;
        data: {
            totalCalls: number;
            totalTokens: number;
            totalQuotaConsumed: number;
            logs: {
                id: string;
                provider: string;
                model: string;
                promptTokens: number;
                completionTokens: number;
                tokenConsumed: number;
                createdAt: Date;
            }[];
        };
    }>;
}
