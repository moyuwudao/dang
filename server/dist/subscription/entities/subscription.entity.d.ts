import { User } from '../../auth/entities/user.entity';
export declare class Subscription {
    id: string;
    userId: string;
    user: User;
    planId: string;
    status: string;
    startedAt: Date;
    expiresAt: Date;
    totalQuota: number;
    usedQuota: number;
    type: string;
    createdAt: Date;
    updatedAt: Date;
}
