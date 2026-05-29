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
var PaymentService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const recharge_record_entity_1 = require("../subscription/entities/recharge-record.entity");
const subscription_service_1 = require("../subscription/subscription.service");
const wechat_pay_service_1 = require("./wechat-pay.service");
const alipay_service_1 = require("./alipay.service");
let PaymentService = PaymentService_1 = class PaymentService {
    constructor(rechargeRecordRepository, subscriptionService, wechatPayService, alipayService) {
        this.rechargeRecordRepository = rechargeRecordRepository;
        this.subscriptionService = subscriptionService;
        this.wechatPayService = wechatPayService;
        this.alipayService = alipayService;
        this.logger = new common_1.Logger(PaymentService_1.name);
    }
    async createRechargeOrder(userId, params) {
        const { amount, paymentMethod } = params;
        const orderId = `RE${Date.now()}${Math.random().toString(36).substr(2, 6)}`;
        const record = this.rechargeRecordRepository.create({
            userId,
            amountCents: amount,
            paymentMethod,
            status: 'pending',
            remark: params.description || `充值 ${amount / 100} 元`,
        });
        await this.rechargeRecordRepository.save(record);
        let paymentData;
        try {
            if (paymentMethod === 'wechat') {
                paymentData = await this.wechatPayService.createOrder({
                    orderId,
                    amount,
                    description: record.remark || '',
                });
            }
            else if (paymentMethod === 'alipay') {
                paymentData = await this.alipayService.createOrder({
                    orderId,
                    amount,
                    description: record.remark || '',
                });
            }
            else {
                throw new Error('不支持的支付方式');
            }
        }
        catch (error) {
            record.status = 'failed';
            await this.rechargeRecordRepository.save(record);
            throw error;
        }
        return {
            code: 200,
            message: '订单创建成功',
            data: {
                orderId,
                amount,
                paymentMethod,
                paymentData,
            },
        };
    }
    async getOrderStatus(orderId) {
        const record = await this.rechargeRecordRepository.findOne({
            where: { id: orderId },
        });
        if (!record) {
            return {
                code: 404,
                message: '订单不存在',
                data: null,
            };
        }
        return {
            code: 200,
            message: 'success',
            data: {
                orderId: record.id,
                status: record.status,
                amount: record.amountCents,
                paymentMethod: record.paymentMethod,
                createdAt: record.createdAt,
            },
        };
    }
    async handleWechatCallback(body) {
        try {
            const result = await this.wechatPayService.verifyCallback(body);
            if (result.success) {
                await this.handlePaymentSuccess(result.orderId, result.amount);
            }
            return { code: 'SUCCESS', message: '成功' };
        }
        catch (error) {
            this.logger.error('微信支付回调处理失败:', error);
            return { code: 'FAIL', message: error.message };
        }
    }
    async handleAlipayCallback(body) {
        try {
            const result = await this.alipayService.verifyCallback(body);
            if (result.success) {
                await this.handlePaymentSuccess(result.orderId, result.amount);
            }
            return { code: 'SUCCESS', message: '成功' };
        }
        catch (error) {
            this.logger.error('支付宝回调处理失败:', error);
            return { code: 'FAIL', message: error.message };
        }
    }
    async handlePaymentSuccess(orderId, amount) {
        const record = await this.rechargeRecordRepository.findOne({
            where: { id: orderId },
        });
        if (!record || record.status === 'completed') {
            return;
        }
        record.status = 'completed';
        await this.rechargeRecordRepository.save(record);
        await this.subscriptionService.recharge(record.userId, {
            amountCents: record.amountCents,
            paymentMethod: record.paymentMethod,
        });
        this.logger.log(`用户 ${record.userId} 充值成功: ${record.amountCents} 分`);
    }
    async getRechargeRecords(userId, page, limit) {
        const [records, total] = await this.rechargeRecordRepository.findAndCount({
            where: { userId },
            order: { createdAt: 'DESC' },
            skip: (page - 1) * limit,
            take: limit,
        });
        return {
            code: 200,
            message: 'success',
            data: {
                records,
                total,
                page,
                limit,
                totalPages: Math.ceil(total / limit),
            },
        };
    }
};
exports.PaymentService = PaymentService;
exports.PaymentService = PaymentService = PaymentService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(recharge_record_entity_1.RechargeRecord)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        subscription_service_1.SubscriptionService,
        wechat_pay_service_1.WechatPayService,
        alipay_service_1.AlipayService])
], PaymentService);
//# sourceMappingURL=payment.service.js.map