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
exports.BillingStandard = void 0;
const typeorm_1 = require("typeorm");
let BillingStandard = class BillingStandard {
};
exports.BillingStandard = BillingStandard;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], BillingStandard.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'plan_id', nullable: true }),
    __metadata("design:type", String)
], BillingStandard.prototype, "planId", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'function_type' }),
    __metadata("design:type", String)
], BillingStandard.prototype, "functionType", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], BillingStandard.prototype, "tier", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'base_price_cents', type: 'int', nullable: true }),
    __metadata("design:type", Number)
], BillingStandard.prototype, "basePriceCents", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], BillingStandard.prototype, "unit", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], BillingStandard.prototype, "provider", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'model_pattern', nullable: true }),
    __metadata("design:type", String)
], BillingStandard.prototype, "modelPattern", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'pricing_model', nullable: true }),
    __metadata("design:type", String)
], BillingStandard.prototype, "pricingModel", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'is_active', default: true }),
    __metadata("design:type", Boolean)
], BillingStandard.prototype, "isActive", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], BillingStandard.prototype, "notes", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ name: 'created_at' }),
    __metadata("design:type", Date)
], BillingStandard.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ name: 'updated_at' }),
    __metadata("design:type", Date)
], BillingStandard.prototype, "updatedAt", void 0);
exports.BillingStandard = BillingStandard = __decorate([
    (0, typeorm_1.Entity)('billing_standards')
], BillingStandard);
//# sourceMappingURL=billing-standard.entity.js.map