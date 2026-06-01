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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuditService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const audit_log_entity_1 = require("../entities/audit-log.entity");
let AuditService = class AuditService {
    constructor(auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }
    async log(params) {
        const log = this.auditLogRepository.create({
            ...params,
            details: params.details ? JSON.stringify(params.details) : null,
        });
        await this.auditLogRepository.save(log);
    }
    async getLogs(options) {
        const { page = 1, limit = 20, userId, action, resource, startDate, endDate } = options;
        const queryBuilder = this.auditLogRepository.createQueryBuilder('log')
            .orderBy('log.createdAt', 'DESC')
            .skip((page - 1) * limit)
            .take(limit);
        if (userId) {
            queryBuilder.andWhere('log.userId = :userId', { userId });
        }
        if (action) {
            queryBuilder.andWhere('log.action = :action', { action });
        }
        if (resource) {
            queryBuilder.andWhere('log.resource = :resource', { resource });
        }
        if (startDate) {
            queryBuilder.andWhere('log.createdAt >= :startDate', { startDate });
        }
        if (endDate) {
            queryBuilder.andWhere('log.createdAt <= :endDate', { endDate });
        }
        const [logs, total] = await queryBuilder.getManyAndCount();
        return {
            code: 200,
            message: 'success',
            data: {
                logs,
                total,
                page,
                limit,
                totalPages: Math.ceil(total / limit),
            },
        };
    }
};
exports.AuditService = AuditService;
exports.AuditService = AuditService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(audit_log_entity_1.AuditLog)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], AuditService);
//# sourceMappingURL=audit.service.js.map