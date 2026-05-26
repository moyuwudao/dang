import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { AiController } from './ai.controller';
import { AiService } from './ai.service';
import { ApiKeyModule } from '../api-key/api-key.module';
import { SubscriptionModule } from '../subscription/subscription.module';
import { RedisModule } from '../redis/redis.module';

@Module({
  imports: [
    HttpModule,
    ApiKeyModule,
    SubscriptionModule,
    RedisModule,
  ],
  controllers: [AiController],
  providers: [AiService],
})
export class AiModule {}
