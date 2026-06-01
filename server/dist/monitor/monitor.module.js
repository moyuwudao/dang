"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MonitorModule = void 0;
const common_1 = require("@nestjs/common");
const axios_1 = require("@nestjs/axios");
const typeorm_1 = require("@nestjs/typeorm");
const monitor_controller_1 = require("./monitor.controller");
const monitor_service_1 = require("./monitor.service");
const metrics_service_1 = require("./metrics.service");
const auth_module_1 = require("../auth/auth.module");
const redis_module_1 = require("../redis/redis.module");
const api_usage_log_entity_1 = require("../subscription/entities/api-usage-log.entity");
let MonitorModule = class MonitorModule {
};
exports.MonitorModule = MonitorModule;
exports.MonitorModule = MonitorModule = __decorate([
    (0, common_1.Module)({
        imports: [
            axios_1.HttpModule,
            auth_module_1.AuthModule,
            redis_module_1.RedisModule,
            typeorm_1.TypeOrmModule.forFeature([api_usage_log_entity_1.ApiUsageLog]),
        ],
        controllers: [monitor_controller_1.MonitorController],
        providers: [monitor_service_1.MonitorService, metrics_service_1.MetricsService],
        exports: [monitor_service_1.MonitorService, metrics_service_1.MetricsService],
    })
], MonitorModule);
//# sourceMappingURL=monitor.module.js.map