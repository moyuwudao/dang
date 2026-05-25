import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  HttpException,
} from '@nestjs/common';
import { Observable, throwError } from 'rxjs';
import { catchError, tap } from 'rxjs/operators';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiKey } from '../entities/api-key.entity';

// 内存中的请求计数器
const requestCounters = new Map<string, { count: number; resetTime: number }>();
const concurrentRequests = new Map<string, number>();

@Injectable()
export class RateLimitInterceptor implements NestInterceptor {
  constructor(
    @InjectRepository(ApiKey)
    private apiKeyRepository: Repository<ApiKey>,
  ) {}

  async intercept(context: ExecutionContext, next: CallHandler): Promise<Observable<any>> {
    const request = context.switchToHttp().getRequest();
    const apiKeyId = request.headers['x-api-key-id'];
    
    if (!apiKeyId) {
      return next.handle();
    }

    const apiKey = await this.apiKeyRepository.findOne({
      where: { id: apiKeyId },
    });

    if (!apiKey || apiKey.status !== 'active') {
      return throwError(() => new HttpException('API Key 无效或已停用', 403));
    }

    // 检查速率限制
    const rateLimitCheck = this.checkRateLimit(apiKeyId, apiKey.rateLimitPerMin);
    if (!rateLimitCheck.allowed) {
      return throwError(() =>
        new HttpException(
          `请求过于频繁，请稍后再试。限制：${apiKey.rateLimitPerMin} 请求/分钟`,
          429,
        ),
      );
    }

    // 检查并发限制
    const concurrentCheck = this.checkConcurrentLimit(apiKeyId, apiKey.maxConcurrentRequests);
    if (!concurrentCheck.allowed) {
      return throwError(() =>
        new HttpException(
          `并发请求过多，请稍后再试。限制：${apiKey.maxConcurrentRequests} 并发`,
          429,
        ),
      );
    }

    // 检查日配额
    if (apiKey.dailyUsage >= apiKey.dailyQuota) {
      return throwError(() =>
        new HttpException(
          `日配额已用完。配额：${apiKey.dailyQuota}，已用：${apiKey.dailyUsage}`,
          429,
        ),
      );
    }

    // 增加并发计数
    this.incrementConcurrent(apiKeyId);

    // 更新最后使用时间
    apiKey.lastUsedAt = new Date();
    await this.apiKeyRepository.save(apiKey);

    return next.handle().pipe(
      tap(async () => {
        // 请求成功，增加日使用量
        apiKey.dailyUsage += 1;
        await this.apiKeyRepository.save(apiKey);
      }),
      catchError(async (error) => {
        // 请求失败也减少并发计数
        this.decrementConcurrent(apiKeyId);
        return throwError(() => error);
      }),
      tap(() => {
        // 请求完成，减少并发计数
        this.decrementConcurrent(apiKeyId);
      }),
    );
  }

  private checkRateLimit(apiKeyId: string, limitPerMin: number): { allowed: boolean } {
    const now = Date.now();
    const windowMs = 60 * 1000; // 1分钟窗口
    const counter = requestCounters.get(apiKeyId);

    if (!counter || now > counter.resetTime) {
      // 新窗口
      requestCounters.set(apiKeyId, {
        count: 1,
        resetTime: now + windowMs,
      });
      return { allowed: true };
    }

    if (counter.count >= limitPerMin) {
      return { allowed: false };
    }

    counter.count += 1;
    return { allowed: true };
  }

  private checkConcurrentLimit(apiKeyId: string, maxConcurrent: number): { allowed: boolean } {
    const current = concurrentRequests.get(apiKeyId) || 0;
    return { allowed: current < maxConcurrent };
  }

  private incrementConcurrent(apiKeyId: string): void {
    const current = concurrentRequests.get(apiKeyId) || 0;
    concurrentRequests.set(apiKeyId, current + 1);
  }

  private decrementConcurrent(apiKeyId: string): void {
    const current = concurrentRequests.get(apiKeyId) || 0;
    if (current > 0) {
      concurrentRequests.set(apiKeyId, current - 1);
    }
  }
}
