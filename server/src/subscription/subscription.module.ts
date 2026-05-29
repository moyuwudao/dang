import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SubscriptionController } from './subscription.controller';
import { SubscriptionService } from './subscription.service';
import { SubscriptionSchedulerService } from './subscription-scheduler.service';
import { Subscription } from './entities/subscription.entity';
import { Plan } from './entities/plan.entity';
import { UserBalance } from './entities/user-balance.entity';
import { RechargeRecord } from './entities/recharge-record.entity';
import { PlanApiPolicy } from './entities/plan-api-policy.entity';
import { ApiUsageLog } from './entities/api-usage-log.entity';
import { PlanDefaultConfig } from './entities/plan-default-config.entity';
import { PlanFeatureQuota } from './entities/plan-feature-quota.entity';
import { UserFeatureUsage } from './entities/user-feature-usage.entity';
import { TokenPricing } from './entities/token-pricing.entity';
import { PlanModule } from '../plan/plan.module';
import { BillingModule } from './billing/billing.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Subscription, Plan, UserBalance, RechargeRecord, PlanApiPolicy, 
      ApiUsageLog, PlanDefaultConfig, PlanFeatureQuota, UserFeatureUsage, TokenPricing
    ]),
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'changji_jwt_secret_change_me',
      signOptions: { expiresIn: '15m' },
    }),
    PlanModule,
    BillingModule,
  ],
  controllers: [SubscriptionController],
  providers: [SubscriptionService, SubscriptionSchedulerService],
  exports: [SubscriptionService],
})
export class SubscriptionModule {}
