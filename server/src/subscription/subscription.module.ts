import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SubscriptionController } from './subscription.controller';
import { SubscriptionService } from './subscription.service';
import { SubscriptionSchedulerService } from './subscription-scheduler.service';
import { TokenBillingService } from './services/token-billing.service';
import { Subscription } from './entities/subscription.entity';
import { Plan } from './entities/plan.entity';
import { UserTokenBalance } from './entities/user-token-balance.entity';
import { RechargeRecord } from './entities/recharge-record.entity';
import { ApiUsageLog } from './entities/api-usage-log.entity';
import { TokenPricing } from './entities/token-pricing.entity';
import { ApiConfig } from './entities/api-config.entity';
import { PlanModule } from '../plan/plan.module';
import { BillingModule } from './billing/billing.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Subscription, Plan, UserTokenBalance, RechargeRecord,
      ApiUsageLog, TokenPricing, ApiConfig
    ]),
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'changji_jwt_secret_change_me',
      signOptions: { expiresIn: '15m' },
    }),
    PlanModule,
    BillingModule,
  ],
  controllers: [SubscriptionController],
  providers: [SubscriptionService, SubscriptionSchedulerService, TokenBillingService],
  exports: [SubscriptionService, TokenBillingService],
})
export class SubscriptionModule {}
