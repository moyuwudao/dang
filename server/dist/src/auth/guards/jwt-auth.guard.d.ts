import { CanActivate, ExecutionContext } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Reflector } from '@nestjs/core';
export declare class JwtAuthGuard implements CanActivate {
    private jwtService;
    private reflector;
    constructor(jwtService: JwtService, reflector: Reflector);
    private readonly publicRoutes;
    canActivate(context: ExecutionContext): boolean;
}
