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
exports.TokenPricing = void 0;
const typeorm_1 = require("typeorm");
let TokenPricing = class TokenPricing {
};
exports.TokenPricing = TokenPricing;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], TokenPricing.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'provider' }),
    __metadata("design:type", String)
], TokenPricing.prototype, "provider", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'model_pattern' }),
    __metadata("design:type", String)
], TokenPricing.prototype, "modelPattern", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'model_name', nullable: true }),
    __metadata("design:type", String)
], TokenPricing.prototype, "modelName", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'feature_type', default: 'ai_chat' }),
    __metadata("design:type", String)
], TokenPricing.prototype, "featureType", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'billing_unit', default: 'tokens' }),
    __metadata("design:type", String)
], TokenPricing.prototype, "billingUnit", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'prompt_price_per_1k', type: 'decimal', precision: 10, scale: 6, default: 0 }),
    __metadata("design:type", Number)
], TokenPricing.prototype, "promptPricePer1k", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'completion_price_per_1k', type: 'decimal', precision: 10, scale: 6, default: 0 }),
    __metadata("design:type", Number)
], TokenPricing.prototype, "completionPricePer1k", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'currency', default: 'CNY' }),
    __metadata("design:type", String)
], TokenPricing.prototype, "currency", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'is_active', default: true }),
    __metadata("design:type", Boolean)
], TokenPricing.prototype, "isActive", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ name: 'created_at' }),
    __metadata("design:type", Date)
], TokenPricing.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ name: 'updated_at' }),
    __metadata("design:type", Date)
], TokenPricing.prototype, "updatedAt", void 0);
exports.TokenPricing = TokenPricing = __decorate([
    (0, typeorm_1.Entity)('token_pricing')
], TokenPricing);
//# sourceMappingURL=token-pricing.entity.js.map