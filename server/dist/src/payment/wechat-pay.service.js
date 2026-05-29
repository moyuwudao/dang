"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var WechatPayService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.WechatPayService = void 0;
const common_1 = require("@nestjs/common");
let WechatPayService = WechatPayService_1 = class WechatPayService {
    constructor() {
        this.logger = new common_1.Logger(WechatPayService_1.name);
        this.config = {
            appId: process.env.WECHAT_APP_ID || '',
            mchId: process.env.WECHAT_MCH_ID || '',
            apiKey: process.env.WECHAT_API_KEY || '',
            notifyUrl: process.env.WECHAT_NOTIFY_URL || 'https://your-domain.com/api/v1/payment/wechat/callback',
        };
    }
    async createOrder(params) {
        const { orderId, amount, description } = params;
        this.logger.log(`创建微信支付订单: ${orderId}, 金额: ${amount}分`);
        return {
            codeUrl: '',
            prepayId: '',
            h5Url: '',
            miniPayParams: {
                timeStamp: Date.now().toString(),
                nonceStr: '',
                package: '',
                signType: 'RSA',
                paySign: '',
            },
        };
    }
    async verifyCallback(body) {
        this.logger.log('验证微信支付回调');
        return {
            success: false,
            orderId: '',
            amount: 0,
        };
    }
    async queryOrder(orderId) {
        this.logger.log(`查询微信支付订单: ${orderId}`);
        return {
            status: 'pending',
            orderId,
        };
    }
};
exports.WechatPayService = WechatPayService;
exports.WechatPayService = WechatPayService = WechatPayService_1 = __decorate([
    (0, common_1.Injectable)()
], WechatPayService);
//# sourceMappingURL=wechat-pay.service.js.map