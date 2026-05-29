import { User } from '../../auth/entities/user.entity';
export declare class RechargeRecord {
    id: string;
    userId: string;
    amountCents: number;
    type: string;
    paymentMethod: string;
    transactionId: string;
    status: string;
    remark: string;
    user: User;
    createdAt: Date;
}
