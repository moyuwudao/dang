import { User } from '../../auth/entities/user.entity';
export declare class UserBalance {
    userId: string;
    balanceCents: number;
    totalRechargedCents: number;
    totalRefundedCents: number;
    user: User;
    createdAt: Date;
    updatedAt: Date;
}
