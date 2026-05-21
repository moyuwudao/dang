import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { User } from '../auth/entities/user.entity';
import { Plan } from '../subscription/entities/plan.entity';
import { Subscription } from '../subscription/entities/subscription.entity';
import { ApiKey } from '../api-key/entities/api-key.entity';
import { UserBalance } from '../subscription/entities/user-balance.entity';
import { RechargeRecord } from '../subscription/entities/recharge-record.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      Plan,
      Subscription,
      ApiKey,
      UserBalance,
      RechargeRecord,
    ]),
  ],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
