import { Injectable, NestInterceptor, ExecutionContext, CallHandler, HttpException } from '@nestjs/common';
import { Observable } from 'rxjs';
import { RedisService } from '../../redis/redis.service';

@Injectable()
export class RedisRateLimitInterceptor implements NestInterceptor {
  constructor(private readonly redisService: RedisService) {}

  async intercept(context: ExecutionContext, next: CallHandler): Promise<Observable<any>> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    const userId = user?.sub || user?.userId || 'anonymous';
    const ip = request.ip || request.connection?.remoteAddress || 'unknown';

    // 用户级限流：每分钟 60 次
    const userKey = `rate_limit:user:${userId}`;
    const userLimit = await this.redisService.rateLimit(userKey, 60, 60);
    if (!userLimit.allowed) {
      throw new HttpException({
        code: 429,
        message: '请求过于频繁，请稍后再试',
        data: {
          remaining: userLimit.remaining,
          resetTime: userLimit.resetTime,
        },
      }, 429);
    }

    // IP 级限流：每分钟 100 次
    const ipKey = `rate_limit:ip:${ip}`;
    const ipLimit = await this.redisService.rateLimit(ipKey, 100, 60);
    if (!ipLimit.allowed) {
      throw new HttpException({
        code: 429,
        message: '该IP请求过于频繁',
        data: {
          remaining: ipLimit.remaining,
          resetTime: ipLimit.resetTime,
        },
      }, 429);
    }

    // 全局限流：每分钟 1000 次
    const globalKey = `rate_limit:global`;
    const globalLimit = await this.redisService.rateLimit(globalKey, 1000, 60);
    if (!globalLimit.allowed) {
      throw new HttpException({
        code: 429,
        message: '系统繁忙，请稍后再试',
        data: {
          remaining: globalLimit.remaining,
          resetTime: globalLimit.resetTime,
        },
      }, 429);
    }

    return next.handle();
  }
}
