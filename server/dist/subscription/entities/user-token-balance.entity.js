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
exports.UserTokenBalance = void 0;
const typeorm_1 = require("typeorm");
let UserTokenBalance = class UserTokenBalance {
};
exports.UserTokenBalance = UserTokenBalance;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], UserTokenBalance.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'user_id', unique: true }),
    __metadata("design:type", String)
], UserTokenBalance.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'total_tokens', type: 'decimal', precision: 15, scale: 4, default: 0 }),
    __metadata("design:type", Number)
], UserTokenBalance.prototype, "totalTokens", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'used_tokens', type: 'decimal', precision: 15, scale: 4, default: 0 }),
    __metadata("design:type", Number)
], UserTokenBalance.prototype, "usedTokens", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'balance_tokens', type: 'decimal', precision: 15, scale: 4, default: 0 }),
    __metadata("design:type", Number)
], UserTokenBalance.prototype, "balanceTokens", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'free_tokens_remaining', type: 'decimal', precision: 15, scale: 4, default: 500 }),
    __metadata("design:type", Number)
], UserTokenBalance.prototype, "freeTokensRemaining", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'expires_at', nullable: true }),
    __metadata("design:type", Date)
], UserTokenBalance.prototype, "expiresAt", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)({ name: 'created_at' }),
    __metadata("design:type", Date)
], UserTokenBalance.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)({ name: 'updated_at' }),
    __metadata("design:type", Date)
], UserTokenBalance.prototype, "updatedAt", void 0);
exports.UserTokenBalance = UserTokenBalance = __decorate([
    (0, typeorm_1.Entity)('user_token_balances')
], UserTokenBalance);
//# sourceMappingURL=user-token-balance.entity.js.map