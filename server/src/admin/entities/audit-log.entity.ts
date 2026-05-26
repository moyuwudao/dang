import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('audit_logs')
export class AuditLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column()
  username: string;

  @Column()
  action: string; // CREATE, UPDATE, DELETE, LOGIN, LOGOUT, EXECUTE

  @Column()
  resource: string; // api_key, plan, subscription, user, system

  @Column({ name: 'resource_id', nullable: true })
  resourceId: string;

  @Column({ type: 'text', nullable: true })
  details: string; // JSON字符串，记录操作详情

  @Column()
  ip: string;

  @Column({ name: 'user_agent', nullable: true })
  userAgent: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
