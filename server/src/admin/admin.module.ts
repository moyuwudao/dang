import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { AuditService } from './services/audit.service';
import { AuthModule } from '../auth/auth.module';
import { SubscriptionModule } from '../subscription/subscription.module';
import { PlanModule } from '../plan/plan.module';
import { User } from '../auth/entities/user.entity';
import { Subscription } from '../subscription/entities/subscription.entity';
import { ApiKey } from '../api-key/entities/api-key.entity';
import { UserBalance } from '../subscription/entities/user-balance.entity';
import { RechargeRecord } from '../subscription/entities/recharge-record.entity';
import { ApiUsageLog } from '../subscription/entities/api-usage-log.entity';
import { PlanDefaultConfig } from '../subscription/entities/plan-default-config.entity';
import { PlanFeatureQuota } from '../subscription/entities/plan-feature-quota.entity';
import { TokenPricing } from '../subscription/entities/token-pricing.entity';
import { BillingStandard } from '../subscription/entities/billing-standard.entity';
import { PlanApiPolicy } from '../subscription/entities/plan-api-policy.entity';
import { UserFeatureUsage } from '../subscription/entities/user-feature-usage.entity';
import { AuditLog } from './entities/audit-log.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      Subscription,
      ApiKey,
      UserBalance,
      RechargeRecord,
      ApiUsageLog,
      PlanDefaultConfig,
      PlanFeatureQuota,
      TokenPricing,
      BillingStandard,
      PlanApiPolicy,
      UserFeatureUsage,
      AuditLog,
    ]),
    AuthModule,
    SubscriptionModule,
    PlanModule,
  ],
  controllers: [AdminController],
  providers: [AdminService, AuditService],
  exports: [AuditService],
})
export class AdminModule {}
