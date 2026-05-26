import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { AuthModule } from './auth/auth.module';
import { SubscriptionModule } from './subscription/subscription.module';
import { ApiKeyModule } from './api-key/api-key.module';
import { AdminModule } from './admin/admin.module';
import { ScheduleModule } from '@nestjs/schedule';
import { MonitorModule } from './monitor/monitor.module';
import { RedisModule } from './redis/redis.module';
import { AiModule } from './ai/ai.module';
import { PaymentModule } from './payment/payment.module';
import { JwtAuthGuard } from './auth/guards/jwt-auth.guard';
import { ResponseInterceptor } from './common/interceptors/response.interceptor';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT, 10) || 5432,
      username: process.env.DB_USER || 'appuser',
      password: process.env.DB_PASSWORD || 'AppUser123456',
      database: process.env.DB_NAME || 'appdb',
      entities: [__dirname + '/**/*.entity{.ts,.js}'],
      synchronize: false, // 数据库 schema 已同步，关闭自动同步
      logging: false,
    }),
    ScheduleModule.forRoot(),
    AuthModule,
    SubscriptionModule,
    ApiKeyModule,
    AdminModule,
    MonitorModule,
    RedisModule,
    AiModule,
    PaymentModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
    {
      provide: APP_INTERCEPTOR,
      useClass: ResponseInterceptor,
    },
  ],
})
export class AppModule {}
