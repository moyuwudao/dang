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
exports.ApiKeyController = void 0;
const common_1 = require("@nestjs/common");
const api_key_service_1 = require("./api-key.service");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const admin_guard_1 = require("../auth/guards/admin.guard");
const rate_limit_interceptor_1 = require("./interceptors/rate-limit.interceptor");
const dto_1 = require("./dto");
let ApiKeyController = class ApiKeyController {
    constructor(apiKeyService) {
        this.apiKeyService = apiKeyService;
    }
    async getApiKey(req) {
        return this.apiKeyService.getApiKey(req.user.sub);
    }
    async refreshApiKey(req) {
        return this.apiKeyService.refreshApiKey(req.user.sub);
    }
    async getApiKeys() {
        return this.apiKeyService.getApiKeys();
    }
    async getApiKeyStats() {
        return this.apiKeyService.getApiKeyStats();
    }
    async getHealthyModels() {
        return this.apiKeyService.getHealthyModels();
    }
    async getApiKeyById(id) {
        return this.apiKeyService.getApiKeyById(id);
    }
    async createApiKey(dto) {
        return this.apiKeyService.createApiKey(dto);
    }
    async batchCreateApiKeys(dtos) {
        const results = [];
        for (const dto of dtos) {
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
    async updateApiKey(id, dto) {
        return this.apiKeyService.updateApiKey(id, dto);
    }
    async deleteApiKey(id) {
        return this.apiKeyService.deleteApiKey(id);
    }
    async testApiKey(id) {
        return this.apiKeyService.testApiKey(id);
    }
};
exports.ApiKeyController = ApiKeyController;
__decorate([
    (0, common_1.Get)(),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.UseInterceptors)(rate_limit_interceptor_1.RateLimitInterceptor),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ApiKeyController.prototype, "getApiKey", null);
__decorate([
    (0, common_1.Post)('refresh'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ApiKeyController.prototype, "refreshApiKey", null);
__decorate([
    (0, common_1.Get)('admin/list'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, admin_guard_1.AdminGuard),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ApiKeyController.prototype, "getApiKeys", null);
__decorate([
    (0, common_1.Get)('admin/stats'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, admin_guard_1.AdminGuard),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ApiKeyController.prototype, "getApiKeyStats", null);
__decorate([
    (0, common_1.Get)('admin/healthy-models'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, admin_guard_1.AdminGuard),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ApiKeyController.prototype, "getHealthyModels", null);
__decorate([
    (0, common_1.Get)('admin/:id'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ApiKeyController.prototype, "getApiKeyById", null);
__decorate([
    (0, common_1.Post)('admin/create'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [dto_1.CreateApiKeyDto]),
    __metadata("design:returntype", Promise)
], ApiKeyController.prototype, "createApiKey", null);
__decorate([
    (0, common_1.Post)('admin/batch'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Array]),
    __metadata("design:returntype", Promise)
], ApiKeyController.prototype, "batchCreateApiKeys", null);
__decorate([
    (0, common_1.Put)('admin/:id'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], ApiKeyController.prototype, "updateApiKey", null);
__decorate([
    (0, common_1.Delete)('admin/:id'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ApiKeyController.prototype, "deleteApiKey", null);
__decorate([
    (0, common_1.Post)('admin/:id/test'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ApiKeyController.prototype, "testApiKey", null);
exports.ApiKeyController = ApiKeyController = __decorate([
    (0, common_1.Controller)('api-key'),
    __metadata("design:paramtypes", [api_key_service_1.ApiKeyService])
], ApiKeyController);
//# sourceMappingURL=api-key.controller.js.map