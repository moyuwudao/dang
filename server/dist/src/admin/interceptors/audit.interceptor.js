"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuditInterceptor = void 0;
const common_1 = require("@nestjs/common");
const operators_1 = require("rxjs/operators");
const audit_service_1 = require("../services/audit.service");
let AuditInterceptor = class AuditInterceptor {
    constructor(auditService) {
        this.auditService = auditService;
    }
    intercept(context, next) {
        const request = context.switchToHttp().getRequest();
        const user = request.user;
        const method = request.method;
        const path = request.route?.path || request.url;
        const ip = request.ip || request.connection?.remoteAddress || 'unknown';
        const userAgent = request.headers['user-agent'];
        const sensitiveActions = ['POST', 'PUT', 'DELETE', 'PATCH'];
        if (!sensitiveActions.includes(method)) {
            return next.handle();
        }
        const { action, resource } = this.parseAction(method, path);
        return next.handle().pipe((0, operators_1.tap)(async (response) => {
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
                }
                catch (error) {
                    console.error('Audit log failed:', error);
                }
            }
        }));
    }
    parseAction(method, path) {
        const actionMap = {
            POST: 'CREATE',
            PUT: 'UPDATE',
            PATCH: 'UPDATE',
            DELETE: 'DELETE',
        };
        const action = actionMap[method] || 'UNKNOWN';
        let resource = 'unknown';
        if (path.includes('api-key'))
            resource = 'api_key';
        else if (path.includes('plan'))
            resource = 'plan';
        else if (path.includes('subscription'))
            resource = 'subscription';
        else if (path.includes('user'))
            resource = 'user';
        else if (path.includes('monitor'))
            resource = 'system';
        else if (path.includes('recharge'))
            resource = 'recharge';
        else if (path.includes('refund'))
            resource = 'refund';
        return { action, resource };
    }
    sanitizeBody(body) {
        if (!body)
            return null;
        const sensitiveFields = ['password', 'apiKey', 'apiSecret', 'token', 'secret'];
        const sanitized = { ...body };
        for (const field of sensitiveFields) {
            if (sanitized[field]) {
                sanitized[field] = '***';
            }
        }
        return sanitized;
    }
};
exports.AuditInterceptor = AuditInterceptor;
exports.AuditInterceptor = AuditInterceptor = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [audit_service_1.AuditService])
], AuditInterceptor);
//# sourceMappingURL=audit.interceptor.js.map