export declare class AuditLog {
    id: string;
    userId: string;
    username: string;
    action: string;
    resource: string;
    resourceId: string;
    details: string;
    ip: string;
    userAgent: string;
    createdAt: Date;
}
