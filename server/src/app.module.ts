import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { APP_GUARD } from '@nestjs/core';
import { AuthModule } from './auth/auth.module';
import { SubscriptionModule } from './subscription/subscription.module';
import { ApiKeyModule } from './api-key/api-key.module';
import { AdminModule } from './admin/admin.module';
import { MonitorModule } from './monitor/monitor.module';
import { JwtAuthGuard } from './auth/guards/jwt-auth.guard';
import { JwtModule } from '@nestjs/jwt';

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
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'changji_jwt_secret_change_me',
      signOptions: { expiresIn: '15m' },
    }),
    AuthModule,
    SubscriptionModule,
    ApiKeyModule,
    AdminModule,
    MonitorModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
  ],
})
export class AppModule {}
