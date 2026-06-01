import { Repository } from 'typeorm';
import { AuditLog } from '../entities/audit-log.entity';
export declare class AuditService {
    private auditLogRepository;
    constructor(auditLogRepository: Repository<AuditLog>);
    log(params: {
        userId: string;
        username: string;
        action: string;
        resource: string;
        resourceId?: string;
        details?: any;
        ip: string;
        userAgent?: string;
    }): Promise<void>;
    getLogs(options: {
        page?: number;
        limit?: number;
        userId?: string;
        action?: string;
        resource?: string;
        startDate?: Date;
        endDate?: Date;
    }): Promise<{
        code: number;
        message: string;
        data: {
            logs: AuditLog[];
            total: number;
            page: number;
            limit: number;
            totalPages: number;
        };
    }>;
}
