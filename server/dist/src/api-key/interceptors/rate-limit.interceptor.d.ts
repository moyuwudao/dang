import { NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { Repository } from 'typeorm';
import { ApiKey } from '../entities/api-key.entity';
export declare class RateLimitInterceptor implements NestInterceptor {
    private apiKeyRepository;
    constructor(apiKeyRepository: Repository<ApiKey>);
    intercept(context: ExecutionContext, next: CallHandler): Promise<Observable<any>>;
    private checkRateLimit;
    private checkConcurrentLimit;
    private incrementConcurrent;
    private decrementConcurrent;
}
