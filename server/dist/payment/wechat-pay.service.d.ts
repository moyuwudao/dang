export declare class WechatPayService {
    private readonly logger;
    private readonly config;
    createOrder(params: {
        orderId: string;
        amount: number;
        description: string;
    }): Promise<any>;
    verifyCallback(body: any): Promise<{
        success: boolean;
        orderId: string;
        amount: number;
    }>;
    queryOrder(orderId: string): Promise<any>;
}
