import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AuditLog } from '../entities/audit-log.entity';

@Injectable()
export class AuditService {
  constructor(
    @InjectRepository(AuditLog)
    private auditLogRepository: Repository<AuditLog>,
  ) {}

  async log(params: {
    userId: string;
    username: string;
    action: string;
    resource: string;
    resourceId?: string;
    details?: any;
    ip: string;
    userAgent?: string;
  }) {
    const log = this.auditLogRepository.create({
      ...params,
      details: params.details ? JSON.stringify(params.details) : null,
    });
    await this.auditLogRepository.save(log);
  }

  async getLogs(options: {
    page?: number;
    limit?: number;
    userId?: string;
    action?: string;
    resource?: string;
    startDate?: Date;
    endDate?: Date;
  }) {
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
}
