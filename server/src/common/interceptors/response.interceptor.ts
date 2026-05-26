import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
  timestamp: string;
}

@Injectable()
export class ResponseInterceptor<T> implements NestInterceptor<T, ApiResponse<T>> {
  intercept(context: ExecutionContext, next: CallHandler): Observable<ApiResponse<T>> {
    return next.handle().pipe(
      map((data) => {
        // 如果已经是标准格式，直接返回
        if (data && typeof data === 'object' && 'code' in data && 'message' in data) {
          return {
            ...data,
            timestamp: new Date().toISOString(),
          };
        }

        // 包装为标准格式
        return {
          code: 200,
          message: 'success',
          data,
          timestamp: new Date().toISOString(),
        };
      }),
    );
  }
}
