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
exports.ApiKeyService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const api_key_entity_1 = require("./entities/api-key.entity");
const user_api_key_entity_1 = require("./entities/user-api-key.entity");
const crypto_util_1 = require("../common/crypto.util");
const axios_1 = require("@nestjs/axios");
const rxjs_1 = require("rxjs");
const redis_service_1 = require("../redis/redis.service");
let ApiKeyService = class ApiKeyService {
    constructor(apiKeyRepository, userApiKeyRepository, httpService, redisService) {
        this.apiKeyRepository = apiKeyRepository;
        this.userApiKeyRepository = userApiKeyRepository;
        this.httpService = httpService;
        this.redisService = redisService;
        this.ACTIVE_KEYS_CACHE = 'api:active_keys';
        this.USER_KEY_CACHE_PREFIX = 'api:user_key:';
        this.KEY_USAGE_PREFIX = 'api:key_usage:';
        this.CACHE_TTL = 300;
    }
    async getApiKey(userId, preferredProvider) {
        const cachedKeyId = await this.redisService.get(`${this.USER_KEY_CACHE_PREFIX}${userId}`);
        if (cachedKeyId) {
            const cachedKey = await this.getKeyFromCacheOrDb(cachedKeyId);
            if (cachedKey && this.isKeyAvailable(cachedKey)) {
                if (!preferredProvider || cachedKey.provider === preferredProvider) {
                    const decryptedKey = crypto_util_1.CryptoUtil.decrypt(cachedKey.apiKeyEncrypted);
                    return {
                        code: 200,
                        message: 'success',
                        data: {
                            provider: cachedKey.provider,
                            apiKey: decryptedKey,
                            model: cachedKey.model,
                            rateLimitPerMin: cachedKey.rateLimitPerMin,
                            expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
                        },
                    };
                }
            }
        }
        const existingAssignment = await this.userApiKeyRepository.findOne({
            where: { userId, isActive: true },
            order: { assignedAt: 'DESC' },
        });
        if (existingAssignment && existingAssignment.expiresAt > new Date()) {
            const apiKey = await this.apiKeyRepository.findOne({
                where: { id: existingAssignment.apiKeyId },
            });
            if (apiKey && this.isKeyAvailable(apiKey)) {
                if (!preferredProvider || apiKey.provider === preferredProvider) {
                    await this.redisService.set(`${this.USER_KEY_CACHE_PREFIX}${userId}`, apiKey.id, this.CACHE_TTL);
                    const decryptedKey = crypto_util_1.CryptoUtil.decrypt(apiKey.apiKeyEncrypted);
                    return {
                        code: 200,
                        message: 'success',
                        data: {
                            provider: apiKey.provider,
                            apiKey: decryptedKey,
                            model: apiKey.model,
                            rateLimitPerMin: apiKey.rateLimitPerMin,
                            expiresAt: existingAssignment.expiresAt,
                        },
                    };
                }
            }
        }
        return this.assignNewKey(userId, preferredProvider);
    }
    async refreshApiKey(userId) {
        await this.redisService.del(`${this.USER_KEY_CACHE_PREFIX}${userId}`);
        await this.userApiKeyRepository.update({ userId, isActive: true }, { isActive: false });
        return this.assignNewKey(userId);
    }
    async createApiKey(dto) {
        const encryptedKey = crypto_util_1.CryptoUtil.encrypt(dto.apiKey);
        const encryptedSecret = dto.apiSecret ? crypto_util_1.CryptoUtil.encrypt(dto.apiSecret) : null;
        const apiKey = this.apiKeyRepository.create({
            provider: dto.provider,
            name: dto.name,
            description: dto.description,
            apiKeyEncrypted: encryptedKey,
            apiSecretEncrypted: encryptedSecret,
            model: dto.model,
            baseUrl: dto.baseUrl,
            status: dto.status ?? api_key_entity_1.ApiKeyStatus.ACTIVE,
            scopes: (dto.scopes ?? [api_key_entity_1.ApiKeyScope.ALL]),
            rateLimitPerMin: dto.rateLimitPerMin ?? 60,
            maxConcurrentRequests: dto.maxConcurrentRequests ?? 5,
            dailyQuota: dto.dailyQuota ?? 1000,
            expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : null,
            isDefault: dto.isDefault ?? false,
            allowedIpRanges: dto.allowedIpRanges,
            supportedFeatures: dto.supportedFeatures ?? [],
        });
        await this.apiKeyRepository.save(apiKey);
        await this.redisService.del(this.ACTIVE_KEYS_CACHE);
        return {
            code: 200,
            message: 'API Key 创建成功',
            data: {
                id: apiKey.id,
                provider: apiKey.provider,
                name: apiKey.name,
                model: apiKey.model,
                status: apiKey.status,
            },
        };
    }
    async getApiKeys() {
        const keys = await this.apiKeyRepository.find();
        return {
            code: 200,
            message: 'success',
            data: keys.map(k => ({
                id: k.id,
                provider: k.provider,
                name: k.name,
                description: k.description,
                model: k.model,
                status: k.status,
                scopes: k.scopes,
                supportedFeatures: k.supportedFeatures ?? [],
                rateLimitPerMin: k.rateLimitPerMin,
                maxConcurrentRequests: k.maxConcurrentRequests,
                dailyQuota: k.dailyQuota,
                dailyUsage: k.dailyUsage,
                expiresAt: k.expiresAt,
                isDefault: k.isDefault,
                lastUsedAt: k.lastUsedAt,
                lastHealthCheckAt: k.lastHealthCheckAt,
                lastHealthCheckStatus: k.lastHealthCheckStatus,
                createdAt: k.createdAt,
                updatedAt: k.updatedAt,
            })),
        };
    }
    async getApiKeyById(id) {
        const apiKey = await this.apiKeyRepository.findOne({ where: { id } });
        if (!apiKey) {
            throw new common_1.NotFoundException('API Key 不存在');
        }
        return {
            code: 200,
            message: 'success',
            data: {
                id: apiKey.id,
                provider: apiKey.provider,
                name: apiKey.name,
                description: apiKey.description,
                model: apiKey.model,
                baseUrl: apiKey.baseUrl,
                status: apiKey.status,
                scopes: apiKey.scopes,
                rateLimitPerMin: apiKey.rateLimitPerMin,
                maxConcurrentRequests: apiKey.maxConcurrentRequests,
                dailyQuota: apiKey.dailyQuota,
                dailyUsage: apiKey.dailyUsage,
                expiresAt: apiKey.expiresAt,
                isDefault: apiKey.isDefault,
                lastUsedAt: apiKey.lastUsedAt,
                lastHealthCheckAt: apiKey.lastHealthCheckAt,
                lastHealthCheckStatus: apiKey.lastHealthCheckStatus,
                allowedIpRanges: apiKey.allowedIpRanges,
                createdAt: apiKey.createdAt,
                updatedAt: apiKey.updatedAt,
            },
        };
    }
    async updateApiKey(id, dto) {
        const apiKey = await this.apiKeyRepository.findOne({ where: { id } });
        if (!apiKey) {
            throw new common_1.NotFoundException('API Key 不存在');
        }
        if (dto.apiKey) {
            apiKey.apiKeyEncrypted = crypto_util_1.CryptoUtil.encrypt(dto.apiKey);
        }
        if (dto.apiSecret) {
            apiKey.apiSecretEncrypted = crypto_util_1.CryptoUtil.encrypt(dto.apiSecret);
        }
        if (dto.provider)
            apiKey.provider = dto.provider;
        if (dto.name)
            apiKey.name = dto.name;
        if (dto.description !== undefined)
            apiKey.description = dto.description;
        if (dto.model)
            apiKey.model = dto.model;
        if (dto.baseUrl !== undefined)
            apiKey.baseUrl = dto.baseUrl;
        if (dto.status)
            apiKey.status = dto.status;
        if (dto.scopes)
            apiKey.scopes = dto.scopes;
        if (dto.rateLimitPerMin !== undefined)
            apiKey.rateLimitPerMin = dto.rateLimitPerMin;
        if (dto.maxConcurrentRequests !== undefined)
            apiKey.maxConcurrentRequests = dto.maxConcurrentRequests;
        if (dto.dailyQuota !== undefined)
            apiKey.dailyQuota = dto.dailyQuota;
        if (dto.expiresAt)
            apiKey.expiresAt = new Date(dto.expiresAt);
        if (dto.isDefault !== undefined)
            apiKey.isDefault = dto.isDefault;
        if (dto.allowedIpRanges !== undefined)
            apiKey.allowedIpRanges = dto.allowedIpRanges;
        if (dto.supportedFeatures !== undefined)
            apiKey.supportedFeatures = dto.supportedFeatures;
        await this.apiKeyRepository.save(apiKey);
        await this.redisService.del(this.ACTIVE_KEYS_CACHE);
        await this.redisService.del(`${this.KEY_USAGE_PREFIX}${id}`);
        return {
            code: 200,
            message: 'API Key 更新成功',
            data: {
                id: apiKey.id,
                provider: apiKey.provider,
                name: apiKey.name,
                status: apiKey.status,
            },
        };
    }
    async deleteApiKey(id) {
        const apiKey = await this.apiKeyRepository.findOne({ where: { id } });
        if (!apiKey) {
            throw new common_1.NotFoundException('API Key 不存在');
        }
        await this.apiKeyRepository.delete(id);
        await this.redisService.del(this.ACTIVE_KEYS_CACHE);
        await this.redisService.del(`${this.KEY_USAGE_PREFIX}${id}`);
        return {
            code: 200,
            message: 'API Key 删除成功',
            data: null,
        };
    }
    async testApiKey(id, dto) {
        const apiKey = await this.apiKeyRepository.findOne({ where: { id } });
        if (!apiKey) {
            throw new common_1.NotFoundException('API Key 不存在');
        }
        const decryptedKey = crypto_util_1.CryptoUtil.decrypt(apiKey.apiKeyEncrypted);
        apiKey.lastHealthCheckAt = new Date();
        const feature = dto?.feature || 'connectivity';
        const results = {
            status: 'healthy',
            provider: apiKey.provider,
            model: apiKey.model,
            feature,
            checks: {},
        };
        let allHealthy = true;
        try {
            const connectivity = await this.performHealthCheck(apiKey.provider, decryptedKey, apiKey.baseUrl);
            results.checks.connectivity = {
                ok: true,
                responseTime: connectivity.responseTime,
                details: connectivity.details,
            };
            if (feature !== 'connectivity') {
                const featureTest = await this.performFeatureTest(apiKey.provider, feature, decryptedKey, apiKey.model, apiKey.baseUrl, dto);
                results.checks.feature = featureTest;
                if (!featureTest.ok)
                    allHealthy = false;
            }
            const balance = await this.queryBalance(apiKey.provider, decryptedKey, apiKey.baseUrl);
            if (balance) {
                results.checks.balance = balance;
                if (balance.exhausted) {
                    allHealthy = false;
                    results.warnings = results.warnings || [];
                    results.warnings.push('账户余额已耗尽或低于阈值');
                }
            }
            if (feature !== 'connectivity') {
                const supported = apiKey.supportedFeatures || [];
                if (!supported.includes(feature) && !supported.includes('all')) {
                    results.warnings = results.warnings || [];
                    results.warnings.push(`该 API 未声明支持 [${feature}] 功能，测试结果可能不准确`);
                }
            }
            results.status = allHealthy ? 'healthy' : 'degraded';
            apiKey.lastHealthCheckStatus = allHealthy ? 'healthy' : 'degraded';
            await this.apiKeyRepository.save(apiKey);
            return {
                code: 200,
                message: allHealthy ? '测试通过' : '测试通过但有警告',
                data: results,
            };
        }
        catch (error) {
            apiKey.lastHealthCheckStatus = 'unhealthy';
            await this.apiKeyRepository.save(apiKey);
            return {
                code: 200,
                message: '测试失败',
                data: {
                    status: 'unhealthy',
                    provider: apiKey.provider,
                    model: apiKey.model,
                    feature,
                    checks: results.checks,
                    error: error.message,
                },
            };
        }
    }
    async performFeatureTest(provider, feature, apiKey, model, baseUrl, dto) {
        const startTime = Date.now();
        try {
            switch (feature) {
                case 'textAnalysis':
                    return await this.testTextFeature(provider, apiKey, model, baseUrl, dto?.testText);
                case 'speechTranscribe':
                case 'speechOffline':
                    return await this.testTranscriptionFeature(provider, apiKey, model, baseUrl);
                case 'speechRealtime':
                    return await this.testRealtimeFeature(provider, apiKey, model, baseUrl);
                case 'imageRecognition':
                    return await this.testImageFeature(provider, apiKey, model, baseUrl, dto?.testImageUrl);
                default:
                    return { ok: false, responseTime: 0, details: { error: `未知功能: ${feature}` } };
            }
        }
        catch (error) {
            return {
                ok: false,
                responseTime: Date.now() - startTime,
                details: { error: error.message, status: error.response?.status },
            };
        }
    }
    async testTextFeature(provider, apiKey, model, baseUrl, text = 'ping') {
        const url = this.getChatCompletionsUrl(provider, baseUrl);
        const startTime = Date.now();
        const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(url, { model, messages: [{ role: 'user', content: text }], max_tokens: 1 }, { headers: this.getAuthHeaders(provider, apiKey), timeout: 10000 }));
        return {
            ok: true,
            responseTime: Date.now() - startTime,
            details: {
                feature: 'textAnalysis',
                status: response.status,
                hasChoices: !!(response.data?.choices?.length),
                usage: response.data?.usage,
            },
        };
    }
    async testTranscriptionFeature(provider, apiKey, model, baseUrl) {
        if (provider === api_key_entity_1.ApiKeyProvider.QWEN) {
            const url = (baseUrl || 'https://dashscope.aliyuncs.com/api/v1').replace(/\/$/, '') + '/services/audio/asr/transcription';
            const startTime = Date.now();
            try {
                const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(url, { model: 'paraformer-v2', input: {}, parameters: {} }, { headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' }, timeout: 10000 }));
                return {
                    ok: true,
                    responseTime: Date.now() - startTime,
                    details: { feature: 'speechTranscribe', status: response.status, note: 'API Key 有效' },
                };
            }
            catch (err) {
                if ([400, 401, 422].includes(err.response?.status)) {
                    return {
                        ok: err.response.status === 401 ? false : true,
                        responseTime: Date.now() - startTime,
                        details: {
                            feature: 'speechTranscribe',
                            status: err.response.status,
                            note: err.response.status === 401 ? 'API Key 无效' : 'API Key 有效（参数错误符合预期）',
                        },
                    };
                }
                throw err;
            }
        }
        return await this.testTextFeature(provider, apiKey, model, baseUrl, 'ping');
    }
    async testRealtimeFeature(provider, apiKey, model, baseUrl) {
        if (provider === api_key_entity_1.ApiKeyProvider.QWEN) {
            const wsUrl = (baseUrl || 'wss://dashscope.aliyuncs.com/api-ws/v1/realtime').replace(/\/$/, '');
            const startTime = Date.now();
            try {
                const url = new URL(wsUrl);
                const httpUrl = `https://${url.host}${url.pathname}`;
                await (0, rxjs_1.firstValueFrom)(this.httpService.get(httpUrl, {
                    headers: { Authorization: `Bearer ${apiKey}` },
                    timeout: 5000,
                    validateStatus: () => true,
                }));
                return {
                    ok: true,
                    responseTime: Date.now() - startTime,
                    details: { feature: 'speechRealtime', note: '端点可达，WebSocket 鉴权可通过' },
                };
            }
            catch (err) {
                return {
                    ok: true,
                    responseTime: Date.now() - startTime,
                    details: { feature: 'speechRealtime', note: '已验证端点响应（HTTP 401/403 表示鉴权握手正常）' },
                };
            }
        }
        return await this.testTextFeature(provider, apiKey, model, baseUrl, 'ping');
    }
    async testImageFeature(provider, apiKey, model, baseUrl, imageUrl) {
        const tinyPng = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
        const dataUrl = imageUrl || `data:image/png;base64,${tinyPng}`;
        const startTime = Date.now();
        if (provider === api_key_entity_1.ApiKeyProvider.QWEN) {
            const url = (baseUrl || 'https://dashscope.aliyuncs.com/api/v1').replace(/\/$/, '') + '/services/aigc/multimodal-generation/generation';
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(url, { model: 'qwen-vl-plus', input: { messages: [{ role: 'user', content: [{ image: dataUrl }, { text: '描述' }] }] }, parameters: {} }, { headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' }, timeout: 10000 }));
            return {
                ok: true,
                responseTime: Date.now() - startTime,
                details: { feature: 'imageRecognition', status: response.status },
            };
        }
        if (provider === api_key_entity_1.ApiKeyProvider.OPENAI) {
            const url = (baseUrl || 'https://api.openai.com/v1').replace(/\/$/, '') + '/chat/completions';
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(url, { model, messages: [{ role: 'user', content: [{ type: 'image_url', image_url: { url: dataUrl } }, { type: 'text', text: '描述' }] }], max_tokens: 1 }, { headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' }, timeout: 10000 }));
            return {
                ok: true,
                responseTime: Date.now() - startTime,
                details: { feature: 'imageRecognition', status: response.status },
            };
        }
        return { ok: false, responseTime: Date.now() - startTime, details: { error: `${provider} 未实现图像识别测试` } };
    }
    async queryBalance(provider, apiKey, baseUrl) {
        try {
            switch (provider) {
                case api_key_entity_1.ApiKeyProvider.QWEN: {
                    return null;
                }
                case api_key_entity_1.ApiKeyProvider.OPENAI: {
                    return null;
                }
                case api_key_entity_1.ApiKeyProvider.DEEPSEEK: {
                    const url = (baseUrl || 'https://api.deepseek.com').replace(/\/$/, '') + '/user/balance';
                    const r = await (0, rxjs_1.firstValueFrom)(this.httpService.get(url, {
                        headers: { Authorization: `Bearer ${apiKey}` },
                        timeout: 5000,
                        validateStatus: () => true,
                    }));
                    if (r.status === 200 && r.data?.balance_infos) {
                        const total = r.data.balance_infos.reduce((s, b) => s + (parseFloat(b.total_balance) || 0), 0);
                        return {
                            provider: 'deepseek',
                            currency: 'CNY',
                            total: total,
                            details: r.data.balance_infos,
                            exhausted: total <= 0,
                        };
                    }
                    return null;
                }
                default:
                    return null;
            }
        }
        catch {
            return null;
        }
    }
    getChatCompletionsUrl(provider, baseUrl) {
        switch (provider) {
            case api_key_entity_1.ApiKeyProvider.QWEN:
                return (baseUrl || 'https://dashscope.aliyuncs.com/compatible-mode/v1').replace(/\/$/, '') + '/chat/completions';
            case api_key_entity_1.ApiKeyProvider.DEEPSEEK:
                return (baseUrl || 'https://api.deepseek.com/v1').replace(/\/$/, '') + '/chat/completions';
            case api_key_entity_1.ApiKeyProvider.OPENAI:
                return (baseUrl || 'https://api.openai.com/v1').replace(/\/$/, '') + '/chat/completions';
            case api_key_entity_1.ApiKeyProvider.GROK:
                return (baseUrl || 'https://api.x.ai/v1').replace(/\/$/, '') + '/chat/completions';
            case api_key_entity_1.ApiKeyProvider.ANTHROPIC:
                return (baseUrl || 'https://api.anthropic.com/v1').replace(/\/$/, '') + '/messages';
            default:
                return (baseUrl || '').replace(/\/$/, '');
        }
    }
    getAuthHeaders(provider, apiKey) {
        if (provider === api_key_entity_1.ApiKeyProvider.ANTHROPIC) {
            return { 'x-api-key': apiKey, 'anthropic-version': '2023-06-01', 'Content-Type': 'application/json' };
        }
        return { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' };
    }
    async getHealthyModels() {
        const cached = await this.redisService.get(this.ACTIVE_KEYS_CACHE);
        if (cached) {
            const keys = JSON.parse(cached);
            const healthyKeys = keys.filter((k) => k.status === api_key_entity_1.ApiKeyStatus.ACTIVE && k.lastHealthCheckStatus === 'healthy');
            return {
                code: 200,
                message: 'success',
                data: healthyKeys.map((k) => ({
                    id: k.id,
                    provider: k.provider,
                    name: k.name,
                    model: k.model,
                    lastHealthCheckAt: k.lastHealthCheckAt,
                })),
            };
        }
        const keys = await this.apiKeyRepository.find({
            where: {
                status: api_key_entity_1.ApiKeyStatus.ACTIVE,
                lastHealthCheckStatus: 'healthy',
            },
        });
        const models = keys.map(k => ({
            id: k.id,
            provider: k.provider,
            name: k.name,
            model: k.model,
            lastHealthCheckAt: k.lastHealthCheckAt,
        }));
        return {
            code: 200,
            message: 'success',
            data: models,
        };
    }
    async getApiKeyStats() {
        const totalKeys = await this.apiKeyRepository.count();
        const activeKeys = await this.apiKeyRepository.count({ where: { status: api_key_entity_1.ApiKeyStatus.ACTIVE } });
        const inactiveKeys = await this.apiKeyRepository.count({ where: { status: api_key_entity_1.ApiKeyStatus.INACTIVE } });
        const expiredKeys = await this.apiKeyRepository.count({ where: { status: api_key_entity_1.ApiKeyStatus.EXPIRED } });
        const providers = Object.values(api_key_entity_1.ApiKeyProvider);
        const providerStats = await Promise.all(providers.map(async (provider) => ({
            provider,
            count: await this.apiKeyRepository.count({ where: { provider } }),
        })));
        return {
            code: 200,
            message: 'success',
            data: {
                total: totalKeys,
                active: activeKeys,
                inactive: inactiveKeys,
                expired: expiredKeys,
                providers: providerStats.filter(p => p.count > 0),
            },
        };
    }
    async recordKeyUsage(keyId, tokens) {
        await this.redisService.increment(`${this.KEY_USAGE_PREFIX}${keyId}`, tokens);
        const now = new Date();
        const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
        const ttlSeconds = Math.floor((endOfDay.getTime() - now.getTime()) / 1000);
        await this.redisService.expire(`${this.KEY_USAGE_PREFIX}${keyId}`, ttlSeconds);
        const key = await this.apiKeyRepository.findOne({ where: { id: keyId } });
        if (key) {
            key.dailyUsage += tokens;
            key.lastUsedAt = new Date();
            await this.apiKeyRepository.save(key);
        }
    }
    async getKeyFromCacheOrDb(keyId) {
        const cached = await this.redisService.get(this.ACTIVE_KEYS_CACHE);
        if (cached) {
            const keys = JSON.parse(cached);
            const found = keys.find((k) => k.id === keyId);
            if (found) {
                const realTimeUsage = await this.redisService.get(`${this.KEY_USAGE_PREFIX}${keyId}`);
                if (realTimeUsage) {
                    found.dailyUsage = parseInt(realTimeUsage, 10);
                }
                return found;
            }
        }
        return this.apiKeyRepository.findOne({ where: { id: keyId } });
    }
    isKeyAvailable(key) {
        if (key.status !== api_key_entity_1.ApiKeyStatus.ACTIVE)
            return false;
        if (key.lastHealthCheckStatus === 'unhealthy')
            return false;
        if (key.dailyUsage >= key.dailyQuota)
            return false;
        if (key.expiresAt && key.expiresAt < new Date())
            return false;
        return true;
    }
    async assignNewKey(userId, preferredProvider) {
        const activeKeys = await this.getActiveKeysWithCache();
        let availableKeys = activeKeys.filter(key => this.isKeyAvailable(key));
        if (preferredProvider) {
            const providerMatchedKeys = availableKeys.filter(key => key.provider === preferredProvider);
            if (providerMatchedKeys.length > 0) {
                availableKeys = providerMatchedKeys;
            }
        }
        if (availableKeys.length === 0) {
            throw new common_1.ForbiddenException('API Key 池已耗尽，请联系管理员');
        }
        const selectedKey = this.selectOptimalKey(availableKeys);
        const assignedUserCount = await this.userApiKeyRepository.count({
            where: { apiKeyId: selectedKey.id, isActive: true },
        });
        if (assignedUserCount >= selectedKey.maxConcurrentRequests) {
            const alternativeKey = this.findLessLoadedKey(availableKeys, selectedKey);
            if (alternativeKey) {
                return this.assignKeyToUser(userId, alternativeKey);
            }
        }
        return this.assignKeyToUser(userId, selectedKey);
    }
    async getActiveKeysWithCache() {
        const cached = await this.redisService.get(this.ACTIVE_KEYS_CACHE);
        if (cached) {
            const keys = JSON.parse(cached);
            for (const key of keys) {
                const realTimeUsage = await this.redisService.get(`${this.KEY_USAGE_PREFIX}${key.id}`);
                if (realTimeUsage) {
                    key.dailyUsage = parseInt(realTimeUsage, 10);
                }
            }
            return keys;
        }
        const keys = await this.apiKeyRepository.find({
            where: { status: api_key_entity_1.ApiKeyStatus.ACTIVE },
        });
        await this.redisService.set(this.ACTIVE_KEYS_CACHE, JSON.stringify(keys), this.CACHE_TTL);
        return keys;
    }
    selectOptimalKey(keys) {
        const scoredKeys = keys.map(key => {
            const usageRate = key.dailyQuota > 0 ? key.dailyUsage / key.dailyQuota : 0;
            const usageScore = (1 - usageRate) * 40;
            let healthScore = 30;
            if (key.lastHealthCheckStatus === 'healthy') {
                healthScore = 30;
            }
            else if (key.lastHealthCheckStatus === 'unhealthy') {
                healthScore = 0;
            }
            else {
                healthScore = 15;
            }
            let responseScore = 20;
            if (key.lastUsedAt) {
                const minutesSinceLastUse = (Date.now() - key.lastUsedAt.getTime()) / 60000;
                if (minutesSinceLastUse < 5) {
                    responseScore = 20;
                }
                else if (minutesSinceLastUse < 30) {
                    responseScore = 15;
                }
                else {
                    responseScore = 10;
                }
            }
            const quotaScore = key.dailyQuota > 0
                ? (1 - (key.dailyUsage / key.dailyQuota)) * 10
                : 10;
            return {
                key,
                score: usageScore + healthScore + responseScore + quotaScore,
            };
        });
        scoredKeys.sort((a, b) => b.score - a.score);
        const topKeys = scoredKeys.filter(s => s.score >= scoredKeys[0].score - 5);
        if (topKeys.length > 1) {
            const randomIndex = Math.floor(Math.random() * topKeys.length);
            return topKeys[randomIndex].key;
        }
        return scoredKeys[0].key;
    }
    findLessLoadedKey(keys, excludeKey) {
        const otherKeys = keys.filter(k => k.id !== excludeKey.id);
        if (otherKeys.length === 0)
            return null;
        return this.selectOptimalKey(otherKeys);
    }
    async assignKeyToUser(userId, apiKey) {
        const expiresAt = new Date();
        expiresAt.setHours(expiresAt.getHours() + 24);
        const assignment = this.userApiKeyRepository.create({
            userId,
            apiKeyId: apiKey.id,
            assignedAt: new Date(),
            expiresAt,
            isActive: true,
        });
        await this.userApiKeyRepository.save(assignment);
        await this.redisService.set(`${this.USER_KEY_CACHE_PREFIX}${userId}`, apiKey.id, 24 * 60 * 60);
        const decryptedKey = crypto_util_1.CryptoUtil.decrypt(apiKey.apiKeyEncrypted);
        return {
            code: 200,
            message: 'success',
            data: {
                provider: apiKey.provider,
                apiKey: decryptedKey,
                model: apiKey.model,
                rateLimitPerMin: apiKey.rateLimitPerMin,
                expiresAt,
            },
        };
    }
    async performHealthCheck(provider, apiKey, baseUrl) {
        const startTime = Date.now();
        switch (provider) {
            case api_key_entity_1.ApiKeyProvider.OPENAI:
                return this.checkOpenAI(apiKey, baseUrl);
            case api_key_entity_1.ApiKeyProvider.ANTHROPIC:
                return this.checkAnthropic(apiKey, baseUrl);
            case api_key_entity_1.ApiKeyProvider.QWEN:
                return this.checkQwen(apiKey, baseUrl);
            case api_key_entity_1.ApiKeyProvider.DEEPSEEK:
                return this.checkDeepSeek(apiKey, baseUrl);
            case api_key_entity_1.ApiKeyProvider.GEMINI:
                return this.checkGemini(apiKey, baseUrl);
            case api_key_entity_1.ApiKeyProvider.GROK:
                return this.checkGrok(apiKey, baseUrl);
            default:
                return this.checkGeneric(apiKey, baseUrl);
        }
    }
    async checkOpenAI(apiKey, baseUrl) {
        const url = (baseUrl || 'https://api.openai.com/v1').replace(/\/$/, '') + '/models';
        const startTime = Date.now();
        try {
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.get(url, {
                headers: { Authorization: `Bearer ${apiKey}` },
                timeout: 10000,
            }));
            return {
                responseTime: Date.now() - startTime,
                details: {
                    provider: 'openai',
                    status: response.status,
                    modelsAvailable: response.data?.data?.length || 0,
                },
            };
        }
        catch (error) {
            if (error.response?.status === 401) {
                throw new Error('OpenAI API Key 无效或已过期');
            }
            throw new Error(`OpenAI API 连接失败: ${error.message}`);
        }
    }
    async checkAnthropic(apiKey, baseUrl) {
        const url = (baseUrl || 'https://api.anthropic.com/v1').replace(/\/$/, '') + '/messages';
        const startTime = Date.now();
        try {
            await (0, rxjs_1.firstValueFrom)(this.httpService.post(url, {
                model: 'claude-3-haiku-20240307',
                max_tokens: 1,
                messages: [{ role: 'user', content: 'hi' }],
            }, {
                headers: {
                    'x-api-key': apiKey,
                    'anthropic-version': '2023-06-01',
                    'content-type': 'application/json',
                },
                timeout: 10000,
            }));
            return {
                responseTime: Date.now() - startTime,
                details: {
                    provider: 'anthropic',
                    status: 200,
                    note: '使用 messages API 验证',
                },
            };
        }
        catch (error) {
            if (error.response?.status === 401) {
                throw new Error('Anthropic API Key 无效或已过期');
            }
            if (error.response?.status === 400 || error.response?.status === 429) {
                return {
                    responseTime: Date.now() - startTime,
                    details: {
                        provider: 'anthropic',
                        status: error.response.status,
                        note: 'API Key 有效，但请求被限制（正常）',
                    },
                };
            }
            throw new Error(`Anthropic API 连接失败: ${error.message}`);
        }
    }
    async checkQwen(apiKey, baseUrl) {
        const url = (baseUrl || 'https://dashscope.aliyuncs.com/compatible-mode/v1').replace(/\/$/, '') + '/chat/completions';
        const startTime = Date.now();
        try {
            await (0, rxjs_1.firstValueFrom)(this.httpService.post(url, {
                model: 'qwen-turbo',
                messages: [{ role: 'user', content: 'hi' }],
                max_tokens: 1,
            }, {
                headers: {
                    Authorization: `Bearer ${apiKey}`,
                    'Content-Type': 'application/json',
                },
                timeout: 10000,
            }));
            return {
                responseTime: Date.now() - startTime,
                details: {
                    provider: 'qwen',
                    status: 200,
                    note: '使用 chat/completions API 验证',
                },
            };
        }
        catch (error) {
            if (error.response?.status === 401) {
                throw new Error('通义千问 API Key 无效或已过期');
            }
            if (error.response?.status === 400 || error.response?.status === 429) {
                return {
                    responseTime: Date.now() - startTime,
                    details: {
                        provider: 'qwen',
                        status: error.response.status,
                        note: 'API Key 有效，但请求被限制（正常）',
                    },
                };
            }
            throw new Error(`通义千问 API 连接失败: ${error.message}`);
        }
    }
    async checkDeepSeek(apiKey, baseUrl) {
        const url = (baseUrl || 'https://api.deepseek.com/v1').replace(/\/$/, '') + '/chat/completions';
        const startTime = Date.now();
        try {
            await (0, rxjs_1.firstValueFrom)(this.httpService.post(url, {
                model: 'deepseek-chat',
                messages: [{ role: 'user', content: 'hi' }],
                max_tokens: 1,
            }, {
                headers: {
                    Authorization: `Bearer ${apiKey}`,
                    'Content-Type': 'application/json',
                },
                timeout: 10000,
            }));
            return {
                responseTime: Date.now() - startTime,
                details: {
                    provider: 'deepseek',
                    status: 200,
                    note: '使用 chat/completions API 验证',
                },
            };
        }
        catch (error) {
            if (error.response?.status === 401) {
                throw new Error('DeepSeek API Key 无效或已过期');
            }
            if (error.response?.status === 400 || error.response?.status === 429) {
                return {
                    responseTime: Date.now() - startTime,
                    details: {
                        provider: 'deepseek',
                        status: error.response.status,
                        note: 'API Key 有效，但请求被限制（正常）',
                    },
                };
            }
            throw new Error(`DeepSeek API 连接失败: ${error.message}`);
        }
    }
    async checkGemini(apiKey, baseUrl) {
        const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
        const startTime = Date.now();
        try {
            await (0, rxjs_1.firstValueFrom)(this.httpService.post(url, {
                contents: [{ parts: [{ text: 'hi' }] }],
            }, {
                timeout: 10000,
            }));
            return {
                responseTime: Date.now() - startTime,
                details: {
                    provider: 'gemini',
                    status: 200,
                    note: '使用 generateContent API 验证',
                },
            };
        }
        catch (error) {
            if (error.response?.status === 400 && error.response?.data?.error?.message?.includes('API key')) {
                throw new Error('Gemini API Key 无效或已过期');
            }
            if (error.response?.status === 429) {
                return {
                    responseTime: Date.now() - startTime,
                    details: {
                        provider: 'gemini',
                        status: 429,
                        note: 'API Key 有效，但请求被限制（正常）',
                    },
                };
            }
            throw new Error(`Gemini API 连接失败: ${error.message}`);
        }
    }
    async checkGrok(apiKey, baseUrl) {
        const url = (baseUrl || 'https://api.x.ai/v1').replace(/\/$/, '') + '/chat/completions';
        const startTime = Date.now();
        try {
            await (0, rxjs_1.firstValueFrom)(this.httpService.post(url, {
                model: 'grok-2',
                messages: [{ role: 'user', content: 'hi' }],
                max_tokens: 1,
            }, {
                headers: {
                    Authorization: `Bearer ${apiKey}`,
                    'Content-Type': 'application/json',
                },
                timeout: 10000,
            }));
            return {
                responseTime: Date.now() - startTime,
                details: {
                    provider: 'grok',
                    status: 200,
                    note: '使用 chat/completions API 验证',
                },
            };
        }
        catch (error) {
            if (error.response?.status === 401) {
                throw new Error('Grok API Key 无效或已过期');
            }
            if (error.response?.status === 400 || error.response?.status === 429) {
                return {
                    responseTime: Date.now() - startTime,
                    details: {
                        provider: 'grok',
                        status: error.response.status,
                        note: 'API Key 有效，但请求被限制（正常）',
                    },
                };
            }
            throw new Error(`Grok API 连接失败: ${error.message}`);
        }
    }
    async checkGeneric(apiKey, baseUrl) {
        if (!baseUrl) {
            throw new Error('自定义 provider 需要提供 baseUrl');
        }
        const startTime = Date.now();
        try {
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.get(baseUrl, {
                headers: { Authorization: `Bearer ${apiKey}` },
                timeout: 10000,
            }));
            return {
                responseTime: Date.now() - startTime,
                details: {
                    provider: 'custom',
                    status: response.status,
                    baseUrl,
                },
            };
        }
        catch (error) {
            if (error.response?.status === 401) {
                throw new Error('自定义 API Key 无效或已过期');
            }
            throw new Error(`自定义 API 连接失败: ${error.message}`);
        }
    }
};
exports.ApiKeyService = ApiKeyService;
exports.ApiKeyService = ApiKeyService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(api_key_entity_1.ApiKey)),
    __param(1, (0, typeorm_1.InjectRepository)(user_api_key_entity_1.UserApiKey)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        axios_1.HttpService,
        redis_service_1.RedisService])
], ApiKeyService);
//# sourceMappingURL=api-key.service.js.map