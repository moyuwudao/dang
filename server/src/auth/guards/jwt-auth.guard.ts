import { Injectable, CanActivate, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Reflector } from '@nestjs/core';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private jwtService: JwtService,
    private reflector: Reflector,
  ) {}

  // 公开路由列表（不需要认证）
  private readonly publicRoutes = [
    { path: '/auth/login', method: 'POST' },
    { path: '/auth/register', method: 'POST' },
    { path: '/auth/refresh', method: 'POST' },
    { path: '/auth/send-verification-code', method: 'POST' },
    { path: '/health', method: 'GET' },
  ];

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const path = request.route?.path || request.url;
    const method = request.method;

    // 检查是否是公开路由（支持带前缀的路径）
    const isPublic = this.publicRoutes.some(
      route => (path === route.path || path.endsWith(route.path)) && route.method === method
    );

    if (isPublic) {
      return true;
    }

    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('缺少认证令牌');
    }

    const token = authHeader.substring(7);

    try {
      const payload = this.jwtService.verify(token);
      request.user = payload;
      return true;
    } catch {
      throw new UnauthorizedException('令牌无效或已过期');
    }
  }
}
