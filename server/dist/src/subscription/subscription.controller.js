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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SubscriptionController = void 0;
const common_1 = require("@nestjs/common");
const subscription_service_1 = require("./subscription.service");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const dto_1 = require("./dto");
let SubscriptionController = class SubscriptionController {
    constructor(subscriptionService) {
        this.subscriptionService = subscriptionService;
    }
    async getSubscription(req) {
        return this.subscriptionService.getSubscription(req.user.sub);
    }
    async createSubscription(req, dto) {
        return this.subscriptionService.createSubscription(req.user.sub, dto.planId);
    }
    async getPlanApiPolicies(planId) {
        const policies = await this.subscriptionService.getPlanApiPolicies(planId);
        return { code: 200, message: 'success', data: policies };
    }
    async setPlanApiPolicy(planId, body) {
        const policy = await this.subscriptionService.setPlanApiPolicy(planId, body.provider, body.multiplier, body.modelPattern);
        return { code: 200, message: 'success', data: policy };
    }
    async deletePlanApiPolicy(planId, policyId) {
        await this.subscriptionService.deletePlanApiPolicy(policyId);
        return { code: 200, message: 'success' };
    }
    async getPlans(type) {
        return this.subscriptionService.getPlans(type);
    }
    async createPlan(dto) {
        return this.subscriptionService.createPlan(dto);
    }
    async useQuota(req, body) {
        return this.subscriptionService.useQuota(req.user.sub, body.amount);
    }
    async getBalance(req) {
        return this.subscriptionService.getBalance(req.user.sub);
    }
    async recharge(req, dto) {
        return this.subscriptionService.recharge(req.user.sub, dto);
    }
    async refund(req, dto) {
        return this.subscriptionService.refund(req.user.sub, dto);
    }
    async getRechargeRecords(req) {
        return this.subscriptionService.getRechargeRecords(req.user.sub);
    }
    async checkApiPermission(req, body) {
        const result = await this.subscriptionService.canUseApi(req.user.sub, body.provider, body.model);
        return { code: 200, message: 'success', data: result };
    }
    async consumeQuotaWithApi(req, body) {
        const result = await this.subscriptionService.consumeQuotaWithApi(req.user.sub, body.provider, body.model, body.tokens);
        return { code: 200, message: 'success', data: result };
    }
    async checkFeature(req, body) {
        const result = await this.subscriptionService.canUseFeature(req.user.sub, body.featureType, body.amount);
        return { code: 200, message: 'success', data: result };
    }
    async consumeFeature(req, body) {
        const result = await this.subscriptionService.consumeFeature(req.user.sub, body.featureType, body.amount, {
            provider: body.provider,
            model: body.model,
            promptTokens: body.tokens?.prompt,
            completionTokens: body.tokens?.completion,
        });
        return { code: 200, message: 'success', data: result };
    }
    async getFeatureUsage(req) {
        const result = await this.subscriptionService.getFeatureUsage(req.user.sub);
        return { code: 200, message: 'success', data: result };
    }
    async purchaseWithBalance(req, body) {
        const result = await this.subscriptionService.purchaseWithBalance(req.user.sub, body.planId);
        return { code: 200, message: 'success', data: result };
    }
};
exports.SubscriptionController = SubscriptionController;
__decorate([
    (0, common_1.Get)(),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], SubscriptionController.prototype, "getSubscription", null);
__decorate([
    (0, common_1.Post)(),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, dto_1.CreateSubscriptionDto]),
    __metadata("design:returntype", Promise)
], SubscriptionController.prototype, "createSubscription", null);
__decorate([
    (0, common_1.Get)('plans/:id/policies'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], SubscriptionController.prototype, "getPlanApiPolicies", null);
__decorate([
    (0, common_1.Post)('plans/:id/policies'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], SubscriptionController.prototype, "setPlanApiPolicy", null);
__decorate([
    (0, common_1.Delete)('plans/:planId/policies/:policyId'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Param)('planId')),
    __param(1, (0, common_1.Param)('policyId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], SubscriptionController.prototype, "deletePlanApiPolicy", null);
__decorate([
    (0, common_1.Get)('plans'),
    __param(0, (0, common_1.Query)('type')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], SubscriptionController.prototype, "getPlans", null);
__decorate([
    (0, common_1.Post)('plans'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [dto_1.CreatePlanDto]),
    __metadata("design:returntype", Promise)
], SubscriptionController.prototype, "createPlan", null);
__decorate([
    (0, common_1.Post)('quota/use'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], SubscriptionController.prototype, "useQuota", null);
__decorate([
    (0, common_1.Get)('balance'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], SubscriptionController.prototype, "getBalance", null);
__decorate([
    (0, common_1.Post)('recharge'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, dto_1.RechargeDto]),
    __metadata("design:returntype", Promise)
], SubscriptionController.prototype, "recharge", null);
__decorate([
    (0, common_1.Post)('refund'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, dto_1.RefundDto]),
    __metadata("design:returntype", Promise)
], SubscriptionController.prototype, "refund", null);
__decorate([
    (0, common_1.Get)('records'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], SubscriptionController.prototype, "getRechargeRecords", null);
__decorate([
    (0, common_1.Post)('check-api'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], SubscriptionController.prototype, "checkApiPermission", null);
__decorate([
    (0, common_1.Post)('quota/consume'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], SubscriptionController.prototype, "consumeQuotaWithApi", null);
__decorate([
    (0, common_1.Post)('check-feature'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], SubscriptionController.prototype, "checkFeature", null);
__decorate([
    (0, common_1.Post)('consume-feature'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], SubscriptionController.prototype, "consumeFeature", null);
__decorate([
    (0, common_1.Get)('feature-usage'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], SubscriptionController.prototype, "getFeatureUsage", null);
__decorate([
    (0, common_1.Post)('purchase-with-balance'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], SubscriptionController.prototype, "purchaseWithBalance", null);
exports.SubscriptionController = SubscriptionController = __decorate([
    (0, common_1.Controller)('subscription'),
    __metadata("design:paramtypes", [subscription_service_1.SubscriptionService])
], SubscriptionController);
//# sourceMappingURL=subscription.controller.js.map