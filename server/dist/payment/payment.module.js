"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const axios_1 = require("@nestjs/axios");
const jwt_1 = require("@nestjs/jwt");
const payment_controller_1 = require("./payment.controller");
const payment_service_1 = require("./payment.service");
const wechat_pay_service_1 = require("./wechat-pay.service");
const alipay_service_1 = require("./alipay.service");
const recharge_record_entity_1 = require("../subscription/entities/recharge-record.entity");
const subscription_module_1 = require("../subscription/subscription.module");
let PaymentModule = class PaymentModule {
};
exports.PaymentModule = PaymentModule;
exports.PaymentModule = PaymentModule = __decorate([
    (0, common_1.Module)({
        imports: [
            axios_1.HttpModule,
            jwt_1.JwtModule.register({
                secret: process.env.JWT_SECRET || 'changji_jwt_secret_change_me',
                signOptions: { expiresIn: '15m' },
            }),
            typeorm_1.TypeOrmModule.forFeature([recharge_record_entity_1.RechargeRecord]),
            subscription_module_1.SubscriptionModule,
        ],
        controllers: [payment_controller_1.PaymentController],
        providers: [payment_service_1.PaymentService, wechat_pay_service_1.WechatPayService, alipay_service_1.AlipayService],
        exports: [payment_service_1.PaymentService],
    })
], PaymentModule);
//# sourceMappingURL=payment.module.js.map