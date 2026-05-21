import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SubscriptionController } from './subscription.controller';
import { SubscriptionService } from './subscription.service';
import { Subscription } from './entities/subscription.entity';
import { Plan } from './entities/plan.entity';
import { UserBalance } from './entities/user-balance.entity';
import { RechargeRecord } from './entities/recharge-record.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Subscription, Plan, UserBalance, RechargeRecord])],
  controllers: [SubscriptionController],
  providers: [SubscriptionService],
  exports: [SubscriptionService],
})
export class SubscriptionModule {}
