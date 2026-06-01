import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MonitorController } from './monitor.controller';
import { MonitorService } from './monitor.service';
import { MetricsService } from './metrics.service';
import { AuthModule } from '../auth/auth.module';
import { RedisModule } from '../redis/redis.module';
import { ApiUsageLog } from '../subscription/entities/api-usage-log.entity';

@Module({
  imports: [
    HttpModule,
    AuthModule,
    RedisModule,
    TypeOrmModule.forFeature([ApiUsageLog]),
  ],
  controllers: [MonitorController],
  providers: [MonitorService, MetricsService],
  exports: [MonitorService, MetricsService],
})
export class MonitorModule {}
