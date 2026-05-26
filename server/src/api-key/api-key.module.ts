import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HttpModule } from '@nestjs/axios';
import { ApiKeyController } from './api-key.controller';
import { ApiKeyService } from './api-key.service';
import { ApiKey } from './entities/api-key.entity';
import { UserApiKey } from './entities/user-api-key.entity';
import { RateLimitInterceptor } from './interceptors/rate-limit.interceptor';
import { AdminModule } from '../admin/admin.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([ApiKey, UserApiKey]),
    HttpModule,
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'changji_jwt_secret_change_me',
      signOptions: { expiresIn: '15m' },
    }),
  ],
  controllers: [ApiKeyController],
  providers: [ApiKeyService, RateLimitInterceptor],
  exports: [ApiKeyService],
})
export class ApiKeyModule {}
