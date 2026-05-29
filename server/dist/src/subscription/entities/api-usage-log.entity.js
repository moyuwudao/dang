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
exports.ApiUsageLog = void 0;
const typeorm_1 = require("typeorm");
const subscription_entity_1 = require("./subscription.entity");
const api_key_entity_1 = require("../../api-key/entities/api-key.entity");
const user_entity_1 = require("../../auth/entities/user.entity");
let ApiUsageLog = class ApiUsageLog {
};
exports.ApiUsageLog = ApiUsageLog;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], ApiUsageLog.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'user_id' }),
    __metadata("design:type", String)
], ApiUsageLog.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'subscription_id', nullable: true }),
    __metadata("design:type", String)
], ApiUsageLog.prototype, "subscriptionId", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'api_key_id', nullable: true }),
    __metadata("design:type", String)
], ApiUsageLog.prototype, "apiKeyId", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], ApiUsageLog.prototype, "provider", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], ApiUsageLog.prototype, "model", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'prompt_tokens', default: 0 }),
    __metadata("design:type", Number)
], ApiUsageLog.prototype, "promptTokens", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'completion_tokens', default: 0 }),
    __metadata("design:type", Number)
], ApiUsageLog.prototype, "completionTokens", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'quota_consumed' }),
    __metadata("design:type", Number)
], ApiUsageLog.prototype, "quotaConsumed", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'cost_cents', nullable: true }),
    __metadata("design:type", Number)
], ApiUsageLog.prototype, "costCents", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'feature_type', nullable: true }),
    __metadata("design:type", String)
], ApiUsageLog.prototype, "featureType", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'resource_consumed', nullable: true }),
    __metadata("design:type", Number)
], ApiUsageLog.prototype, "resourceConsumed", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'unit', nullable: true }),
    __metadata("design:type", String)
], ApiUsageLog.prototype, "unit", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => user_entity_1.User),
    (0, typeorm_1.JoinColumn)({ name: 'user_id' }),
    __metadata("design:type", user_entity_1.User)
], ApiUsageLog.prototype, "user", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => subscription_entity_1.Subscription),
    (0, typeorm_1.JoinColumn)({ name: 'subscription_id' }),
    __metadata("design:type", subscription_entity_1.Subscription)
], ApiUsageLog.prototype, "subscription", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => api_key_entity_1.ApiKey),
    (0, typeorm_1.JoinColumn)({ name: 'api_key_id' }),
    __metadata("design:type", api_key_entity_1.ApiKey)
], ApiUsageLog.prototype, "apiKey", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ name: 'created_at' }),
    __metadata("design:type", Date)
], ApiUsageLog.prototype, "createdAt", void 0);
exports.ApiUsageLog = ApiUsageLog = __decorate([
    (0, typeorm_1.Entity)('api_usage_logs')
], ApiUsageLog);
//# sourceMappingURL=api-usage-log.entity.js.map