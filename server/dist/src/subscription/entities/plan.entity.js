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
exports.Plan = void 0;
const typeorm_1 = require("typeorm");
const plan_feature_quota_entity_1 = require("./plan-feature-quota.entity");
let Plan = class Plan {
};
exports.Plan = Plan;
__decorate([
    (0, typeorm_1.PrimaryColumn)(),
    __metadata("design:type", String)
], Plan.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], Plan.prototype, "name", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Plan.prototype, "description", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'priceCents' }),
    __metadata("design:type", Number)
], Plan.prototype, "priceCents", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'durationDays' }),
    __metadata("design:type", Number)
], Plan.prototype, "durationDays", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: 'subscription' }),
    __metadata("design:type", String)
], Plan.prototype, "type", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'api_policy_type', default: 'all' }),
    __metadata("design:type", String)
], Plan.prototype, "apiPolicyType", void 0);
__decorate([
    (0, typeorm_1.Column)('simple-array', { nullable: true }),
    __metadata("design:type", Array)
], Plan.prototype, "features", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'isRecommended', default: false }),
    __metadata("design:type", Boolean)
], Plan.prototype, "isRecommended", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'quotaType' }),
    __metadata("design:type", String)
], Plan.prototype, "quotaType", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'quotaValue', nullable: true }),
    __metadata("design:type", Number)
], Plan.prototype, "quotaValue", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'isActive', default: true }),
    __metadata("design:type", Boolean)
], Plan.prototype, "isActive", void 0);
__decorate([
    (0, typeorm_1.Column)('simple-array', { name: 'allowed_models', nullable: true }),
    __metadata("design:type", Array)
], Plan.prototype, "allowedModels", void 0);
__decorate([
    (0, typeorm_1.OneToMany)(() => plan_feature_quota_entity_1.PlanFeatureQuota, quota => quota.plan),
    __metadata("design:type", Array)
], Plan.prototype, "featureQuotas", void 0);
exports.Plan = Plan = __decorate([
    (0, typeorm_1.Entity)('plans')
], Plan);
//# sourceMappingURL=plan.entity.js.map