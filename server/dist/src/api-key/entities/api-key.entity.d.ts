export declare enum ApiKeyProvider {
    QWEN = "qwen",
    OPENAI = "openai",
    ANTHROPIC = "anthropic",
    GEMINI = "gemini",
    DEEPSEEK = "deepseek",
    GROK = "grok",
    CUSTOM = "custom"
}
export declare enum ApiKeyStatus {
    ACTIVE = "active",
    INACTIVE = "inactive",
    EXPIRED = "expired",
    REVOKED = "revoked"
}
export declare enum ApiKeyScope {
    TRANSCRIPTION = "transcription",
    SUMMARY = "summary",
    CHAT = "chat",
    TRANSLATION = "translation",
    ALL = "all"
}
export declare class ApiKey {
    id: string;
    provider: ApiKeyProvider;
    name: string;
    description: string;
    apiKeyEncrypted: string;
    apiSecretEncrypted: string;
    model: string;
    baseUrl: string;
    status: ApiKeyStatus;
    scopes: ApiKeyScope[];
    rateLimitPerMin: number;
    maxConcurrentRequests: number;
    dailyQuota: number;
    dailyUsage: number;
    expiresAt: Date;
    isDefault: boolean;
    lastUsedAt: Date;
    lastHealthCheckAt: Date;
    lastHealthCheckStatus: string;
    allowedIpRanges: string;
    createdAt: Date;
    updatedAt: Date;
}
