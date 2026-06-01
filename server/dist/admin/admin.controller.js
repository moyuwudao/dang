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
const api_key_service_1 = require("../api-key/api-key.service");
const monitor_service_1 = require("../monitor/monitor.service");
const metrics_service_1 = require("../monitor/metrics.service");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const admin_guard_1 = require("../auth/guards/admin.guard");
const dto_1 = require("../api-key/dto");
let AdminController = class AdminController {
    constructor(adminService, planService, apiKeyService, monitorService, metricsService) {
        this.adminService = adminService;
        this.planService = planService;
        this.apiKeyService = apiKeyService;
        this.monitorService = monitorService;
        this.metricsService = metricsService;
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
    async getPlanById(id) {
        const data = await this.planService.getPlanById(id);
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
    async adjustUserTokens(userId, data) {
        const result = await this.adminService.adjustUserTokens(userId, data.amount, data.reason);
        return { code: 200, message: 'success', data: result };
    }
    async getRevenueStats(startDate, endDate) {
        const data = await this.adminService.getRevenueStats(startDate, endDate);
        return { code: 200, message: 'success', data };
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
    async getApiConfigs() {
        const data = await this.adminService.getApiConfigs();
        return { code: 200, message: 'success', data };
    }
    async createApiConfig(data) {
        const result = await this.adminService.createApiConfig(data);
        return { code: 200, message: 'success', data: result };
    }
    async updateApiConfig(id, data) {
        const result = await this.adminService.updateApiConfig(id, data);
        return { code: 200, message: 'success', data: result };
    }
    async deleteApiConfig(id) {
        await this.adminService.deleteApiConfig(id);
        return { code: 200, message: 'success', data: null };
    }
    async getApiKeys() {
        const result = await this.apiKeyService.getApiKeys();
        return result;
    }
    async getApiKeyStats() {
        const result = await this.apiKeyService.getApiKeyStats();
        return result;
    }
    async createApiKey(dto) {
        const result = await this.apiKeyService.createApiKey(dto);
        return result;
    }
    async batchCreateApiKeys(body) {
        const results = [];
        for (const dto of body.keys) {
            try {
                const result = await this.apiKeyService.createApiKey(dto);
                results.push({ success: true, data: result.data });
            }
            catch (error) {
                results.push({ success: false, error: error.message, name: dto.name });
            }
        }
        return {
            code: 200,
            message: '批量创建完成',
            data: results,
        };
    }
    async testApiKey(id) {
        const result = await this.apiKeyService.testApiKey(id);
        return result;
    }
    async updateApiKey(id, dto) {
        const result = await this.apiKeyService.updateApiKey(id, dto);
        return result;
    }
    async deleteApiKey(id) {
        const result = await this.apiKeyService.deleteApiKey(id);
        return result;
    }
    async getRealtimeMetrics() {
        if (!this.metricsService) {
            throw new common_1.HttpException('Metrics service unavailable', common_1.HttpStatus.SERVICE_UNAVAILABLE);
        }
        const data = await this.metricsService.getRealtimeMetrics();
        return { code: 200, message: 'success', data };
    }
    async getTrendData(days) {
        if (!this.metricsService) {
            throw new common_1.HttpException('Metrics service unavailable', common_1.HttpStatus.SERVICE_UNAVAILABLE);
        }
        const data = await this.metricsService.getTrendData(parseInt(days || '7', 10));
        return { code: 200, message: 'success', data };
    }
    async getSystemInfo() {
        if (!this.monitorService) {
            throw new common_1.HttpException('Monitor service unavailable', common_1.HttpStatus.SERVICE_UNAVAILABLE);
        }
        const data = await this.monitorService.getSystemInfo();
        return { code: 200, message: 'success', data };
    }
    async getServices() {
        if (!this.monitorService) {
            throw new common_1.HttpException('Monitor service unavailable', common_1.HttpStatus.SERVICE_UNAVAILABLE);
        }
        const data = await this.monitorService.getServices();
        return { code: 200, message: 'success', data };
    }
    async getMonitorLogs(service, lines) {
        if (!this.monitorService) {
            throw new common_1.HttpException('Monitor service unavailable', common_1.HttpStatus.SERVICE_UNAVAILABLE);
        }
        const data = await this.monitorService.getLogs(service, parseInt(lines || '100', 10));
        return { code: 200, message: 'success', data };
    }
    async executeCommand(body) {
        if (!this.monitorService) {
            throw new common_1.HttpException('Monitor service unavailable', common_1.HttpStatus.SERVICE_UNAVAILABLE);
        }
        const data = await this.monitorService.executeCommand(body.command, body.timeout || 30);
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
    (0, common_1.Get)('plans/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getPlanById", null);
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
    (0, common_1.Post)('users/:id/adjust-tokens'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "adjustUserTokens", null);
__decorate([
    (0, common_1.Get)('revenue-stats'),
    __param(0, (0, common_1.Query)('startDate')),
    __param(1, (0, common_1.Query)('endDate')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getRevenueStats", null);
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
    (0, common_1.Get)('api-configs'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getApiConfigs", null);
__decorate([
    (0, common_1.Post)('api-configs'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "createApiConfig", null);
__decorate([
    (0, common_1.Put)('api-configs/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "updateApiConfig", null);
__decorate([
    (0, common_1.Delete)('api-configs/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "deleteApiConfig", null);
__decorate([
    (0, common_1.Get)('api-keys'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getApiKeys", null);
__decorate([
    (0, common_1.Get)('api-keys/stats'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getApiKeyStats", null);
__decorate([
    (0, common_1.Post)('api-keys'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [dto_1.CreateApiKeyDto]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "createApiKey", null);
__decorate([
    (0, common_1.Post)('api-keys/batch'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "batchCreateApiKeys", null);
__decorate([
    (0, common_1.Post)('api-keys/:id/test'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "testApiKey", null);
__decorate([
    (0, common_1.Put)('api-keys/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "updateApiKey", null);
__decorate([
    (0, common_1.Delete)('api-keys/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "deleteApiKey", null);
__decorate([
    (0, common_1.Get)('monitor/realtime'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getRealtimeMetrics", null);
__decorate([
    (0, common_1.Get)('monitor/trend'),
    __param(0, (0, common_1.Query)('days')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getTrendData", null);
__decorate([
    (0, common_1.Get)('monitor/system-info'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getSystemInfo", null);
__decorate([
    (0, common_1.Get)('monitor/services'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getServices", null);
__decorate([
    (0, common_1.Get)('monitor/logs'),
    __param(0, (0, common_1.Query)('service')),
    __param(1, (0, common_1.Query)('lines')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "getMonitorLogs", null);
__decorate([
    (0, common_1.Post)('monitor/execute'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AdminController.prototype, "executeCommand", null);
exports.AdminController = AdminController = __decorate([
    (0, common_1.Controller)('admin'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, admin_guard_1.AdminGuard),
    __param(3, (0, common_1.Optional)()),
    __param(4, (0, common_1.Optional)()),
    __metadata("design:paramtypes", [admin_service_1.AdminService,
        plan_service_1.PlanService,
        api_key_service_1.ApiKeyService,
        monitor_service_1.MonitorService,
        metrics_service_1.MetricsService])
], AdminController);
//# sourceMappingURL=admin.controller.js.map