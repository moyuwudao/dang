"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.BillingModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const billing_strategy_factory_1 = require("./billing-strategy.factory");
const subscription_billing_strategy_1 = require("./strategies/subscription-billing.strategy");
const package_billing_strategy_1 = require("./strategies/package-billing.strategy");
const pay_as_you_go_billing_strategy_1 = require("./strategies/pay-as-you-go-billing.strategy");
const subscription_entity_1 = require("../entities/subscription.entity");
const user_feature_usage_entity_1 = require("../entities/user-feature-usage.entity");
const plan_feature_quota_entity_1 = require("../entities/plan-feature-quota.entity");
const user_balance_entity_1 = require("../entities/user-balance.entity");
const token_pricing_entity_1 = require("../entities/token-pricing.entity");
const api_usage_log_entity_1 = require("../entities/api-usage-log.entity");
let BillingModule = class BillingModule {
};
exports.BillingModule = BillingModule;
exports.BillingModule = BillingModule = __decorate([
    (0, common_1.Module)({
        imports: [
            typeorm_1.TypeOrmModule.forFeature([
                subscription_entity_1.Subscription,
                user_feature_usage_entity_1.UserFeatureUsage,
                plan_feature_quota_entity_1.PlanFeatureQuota,
                user_balance_entity_1.UserBalance,
                token_pricing_entity_1.TokenPricing,
                api_usage_log_entity_1.ApiUsageLog,
            ]),
        ],
        providers: [
            billing_strategy_factory_1.BillingStrategyFactory,
            subscription_billing_strategy_1.SubscriptionBillingStrategy,
            package_billing_strategy_1.PackageBillingStrategy,
            pay_as_you_go_billing_strategy_1.PayAsYouGoBillingStrategy,
        ],
        exports: [billing_strategy_factory_1.BillingStrategyFactory],
    })
], BillingModule);
//# sourceMappingURL=billing.module.js.map