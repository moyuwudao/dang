import { Repository } from 'typeorm';
import { RechargeRecord } from '../subscription/entities/recharge-record.entity';
import { SubscriptionService } from '../subscription/subscription.service';
import { WechatPayService } from './wechat-pay.service';
import { AlipayService } from './alipay.service';
export declare class PaymentService {
    private rechargeRecordRepository;
    private readonly subscriptionService;
    private readonly wechatPayService;
    private readonly alipayService;
    private readonly logger;
    constructor(rechargeRecordRepository: Repository<RechargeRecord>, subscriptionService: SubscriptionService, wechatPayService: WechatPayService, alipayService: AlipayService);
    createRechargeOrder(userId: string, params: {
        amount: number;
        paymentMethod: string;
        description?: string;
    }): Promise<{
        code: number;
        message: string;
        data: {
            orderId: string;
            amount: number;
            paymentMethod: string;
            paymentData: any;
        };
    }>;
    getOrderStatus(orderId: string): Promise<{
        code: number;
        message: string;
        data: {
            orderId: string;
            status: string;
            amount: number;
            paymentMethod: string;
            createdAt: Date;
        };
    }>;
    handleWechatCallback(body: any): Promise<{
        code: string;
        message: any;
    }>;
    handleAlipayCallback(body: any): Promise<{
        code: string;
        message: any;
    }>;
    private handlePaymentSuccess;
    getRechargeRecords(userId: string, page: number, limit: number): Promise<{
        code: number;
        message: string;
        data: {
            records: RechargeRecord[];
            total: number;
            page: number;
            limit: number;
            totalPages: number;
        };
    }>;
}
