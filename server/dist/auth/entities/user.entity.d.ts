import { Subscription } from '../../subscription/entities/subscription.entity';
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
    createdAt: Date;
    updatedAt: Date;
}
