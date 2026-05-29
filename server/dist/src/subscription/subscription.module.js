"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SubscriptionModule = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const typeorm_1 = require("@nestjs/typeorm");
const subscription_controller_1 = require("./subscription.controller");
const subscription_service_1 = require("./subscription.service");
const subscription_scheduler_service_1 = require("./subscription-scheduler.service");
const subscription_entity_1 = require("./entities/subscription.entity");
const plan_entity_1 = require("./entities/plan.entity");
const user_balance_entity_1 = require("./entities/user-balance.entity");
const recharge_record_entity_1 = require("./entities/recharge-record.entity");
const plan_api_policy_entity_1 = require("./entities/plan-api-policy.entity");
const api_usage_log_entity_1 = require("./entities/api-usage-log.entity");
const plan_default_config_entity_1 = require("./entities/plan-default-config.entity");
const plan_feature_quota_entity_1 = require("./entities/plan-feature-quota.entity");
const user_feature_usage_entity_1 = require("./entities/user-feature-usage.entity");
const token_pricing_entity_1 = require("./entities/token-pricing.entity");
const plan_module_1 = require("../plan/plan.module");
const billing_module_1 = require("./billing/billing.module");
let SubscriptionModule = class SubscriptionModule {
};
exports.SubscriptionModule = SubscriptionModule;
exports.SubscriptionModule = SubscriptionModule = __decorate([
    (0, common_1.Module)({
        imports: [
            typeorm_1.TypeOrmModule.forFeature([
                subscription_entity_1.Subscription, plan_entity_1.Plan, user_balance_entity_1.UserBalance, recharge_record_entity_1.RechargeRecord, plan_api_policy_entity_1.PlanApiPolicy,
                api_usage_log_entity_1.ApiUsageLog, plan_default_config_entity_1.PlanDefaultConfig, plan_feature_quota_entity_1.PlanFeatureQuota, user_feature_usage_entity_1.UserFeatureUsage, token_pricing_entity_1.TokenPricing
            ]),
            jwt_1.JwtModule.register({
                secret: process.env.JWT_SECRET || 'changji_jwt_secret_change_me',
                signOptions: { expiresIn: '15m' },
            }),
            plan_module_1.PlanModule,
            billing_module_1.BillingModule,
        ],
        controllers: [subscription_controller_1.SubscriptionController],
        providers: [subscription_service_1.SubscriptionService, subscription_scheduler_service_1.SubscriptionSchedulerService],
        exports: [subscription_service_1.SubscriptionService],
    })
], SubscriptionModule);
//# sourceMappingURL=subscription.module.js.map