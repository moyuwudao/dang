import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Subscription } from '../entities/subscription.entity';
import { UserTokenBalance } from '../entities/user-token-balance.entity';
import { TokenPricing } from '../entities/token-pricing.entity';
import { ApiUsageLog } from '../entities/api-usage-log.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Subscription,
      UserTokenBalance,
      TokenPricing,
      ApiUsageLog,
    ]),
  ],
  providers: [],
  exports: [],
})
export class BillingModule {}
