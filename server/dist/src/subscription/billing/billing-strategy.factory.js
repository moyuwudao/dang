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
exports.BillingStrategyFactory = void 0;
const common_1 = require("@nestjs/common");
const subscription_billing_strategy_1 = require("./strategies/subscription-billing.strategy");
const package_billing_strategy_1 = require("./strategies/package-billing.strategy");
const pay_as_you_go_billing_strategy_1 = require("./strategies/pay-as-you-go-billing.strategy");
let BillingStrategyFactory = class BillingStrategyFactory {
    constructor(subscriptionStrategy, packageStrategy, payAsYouGoStrategy) {
        this.subscriptionStrategy = subscriptionStrategy;
        this.packageStrategy = packageStrategy;
        this.payAsYouGoStrategy = payAsYouGoStrategy;
    }
    async getStrategy(userId, featureType) {
        if (await this.subscriptionStrategy.canUse(userId, featureType, 0)) {
            return this.subscriptionStrategy;
        }
        if (await this.packageStrategy.canUse(userId, featureType, 0)) {
            return this.packageStrategy;
        }
        return this.payAsYouGoStrategy;
    }
};
exports.BillingStrategyFactory = BillingStrategyFactory;
exports.BillingStrategyFactory = BillingStrategyFactory = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [subscription_billing_strategy_1.SubscriptionBillingStrategy,
        package_billing_strategy_1.PackageBillingStrategy,
        pay_as_you_go_billing_strategy_1.PayAsYouGoBillingStrategy])
], BillingStrategyFactory);
//# sourceMappingURL=billing-strategy.factory.js.map