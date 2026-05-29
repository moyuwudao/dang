import { User } from '../../auth/entities/user.entity';
import { Plan } from './plan.entity';
export declare class Subscription {
    id: string;
    userId: string;
    planId: string;
    status: string;
    startedAt: Date;
    expiresAt: Date;
    totalQuota: number;
    usedQuota: number;
    balanceQuota: number;
    type: string;
    user: User;
    plan: Plan;
    createdAt: Date;
    updatedAt: Date;
}
