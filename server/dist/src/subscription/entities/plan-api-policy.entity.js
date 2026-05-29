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
exports.PlanApiPolicy = void 0;
const typeorm_1 = require("typeorm");
const plan_entity_1 = require("./plan.entity");
let PlanApiPolicy = class PlanApiPolicy {
};
exports.PlanApiPolicy = PlanApiPolicy;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], PlanApiPolicy.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'plan_id' }),
    __metadata("design:type", String)
], PlanApiPolicy.prototype, "planId", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], PlanApiPolicy.prototype, "provider", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'model_pattern', nullable: true }),
    __metadata("design:type", String)
], PlanApiPolicy.prototype, "modelPattern", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'decimal', precision: 3, scale: 1, default: 1.0 }),
    __metadata("design:type", Number)
], PlanApiPolicy.prototype, "multiplier", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'is_allowed', default: true }),
    __metadata("design:type", Boolean)
], PlanApiPolicy.prototype, "isAllowed", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => plan_entity_1.Plan),
    (0, typeorm_1.JoinColumn)({ name: 'plan_id' }),
    __metadata("design:type", plan_entity_1.Plan)
], PlanApiPolicy.prototype, "plan", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ name: 'created_at' }),
    __metadata("design:type", Date)
], PlanApiPolicy.prototype, "createdAt", void 0);
exports.PlanApiPolicy = PlanApiPolicy = __decorate([
    (0, typeorm_1.Entity)('plan_api_policies')
], PlanApiPolicy);
//# sourceMappingURL=plan-api-policy.entity.js.map