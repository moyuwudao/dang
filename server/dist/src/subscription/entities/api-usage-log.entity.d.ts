import { Subscription } from './subscription.entity';
import { ApiKey } from '../../api-key/entities/api-key.entity';
import { User } from '../../auth/entities/user.entity';
export declare class ApiUsageLog {
    id: string;
    userId: string;
    subscriptionId: string;
    apiKeyId: string;
    provider: string;
    model: string;
    promptTokens: number;
    completionTokens: number;
    quotaConsumed: number;
    costCents: number;
    featureType: string;
    resourceConsumed: number;
    unit: string;
    user: User;
    subscription: Subscription;
    apiKey: ApiKey;
    createdAt: Date;
}
