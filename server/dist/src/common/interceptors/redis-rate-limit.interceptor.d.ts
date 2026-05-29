import { NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { RedisService } from '../../redis/redis.service';
export declare class RedisRateLimitInterceptor implements NestInterceptor {
    private readonly redisService;
    constructor(redisService: RedisService);
    intercept(context: ExecutionContext, next: CallHandler): Promise<Observable<any>>;
}
