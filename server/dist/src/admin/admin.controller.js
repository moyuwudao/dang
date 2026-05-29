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
exports.AdminController = void 0;
const common_1 = require("@nestjs/common");
const admin_service_1 = require("./admin.service");
const plan_service_1 = require("../plan/plan.service");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const admin_guard_1 = require("../auth/guards/admin.guard");
let AdminController = class AdminController {
    constructor(adminService, planService) {
        this.adminService = adminService;
        this.planService = planService;
    }
    async getStats() {
        const data = await this.adminService.getStats();
        return { code: 200, message: 'success', data };
    }
    async getUsers(page, limit, search) {
        const data = await this.adminService.getUsers(page ? parseInt(page, 10) : 1, limit ? parseInt(limit, 10) : 20, search);
        return { code: 200, message: 'success', data };
    }
    async createUser(data) {
        const result = await this.adminService.createUser(data);
        return { code: 200, message: '创建成功', data: result };
    }
    async getUserById(id) {
        const result = await this.adminService.getUserById(id);
        return { code: 200, message: 'success', data: result };
    }
    async updateUser(id, data) {
        const result = await this.adminService.updateUser(id, data);
        return { code: 200, message: 'success', data: result };
    }
    async deleteUser(id) {
        await this.adminService.deleteUser(id);
        return { code: 200, message: 'success', data: null };
    }
    async getPlans() {
        const data = await this.adminService.getPlans();
        return { code: 200, message: 'success', data };
    }
    async createPlan(data) {
        const result = await this.adminService.createPlan(data);
        return { code: 200, message: 'success', data: result };
    }
    async updatePlan(id, data) {
        const result = await this.adminService.updatePlan(id, data);
        return { code: 200, message: 'success', data: result };
    }
    async deletePlan(id) {
        await this.adminService.deletePlan(id);
        return { code: 200, message: 'success', data: null };
    }
    async getSubscriptions(page, limit, status) {
        const data = await this.adminService.getSubscriptions(page ? parseInt(page, 10) : 1, limit ? parseInt(limit, 10) : 20, status);
        return { code: 200, message: 'success', data };
    }
    async updateSubscription(id, data) {
        const result = await this.adminService.updateSubscription(id, data);
        return { code: 200, message: 'success', data: result };
    }
    async assignPlanToUser(userId, data) {
        const result = await this.adminService.assignPlanToUser(userId, data.planId);
        return { code: 200, message: 'success', data: result };
    }
    async getRechargeRecords(page, limit) {
        const data = await this.adminService.getRechargeRecords(page ? parseInt(page, 10) : 1, limit ? parseInt(limit, 10) : 20);
        return { code: 200, message: 'success', data };
    }
    async getUserGrowth(days) {
        const data = await this.adminService.getUserGrowth(days ? parseInt(days, 10) : 7);
        return { code: 200, message: 'success', data };
    }
    async getRevenueTrend(days) {
        const data = await this.adminService.getRevenueTrend(days ? parseInt(days, 10) : 7);
        return { code: 200, message: 'success', data };
    }
    async getApiUsageLogs(page, limit, userId, provider) {
        const data = await this.adminService.getApiUsageLogs(page ? parseInt(page, 10) : 1, limit ? parseInt(limit, 10) : 20, userId, provider);
        return { code: 200, message: 'success', data };
    }
    async adjustUserQuota(userId, data) {
        const result = await this.adminService.adjustUserQuota(userId, data.amount, data.reason);
        return { code: 200, message: 'success', data: result };
    }
    async getRevenueStats(startDate, endDate) {
        const data = await this.adminService.getRevenueStats(startDate, endDate);
        return { code: 200, message: 'success', data };
    }
    async getPlanDefaultConfigs(planId) {
        const data = await this.adminService.getPlanDefaultConfigs(planId);
        return { code: 200, message: 'success', data };
    }
    async setPlanDefaultConfig(planId, data) {
        const result = await this.adminService.setPlanDefaultConfig(planId, data);
        return { code: 200, message: 'success', data: result };
    }
    async deletePlanDefaultConfig(configId) {
        await this.adminService.deletePlanDefaultConfig(configId);
        return { code: 200, message: 'success', data: null };
    }
    async getPlanFeatureQuotas(planId) {
        const data = await this.planService.getPlanFeatureQuotas(planId);
        return { code: 200, message: 'success', data };
    }
    async setPlanFeatureQuota(planId, data) {
        const result = await this.planService.setPlanFeatureQuota(planId, data);
        return { code: 200, message: 'success', data: result };
    }
    async deletePlanFeatureQuota(quotaId) {
        await this.planService.deletePlanFeatureQuota(quotaId);
        return { code: 200, message: 'success', data: null };
    }
    async getTokenPricing() {
        const data = await this.adminService.getTokenPricing();
        return { code: 200, message: 'success', data };
    }
    async createTokenPricing(data) {
        const result = await this.adminService.createTokenPricing(data);
        return { code: 200, message: 'success', data: result };
    }
    async updateTokenPricing(id, data) {
        const result = await this.adminService.updateTokenPricing(id, data);
        return { code: 200, message: 'success', data: result };
    }
    async deleteTokenPricing(id) {
        await this.adminService.deleteTokenPricing(id);
        return { code: 200, message: 'success', data: null };
    }
    async getUserFeatureUsage(userId) {
        const data = await this.adminService.getUserFeatureUsage(userId);
        return { code: 200, message: 'success', data };
    }
};
exports.AdminController = AdminController;
__decorate([
    (0, common_1.Get)('stats'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getStats", null);
__decorate([
    (0, common_1.Get)('users'),
    __param(0, (0, common_1.Query)('page')),
    __param(1, (0, common_1.Query)('limit')),
    __param(2, (0, common_1.Query)('search')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getUsers", null);
__decorate([
    (0, common_1.Post)('users'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "createUser", null);
__decorate([
    (0, common_1.Get)('users/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getUserById", null);
__decorate([
    (0, common_1.Put)('users/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "updateUser", null);
__decorate([
    (0, common_1.Delete)('users/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "deleteUser", null);
__decorate([
    (0, common_1.Get)('plans'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getPlans", null);
__decorate([
    (0, common_1.Post)('plans'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "createPlan", null);
__decorate([
    (0, common_1.Put)('plans/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "updatePlan", null);
__decorate([
    (0, common_1.Delete)('plans/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "deletePlan", null);
__decorate([
    (0, common_1.Get)('subscriptions'),
    __param(0, (0, common_1.Query)('page')),
    __param(1, (0, common_1.Query)('limit')),
    __param(2, (0, common_1.Query)('status')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getSubscriptions", null);
__decorate([
    (0, common_1.Put)('subscriptions/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "updateSubscription", null);
__decorate([
    (0, common_1.Post)('users/:id/subscribe'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "assignPlanToUser", null);
__decorate([
    (0, common_1.Get)('recharge-records'),
    __param(0, (0, common_1.Query)('page')),
    __param(1, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getRechargeRecords", null);
__decorate([
    (0, common_1.Get)('charts/user-growth'),
    __param(0, (0, common_1.Query)('days')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getUserGrowth", null);
__decorate([
    (0, common_1.Get)('charts/revenue-trend'),
    __param(0, (0, common_1.Query)('days')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getRevenueTrend", null);
__decorate([
    (0, common_1.Get)('api-usage-logs'),
    __param(0, (0, common_1.Query)('page')),
    __param(1, (0, common_1.Query)('limit')),
    __param(2, (0, common_1.Query)('userId')),
    __param(3, (0, common_1.Query)('provider')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getApiUsageLogs", null);
__decorate([
    (0, common_1.Post)('users/:id/adjust-quota'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "adjustUserQuota", null);
__decorate([
    (0, common_1.Get)('revenue-stats'),
    __param(0, (0, common_1.Query)('startDate')),
    __param(1, (0, common_1.Query)('endDate')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getRevenueStats", null);
__decorate([
    (0, common_1.Get)('plans/:id/default-configs'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getPlanDefaultConfigs", null);
__decorate([
    (0, common_1.Post)('plans/:id/default-configs'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "setPlanDefaultConfig", null);
__decorate([
    (0, common_1.Delete)('plans/default-configs/:configId'),
    __param(0, (0, common_1.Param)('configId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "deletePlanDefaultConfig", null);
__decorate([
    (0, common_1.Get)('plans/:id/feature-quotas'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getPlanFeatureQuotas", null);
__decorate([
    (0, common_1.Post)('plans/:id/feature-quotas'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "setPlanFeatureQuota", null);
__decorate([
    (0, common_1.Delete)('plans/feature-quotas/:quotaId'),
    __param(0, (0, common_1.Param)('quotaId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "deletePlanFeatureQuota", null);
__decorate([
    (0, common_1.Get)('token-pricing'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getTokenPricing", null);
__decorate([
    (0, common_1.Post)('token-pricing'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "createTokenPricing", null);
__decorate([
    (0, common_1.Put)('token-pricing/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "updateTokenPricing", null);
__decorate([
    (0, common_1.Delete)('token-pricing/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "deleteTokenPricing", null);
__decorate([
    (0, common_1.Get)('users/:id/feature-usage'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getUserFeatureUsage", null);
exports.AdminController = AdminController = __decorate([
    (0, common_1.Controller)('admin'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, admin_guard_1.AdminGuard),
    __metadata("design:paramtypes", [admin_service_1.AdminService,
        plan_service_1.PlanService])
], AdminController);
//# sourceMappingURL=admin.controller.js.map