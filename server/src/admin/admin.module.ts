import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { AuditService } from './services/audit.service';
import { AuthModule } from '../auth/auth.module';
import { SubscriptionModule } from '../subscription/subscription.module';
import { PlanModule } from '../plan/plan.module';
import { ApiKeyModule } from '../api-key/api-key.module';
import { MonitorModule } from '../monitor/monitor.module';
import { User } from '../auth/entities/user.entity';
import { Subscription } from '../subscription/entities/subscription.entity';
import { ApiKey } from '../api-key/entities/api-key.entity';
import { RechargeRecord } from '../subscription/entities/recharge-record.entity';
import { ApiUsageLog } from '../subscription/entities/api-usage-log.entity';
import { TokenPricing } from '../subscription/entities/token-pricing.entity';
import { ApiConfig } from '../subscription/entities/api-config.entity';
import { Plan } from '../subscription/entities/plan.entity';
import { AuditLog } from './entities/audit-log.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      Subscription,
      ApiKey,
      RechargeRecord,
      ApiUsageLog,
      TokenPricing,
      ApiConfig,
      Plan,
      AuditLog,
    ]),
    AuthModule,
    SubscriptionModule,
    PlanModule,
    ApiKeyModule,
    MonitorModule,
  ],
  controllers: [AdminController],
  providers: [AdminService, AuditService],
  exports: [AuditService],
})
export class AdminModule {}
