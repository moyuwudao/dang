"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var AlipayService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.AlipayService = void 0;
const common_1 = require("@nestjs/common");
let AlipayService = AlipayService_1 = class AlipayService {
    constructor() {
        this.logger = new common_1.Logger(AlipayService_1.name);
        this.config = {
            appId: process.env.ALIPAY_APP_ID || '',
            privateKey: process.env.ALIPAY_PRIVATE_KEY || '',
            publicKey: process.env.ALIPAY_PUBLIC_KEY || '',
            notifyUrl: process.env.ALIPAY_NOTIFY_URL || 'https://your-domain.com/api/v1/payment/alipay/callback',
            returnUrl: process.env.ALIPAY_RETURN_URL || 'https://your-domain.com/payment/success',
        };
    }
    async createOrder(params) {
        const { orderId, amount, description } = params;
        this.logger.log(`创建支付宝订单: ${orderId}, 金额: ${amount}分`);
        return {
            form: '',
            pcForm: '',
            payUrl: '',
            tradeNo: orderId,
        };
    }
    async verifyCallback(body) {
        this.logger.log('验证支付宝回调');
        return {
            success: false,
            orderId: '',
            amount: 0,
        };
    }
    async queryOrder(orderId) {
        this.logger.log(`查询支付宝订单: ${orderId}`);
        return {
            status: 'pending',
            orderId,
        };
    }
};
exports.AlipayService = AlipayService;
exports.AlipayService = AlipayService = AlipayService_1 = __decorate([
    (0, common_1.Injectable)()
], AlipayService);
//# sourceMappingURL=alipay.service.js.map