import { User } from '../../auth/entities/user.entity';
export declare class Subscription {
    id: string;
    userId: string;
    user: User;
    planId: string;
    status: string;
    startedAt: Date;
    expiresAt: Date;
    tokenQuota: number;
    usedTokens: number;
    balanceTokens: number;
    type: string;
    createdAt: Date;
    updatedAt: Date;
}
