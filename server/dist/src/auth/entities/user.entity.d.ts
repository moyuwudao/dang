import { Subscription } from '../../subscription/entities/subscription.entity';
import { UserBalance } from '../../subscription/entities/user-balance.entity';
export declare class User {
    id: string;
    phone: string;
    email: string;
    passwordHash: string;
    nickname: string;
    avatarUrl: string;
    status: string;
    role: string;
    subscriptions: Subscription[];
    balance: UserBalance;
    createdAt: Date;
    updatedAt: Date;
}
