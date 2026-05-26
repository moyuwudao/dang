import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SnakeNamingStrategy } from 'typeorm-naming-strategies';
import { AuthModule } from './auth/auth.module';
import { SubscriptionModule } from './subscription/subscription.module';
import { ApiKeyModule } from './api-key/api-key.module';
import { AdminModule } from './admin/admin.module';
import { MonitorModule } from './monitor/monitor.module';

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
      namingStrategy: new SnakeNamingStrategy(),
    }),
    AuthModule,
    SubscriptionModule,
    ApiKeyModule,
    AdminModule,
    MonitorModule,
  ],
})
export class AppModule {}
