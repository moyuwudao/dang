import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HttpModule } from '@nestjs/axios';
import { ApiKeyController } from './api-key.controller';
import { ApiKeyService } from './api-key.service';
import { ApiKeyHealthService } from './api-key-health.service';
import { ApiKey } from './entities/api-key.entity';
import { UserApiKey } from './entities/user-api-key.entity';
import { RateLimitInterceptor } from './interceptors/rate-limit.interceptor';

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
  providers: [ApiKeyService, ApiKeyHealthService, RateLimitInterceptor],
  exports: [ApiKeyService, ApiKeyHealthService],
})
export class ApiKeyModule {}
