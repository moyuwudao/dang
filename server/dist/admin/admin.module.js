"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdminModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const admin_controller_1 = require("./admin.controller");
const admin_service_1 = require("./admin.service");
const audit_service_1 = require("./services/audit.service");
const auth_module_1 = require("../auth/auth.module");
const subscription_module_1 = require("../subscription/subscription.module");
const plan_module_1 = require("../plan/plan.module");
const api_key_module_1 = require("../api-key/api-key.module");
const monitor_module_1 = require("../monitor/monitor.module");
const user_entity_1 = require("../auth/entities/user.entity");
const subscription_entity_1 = require("../subscription/entities/subscription.entity");
const api_key_entity_1 = require("../api-key/entities/api-key.entity");
const recharge_record_entity_1 = require("../subscription/entities/recharge-record.entity");
const api_usage_log_entity_1 = require("../subscription/entities/api-usage-log.entity");
const token_pricing_entity_1 = require("../subscription/entities/token-pricing.entity");
const api_config_entity_1 = require("../subscription/entities/api-config.entity");
const plan_entity_1 = require("../subscription/entities/plan.entity");
const audit_log_entity_1 = require("./entities/audit-log.entity");
let AdminModule = class AdminModule {
};
exports.AdminModule = AdminModule;
exports.AdminModule = AdminModule = __decorate([
    (0, common_1.Module)({
        imports: [
            typeorm_1.TypeOrmModule.forFeature([
                user_entity_1.User,
                subscription_entity_1.Subscription,
                api_key_entity_1.ApiKey,
                recharge_record_entity_1.RechargeRecord,
                api_usage_log_entity_1.ApiUsageLog,
                token_pricing_entity_1.TokenPricing,
                api_config_entity_1.ApiConfig,
                plan_entity_1.Plan,
                audit_log_entity_1.AuditLog,
            ]),
            auth_module_1.AuthModule,
            subscription_module_1.SubscriptionModule,
            plan_module_1.PlanModule,
            api_key_module_1.ApiKeyModule,
            monitor_module_1.MonitorModule,
        ],
        controllers: [admin_controller_1.AdminController],
        providers: [admin_service_1.AdminService, audit_service_1.AuditService],
        exports: [audit_service_1.AuditService],
    })
], AdminModule);
//# sourceMappingURL=admin.module.js.map