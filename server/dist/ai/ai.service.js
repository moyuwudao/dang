"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AiService = void 0;
const common_1 = require("@nestjs/common");
const axios_1 = require("@nestjs/axios");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const rxjs_1 = require("rxjs");
const api_key_service_1 = require("../api-key/api-key.service");
const subscription_service_1 = require("../subscription/subscription.service");
const redis_service_1 = require("../redis/redis.service");
const token_billing_service_1 = require("../subscription/services/token-billing.service");
const api_usage_log_entity_1 = require("../subscription/entities/api-usage-log.entity");
let AiService = class AiService {
    constructor(httpService, apiKeyService, subscriptionService, redisService, tokenBillingService, apiUsageLogRepository) {
        this.httpService = httpService;
        this.apiKeyService = apiKeyService;
        this.subscriptionService = subscriptionService;
        this.redisService = redisService;
        this.tokenBillingService = tokenBillingService;
        this.apiUsageLogRepository = apiUsageLogRepository;
    }
    async chat(userId, params) {
        const apiKeyResult = await this.apiKeyService.getApiKey(userId);
        if (!apiKeyResult.data?.apiKey) {
            throw new common_1.HttpException('未分配 API Key', 500);
        }
        const apiKey = apiKeyResult.data;
        try {
            const response = await this.callAiProvider(apiKey, params);
            const promptTokens = response.usage?.prompt_tokens || 0;
            const completionTokens = response.usage?.completion_tokens || 0;
            const totalTokens = promptTokens + completionTokens;
            const billingResult = await this.tokenBillingService.consumeToken(userId, {
                provider: apiKey.provider,
                model: params.model || response.model || 'unknown',
                rawAmount: totalTokens,
                promptTokens,
                completionTokens,
            });
            if (!billingResult.success) {
                console.warn(`Token计费失败: ${billingResult.message}`, { userId, totalTokens });
            }
            await this.apiUsageLogRepository.save({
                userId,
                provider: apiKey.provider,
                model: params.model || response.model || 'unknown',
                promptTokens,
                completionTokens,
                tokenConsumed: billingResult.tokenConsumed || totalTokens,
                costYuan: billingResult.costYuan || 0,
            });
            return {
                code: 200,
                message: 'success',
                data: {
                    content: response.choices?.[0]?.message?.content || '',
                    model: response.model,
                    provider: apiKey.provider,
                },
                usage: {
                    promptTokens,
                    completionTokens,
                    totalTokens,
                    tokenConsumed: billingResult.tokenConsumed,
                    costYuan: billingResult.costYuan,
                    balanceRemaining: billingResult.balanceRemaining,
                    freeTokensRemaining: billingResult.freeTokensRemaining,
                },
            };
        }
        catch (error) {
            throw new common_1.HttpException(`AI 服务调用失败: ${error.message}`, error.status || 500);
        }
    }
    async transcribe(userId, params) {
        return this.chat(userId, {
            messages: [{ role: 'user', content: `转写音频: ${params.audioUrl}` }],
            provider: params.provider,
        });
    }
    async getUsage(userId, startDate, endDate) {
        const query = this.apiUsageLogRepository.createQueryBuilder('log')
            .where('log.userId = :userId', { userId })
            .orderBy('log.createdAt', 'DESC');
        if (startDate) {
            query.andWhere('log.createdAt >= :startDate', { startDate: new Date(startDate) });
        }
        if (endDate) {
            query.andWhere('log.createdAt <= :endDate', { endDate: new Date(endDate) });
        }
        const logs = await query.getMany();
        const totalCalls = logs.length;
        const totalTokens = logs.reduce((sum, log) => sum + log.promptTokens + log.completionTokens, 0);
        const totalQuota = logs.reduce((sum, log) => sum + log.tokenConsumed, 0);
        return {
            code: 200,
            message: 'success',
            data: {
                totalCalls,
                totalTokens,
                totalQuotaConsumed: totalQuota,
                logs: logs.map(log => ({
                    id: log.id,
                    provider: log.provider,
                    model: log.model,
                    promptTokens: log.promptTokens,
                    completionTokens: log.completionTokens,
                    tokenConsumed: log.tokenConsumed,
                    createdAt: log.createdAt,
                })),
            },
        };
    }
    async callAiProvider(apiKey, params) {
        const url = apiKey.baseUrl || this.getDefaultBaseUrl(apiKey.provider);
        const model = params.model || apiKey.model || this.getDefaultModel(apiKey.provider);
        const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${url}/v1/chat/completions`, {
            model,
            messages: params.messages,
            stream: params.stream || false,
        }, {
            headers: {
                'Authorization': `Bearer ${apiKey.apiKey}`,
                'Content-Type': 'application/json',
            },
            timeout: 30000,
        }));
        return response.data;
    }
    getDefaultBaseUrl(provider) {
        const urls = {
            qwen: 'https://dashscope.aliyuncs.com/api',
            openai: 'https://api.openai.com',
            deepseek: 'https://api.deepseek.com',
            anthropic: 'https://api.anthropic.com',
            gemini: 'https://generativelanguage.googleapis.com',
            grok: 'https://api.x.ai',
        };
        return urls[provider] || 'https://api.openai.com';
    }
    getDefaultModel(provider) {
        const models = {
            qwen: 'qwen-plus',
            openai: 'gpt-3.5-turbo',
            deepseek: 'deepseek-chat',
            anthropic: 'claude-3-haiku-20240307',
            gemini: 'gemini-pro',
            grok: 'grok-beta',
        };
        return models[provider] || 'gpt-3.5-turbo';
    }
    async calculateQuotaConsumed(userId, provider, model, tokens) {
        const result = await this.tokenBillingService.consumeToken(userId, {
            provider,
            model,
            rawAmount: tokens,
            promptTokens: 0,
            completionTokens: tokens,
        });
        return result.tokenConsumed || tokens;
    }
};
exports.AiService = AiService;
exports.AiService = AiService = __decorate([
    (0, common_1.Injectable)(),
    __param(5, (0, typeorm_1.InjectRepository)(api_usage_log_entity_1.ApiUsageLog)),
    __metadata("design:paramtypes", [axios_1.HttpService,
        api_key_service_1.ApiKeyService,
        subscription_service_1.SubscriptionService,
        redis_service_1.RedisService,
        token_billing_service_1.TokenBillingService,
        typeorm_2.Repository])
], AiService);
//# sourceMappingURL=ai.service.js.map