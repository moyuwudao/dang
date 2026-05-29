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
exports.UserFeatureUsage = void 0;
const typeorm_1 = require("typeorm");
let UserFeatureUsage = class UserFeatureUsage {
};
exports.UserFeatureUsage = UserFeatureUsage;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], UserFeatureUsage.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'user_id' }),
    __metadata("design:type", String)
], UserFeatureUsage.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'subscription_id' }),
    __metadata("design:type", String)
], UserFeatureUsage.prototype, "subscriptionId", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'feature_type' }),
    __metadata("design:type", String)
], UserFeatureUsage.prototype, "featureType", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'used_amount', default: 0 }),
    __metadata("design:type", Number)
], UserFeatureUsage.prototype, "usedAmount", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'total_amount' }),
    __metadata("design:type", Number)
], UserFeatureUsage.prototype, "totalAmount", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'unit' }),
    __metadata("design:type", String)
], UserFeatureUsage.prototype, "unit", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ name: 'created_at' }),
    __metadata("design:type", Date)
], UserFeatureUsage.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ name: 'updated_at' }),
    __metadata("design:type", Date)
], UserFeatureUsage.prototype, "updatedAt", void 0);
exports.UserFeatureUsage = UserFeatureUsage = __decorate([
    (0, typeorm_1.Entity)('user_feature_usage')
], UserFeatureUsage);
//# sourceMappingURL=user-feature-usage.entity.js.map