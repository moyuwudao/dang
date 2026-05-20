import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SubscriptionController } from './subscription.controller';
import { SubscriptionService } from './subscription.service';
import { Subscription } from './entities/subscription.entity';
import { Plan } from './entities/plan.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Subscription, Plan])],
  controllers: [SubscriptionController],
  providers: [SubscriptionService],
  exports: [SubscriptionService],
})
export class SubscriptionModule {}
