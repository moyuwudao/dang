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
exports.Subscription = void 0;
const typeorm_1 = require("typeorm");
const user_entity_1 = require("../../auth/entities/user.entity");
const plan_entity_1 = require("./plan.entity");
let Subscription = class Subscription {
};
exports.Subscription = Subscription;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], Subscription.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'userId' }),
    __metadata("design:type", String)
], Subscription.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'planId' }),
    __metadata("design:type", String)
], Subscription.prototype, "planId", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: 'active' }),
    __metadata("design:type", String)
], Subscription.prototype, "status", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'startedAt', type: 'timestamp' }),
    __metadata("design:type", Date)
], Subscription.prototype, "startedAt", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'expiresAt', type: 'timestamp' }),
    __metadata("design:type", Date)
], Subscription.prototype, "expiresAt", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'totalQuota', default: 0 }),
    __metadata("design:type", Number)
], Subscription.prototype, "totalQuota", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'usedQuota', default: 0 }),
    __metadata("design:type", Number)
], Subscription.prototype, "usedQuota", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'balance_quota', default: 0 }),
    __metadata("design:type", Number)
], Subscription.prototype, "balanceQuota", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: 'subscription' }),
    __metadata("design:type", String)
], Subscription.prototype, "type", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => user_entity_1.User, user => user.subscriptions),
    (0, typeorm_1.JoinColumn)({ name: 'userId' }),
    __metadata("design:type", user_entity_1.User)
], Subscription.prototype, "user", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => plan_entity_1.Plan),
    (0, typeorm_1.JoinColumn)({ name: 'planId' }),
    __metadata("design:type", plan_entity_1.Plan)
], Subscription.prototype, "plan", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], Subscription.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)(),
    __metadata("design:type", Date)
], Subscription.prototype, "updatedAt", void 0);
exports.Subscription = Subscription = __decorate([
    (0, typeorm_1.Entity)('subscriptions')
], Subscription);
//# sourceMappingURL=subscription.entity.js.map