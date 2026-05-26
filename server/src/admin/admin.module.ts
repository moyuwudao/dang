import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { AuditService } from './services/audit.service';
import { AuthModule } from '../auth/auth.module';
import { SubscriptionModule } from '../subscription/subscription.module';
import { User } from '../auth/entities/user.entity';
import { Plan } from '../subscription/entities/plan.entity';
import { Subscription } from '../subscription/entities/subscription.entity';
import { ApiKey } from '../api-key/entities/api-key.entity';
import { UserBalance } from '../subscription/entities/user-balance.entity';
import { RechargeRecord } from '../subscription/entities/recharge-record.entity';
import { AuditLog } from './entities/audit-log.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      Plan,
      Subscription,
      ApiKey,
      UserBalance,
      RechargeRecord,
      AuditLog,
    ]),
    AuthModule,
    SubscriptionModule,
  ],
  controllers: [AdminController],
  providers: [AdminService, AuditService],
  exports: [AuditService],
})
export class AdminModule {}
