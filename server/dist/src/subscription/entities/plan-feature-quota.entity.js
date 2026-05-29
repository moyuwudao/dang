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
exports.PlanFeatureQuota = void 0;
const typeorm_1 = require("typeorm");
const plan_entity_1 = require("./plan.entity");
let PlanFeatureQuota = class PlanFeatureQuota {
};
exports.PlanFeatureQuota = PlanFeatureQuota;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], PlanFeatureQuota.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'plan_id' }),
    __metadata("design:type", String)
], PlanFeatureQuota.prototype, "planId", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'feature_type' }),
    __metadata("design:type", String)
], PlanFeatureQuota.prototype, "featureType", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'quota_value' }),
    __metadata("design:type", Number)
], PlanFeatureQuota.prototype, "quotaValue", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'quota_unit' }),
    __metadata("design:type", String)
], PlanFeatureQuota.prototype, "quotaUnit", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: 1.0 }),
    __metadata("design:type", Number)
], PlanFeatureQuota.prototype, "multiplier", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => plan_entity_1.Plan, plan => plan.featureQuotas),
    (0, typeorm_1.JoinColumn)({ name: 'planId' }),
    __metadata("design:type", plan_entity_1.Plan)
], PlanFeatureQuota.prototype, "plan", void 0);
exports.PlanFeatureQuota = PlanFeatureQuota = __decorate([
    (0, typeorm_1.Entity)('plan_feature_quotas')
], PlanFeatureQuota);
//# sourceMappingURL=plan-feature-quota.entity.js.map