import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiController } from './ai.controller';
import { AiService } from './ai.service';
import { AiRouterService } from './ai-router.service';
import { ApiKeyModule } from '../api-key/api-key.module';
import { SubscriptionModule } from '../subscription/subscription.module';
import { RedisModule } from '../redis/redis.module';
import { ApiUsageLog } from '../subscription/entities/api-usage-log.entity';
import { PlanApiPolicy } from '../subscription/entities/plan-api-policy.entity';
import { ApiKey } from '../api-key/entities/api-key.entity';

@Module({
  imports: [
    HttpModule,
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'changji_jwt_secret_change_me',
      signOptions: { expiresIn: '15m' },
    }),
    ApiKeyModule,
    SubscriptionModule,
    RedisModule,
    TypeOrmModule.forFeature([ApiUsageLog, PlanApiPolicy, ApiKey]),
  ],
  controllers: [AiController],
  providers: [AiService, AiRouterService],
  exports: [AiRouterService],
})
export class AiModule {}
