import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { AuditService } from '../services/audit.service';

@Injectable()
export class AuditInterceptor implements NestInterceptor {
  constructor(private readonly auditService: AuditService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    const method = request.method;
    const path = request.route?.path || request.url;
    const ip = request.ip || request.connection?.remoteAddress || 'unknown';
    const userAgent = request.headers['user-agent'];

    // 只记录敏感操作（增删改、执行命令）
    const sensitiveActions = ['POST', 'PUT', 'DELETE', 'PATCH'];
    if (!sensitiveActions.includes(method)) {
      return next.handle();
    }

    // 解析操作类型和资源
    const { action, resource } = this.parseAction(method, path);

    return next.handle().pipe(
      tap(async (response) => {
        if (user) {
          try {
            await this.auditService.log({
              userId: user.sub || user.userId,
              username: user.phone || user.username || 'unknown',
              action,
              resource,
              resourceId: request.params?.id,
              details: {
                path,
                method,
                body: this.sanitizeBody(request.body),
                response: response?.code === 200 ? 'success' : 'failed',
              },
              ip,
              userAgent,
            });
          } catch (error) {
            // 审计日志记录失败不应影响主流程
            console.error('Audit log failed:', error);
          }
        }
      }),
    );
  }

  private parseAction(method: string, path: string): { action: string; resource: string } {
    // 根据 HTTP 方法和路径解析操作类型
    const actionMap: Record<string, string> = {
      POST: 'CREATE',
      PUT: 'UPDATE',
      PATCH: 'UPDATE',
      DELETE: 'DELETE',
    };

    const action = actionMap[method] || 'UNKNOWN';

    // 解析资源类型
    let resource = 'unknown';
    if (path.includes('api-key')) resource = 'api_key';
    else if (path.includes('plan')) resource = 'plan';
    else if (path.includes('subscription')) resource = 'subscription';
    else if (path.includes('user')) resource = 'user';
    else if (path.includes('monitor')) resource = 'system';
    else if (path.includes('recharge')) resource = 'recharge';
    else if (path.includes('refund')) resource = 'refund';

    return { action, resource };
  }

  private sanitizeBody(body: any): any {
    if (!body) return null;
    
    // 移除敏感字段
    const sensitiveFields = ['password', 'apiKey', 'apiSecret', 'token', 'secret'];
    const sanitized = { ...body };
    
    for (const field of sensitiveFields) {
      if (sanitized[field]) {
        sanitized[field] = '***';
      }
    }
    
    return sanitized;
  }
}
