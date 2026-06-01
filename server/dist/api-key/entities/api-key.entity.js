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
Object.defineProperty(exports, "__esModule", { value: true });
exports.ApiKey = exports.ApiKeyScope = exports.ApiKeyStatus = exports.ApiKeyProvider = void 0;
const typeorm_1 = require("typeorm");
var ApiKeyProvider;
(function (ApiKeyProvider) {
    ApiKeyProvider["QWEN"] = "qwen";
    ApiKeyProvider["OPENAI"] = "openai";
    ApiKeyProvider["ANTHROPIC"] = "anthropic";
    ApiKeyProvider["GEMINI"] = "gemini";
    ApiKeyProvider["DEEPSEEK"] = "deepseek";
    ApiKeyProvider["GROK"] = "grok";
    ApiKeyProvider["CUSTOM"] = "custom";
})(ApiKeyProvider || (exports.ApiKeyProvider = ApiKeyProvider = {}));
var ApiKeyStatus;
(function (ApiKeyStatus) {
    ApiKeyStatus["ACTIVE"] = "active";
    ApiKeyStatus["INACTIVE"] = "inactive";
    ApiKeyStatus["EXPIRED"] = "expired";
    ApiKeyStatus["REVOKED"] = "revoked";
})(ApiKeyStatus || (exports.ApiKeyStatus = ApiKeyStatus = {}));
var ApiKeyScope;
(function (ApiKeyScope) {
    ApiKeyScope["TRANSCRIPTION"] = "transcription";
    ApiKeyScope["SUMMARY"] = "summary";
    ApiKeyScope["CHAT"] = "chat";
    ApiKeyScope["TRANSLATION"] = "translation";
    ApiKeyScope["ALL"] = "all";
})(ApiKeyScope || (exports.ApiKeyScope = ApiKeyScope = {}));
let ApiKey = class ApiKey {
};
exports.ApiKey = ApiKey;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], ApiKey.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: ApiKeyProvider,
        default: ApiKeyProvider.CUSTOM,
    }),
    __metadata("design:type", String)
], ApiKey.prototype, "provider", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], ApiKey.prototype, "name", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], ApiKey.prototype, "description", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'apiKeyEncrypted' }),
    __metadata("design:type", String)
], ApiKey.prototype, "apiKeyEncrypted", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'apiSecretEncrypted', nullable: true }),
    __metadata("design:type", String)
], ApiKey.prototype, "apiSecretEncrypted", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], ApiKey.prototype, "model", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'base_url', nullable: true }),
    __metadata("design:type", String)
], ApiKey.prototype, "baseUrl", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: ApiKeyStatus,
        default: ApiKeyStatus.ACTIVE,
    }),
    __metadata("design:type", String)
], ApiKey.prototype, "status", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'simple-array', nullable: true }),
    __metadata("design:type", Array)
], ApiKey.prototype, "scopes", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'rate_limit_per_min', default: 60 }),
    __metadata("design:type", Number)
], ApiKey.prototype, "rateLimitPerMin", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'max_concurrent_requests', default: 5 }),
    __metadata("design:type", Number)
], ApiKey.prototype, "maxConcurrentRequests", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'daily_quota', default: 1000 }),
    __metadata("design:type", Number)
], ApiKey.prototype, "dailyQuota", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'daily_usage', default: 0 }),
    __metadata("design:type", Number)
], ApiKey.prototype, "dailyUsage", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'expires_at', type: 'date', nullable: true }),
    __metadata("design:type", Date)
], ApiKey.prototype, "expiresAt", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'is_default', default: false }),
    __metadata("design:type", Boolean)
], ApiKey.prototype, "isDefault", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'last_used_at', nullable: true }),
    __metadata("design:type", Date)
], ApiKey.prototype, "lastUsedAt", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'last_health_check_at', nullable: true }),
    __metadata("design:type", Date)
], ApiKey.prototype, "lastHealthCheckAt", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'last_health_check_status', nullable: true }),
    __metadata("design:type", String)
], ApiKey.prototype, "lastHealthCheckStatus", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'allowed_ip_ranges', nullable: true }),
    __metadata("design:type", String)
], ApiKey.prototype, "allowedIpRanges", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], ApiKey.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)(),
    __metadata("design:type", Date)
], ApiKey.prototype, "updatedAt", void 0);
exports.ApiKey = ApiKey = __decorate([
    (0, typeorm_1.Entity)('api_keys')
], ApiKey);
//# sourceMappingURL=api-key.entity.js.map