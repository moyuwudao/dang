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
exports.MonitorController = void 0;
const common_1 = require("@nestjs/common");
const monitor_service_1 = require("./monitor.service");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const admin_guard_1 = require("../auth/guards/admin.guard");
let MonitorController = class MonitorController {
    constructor(monitorService) {
        this.monitorService = monitorService;
    }
    async getSystemInfo() {
        const data = await this.monitorService.getSystemInfo();
        return { code: 200, message: 'success', data };
    }
    async getServices() {
        const data = await this.monitorService.getServices();
        return { code: 200, message: 'success', data };
    }
    async getLogs(body) {
        const data = await this.monitorService.getLogs(body.service, body.lines || 100);
        return { code: 200, message: 'success', data };
    }
    async executeCommand(body) {
        const data = await this.monitorService.executeCommand(body.command, body.timeout || 30);
        return { code: 200, message: 'success', data };
    }
};
exports.MonitorController = MonitorController;
__decorate([
    (0, common_1.Get)('system'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], MonitorController.prototype, "getSystemInfo", null);
__decorate([
    (0, common_1.Get)('services'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], MonitorController.prototype, "getServices", null);
__decorate([
    (0, common_1.Post)('logs'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], MonitorController.prototype, "getLogs", null);
__decorate([
    (0, common_1.Post)('execute'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], MonitorController.prototype, "executeCommand", null);
exports.MonitorController = MonitorController = __decorate([
    (0, common_1.Controller)('monitor'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, admin_guard_1.AdminGuard),
    __metadata("design:paramtypes", [monitor_service_1.MonitorService])
], MonitorController);
//# sourceMappingURL=monitor.controller.js.map