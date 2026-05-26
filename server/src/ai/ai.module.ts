import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { AiController } from './ai.controller';
import { AiService } from './ai.service';
import { ApiKeyModule } from '../api-key/api-key.module';
import { SubscriptionModule } from '../subscription/subscription.module';
import { RedisModule } from '../redis/redis.module';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ApiUsageLog } from '../subscription/entities/api-usage-log.entity';
import { PlanApiPolicy } from '../subscription/entities/plan-api-policy.entity';

@Module({
  imports: [
    HttpModule,
    ApiKeyModule,
    SubscriptionModule,
    RedisModule,
    TypeOrmModule.forFeature([ApiUsageLog, PlanApiPolicy]),
  ],
  controllers: [AiController],
  providers: [AiService],
})
export class AiModule {}
