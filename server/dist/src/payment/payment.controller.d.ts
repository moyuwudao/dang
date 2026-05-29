import { PaymentService } from './payment.service';
export declare class PaymentController {
    private readonly paymentService;
    constructor(paymentService: PaymentService);
    createRechargeOrder(req: any, body: {
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
    wechatCallback(body: any): Promise<{
        code: string;
        message: any;
    }>;
    alipayCallback(body: any): Promise<{
        code: string;
        message: any;
    }>;
    getRechargeRecords(req: any, page?: string, limit?: string): Promise<{
        code: number;
        message: string;
        data: {
            records: import("../subscription/entities/recharge-record.entity").RechargeRecord[];
            total: number;
            page: number;
            limit: number;
            totalPages: number;
        };
    }>;
}
