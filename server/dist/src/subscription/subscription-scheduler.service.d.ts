import { Repository } from 'typeorm';
import { Subscription } from './entities/subscription.entity';
import { SubscriptionService } from './subscription.service';
export declare class SubscriptionSchedulerService {
    private subscriptionRepository;
    private readonly subscriptionService;
    private readonly logger;
    constructor(subscriptionRepository: Repository<Subscription>, subscriptionService: SubscriptionService);
    checkExpiringSubscriptions(): Promise<void>;
    handleExpiredSubscriptions(): Promise<void>;
    processAutoRenewal(): Promise<void>;
}
