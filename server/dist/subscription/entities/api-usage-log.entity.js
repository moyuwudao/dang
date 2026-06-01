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
    (0, typeorm_1.Column)({ name: 'token_consumed', default: 0 }),
    __metadata("design:type", Number)
], ApiUsageLog.prototype, "tokenConsumed", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'api_coefficient', type: 'decimal', precision: 10, scale: 4, default: 1.0 }),
    __metadata("design:type", Number)
], ApiUsageLog.prototype, "apiCoefficient", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'cost_yuan', type: 'decimal', precision: 10, scale: 4, nullable: true }),
    __metadata("design:type", Number)
], ApiUsageLog.prototype, "costYuan", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ name: 'created_at' }),
    __metadata("design:type", Date)
], ApiUsageLog.prototype, "createdAt", void 0);
exports.ApiUsageLog = ApiUsageLog = __decorate([
    (0, typeorm_1.Entity)('api_usage_logs')
], ApiUsageLog);
//# sourceMappingURL=api-usage-log.entity.js.map