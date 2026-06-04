import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne } from 'typeorm';
import { User } from '../../auth/entities/user.entity';

@Entity('subscriptions')
export class Subscription {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  // 修复 schema mismatch: 实体 name 与 DB 实际列名一致（camelCase）
  // 原: @Column({ name: 'user_id' }) → 现: 去除 name，typeorm 默认用属性名 userId
  @Column()
  userId: string;

  @ManyToOne(() => User, user => user.subscriptions)
  user: User;

  // 原: @Column({ name: 'plan_id' }) → DB 列名 planId
  @Column()
  planId: string;

  @Column({ default: 'active' })
  status: string;

  // 原: @Column({ name: 'started_at', type: 'timestamp' }) → DB 列名 startedAt
  @Column({ type: 'timestamp' })
  startedAt: Date;

  // 原: @Column({ name: 'expires_at', type: 'timestamp' }) → DB 列名 expiresAt
  @Column({ type: 'timestamp' })
  expiresAt: Date;

  // 原: @Column({ name: 'token_quota', default: 0 }) → DB 列名 totalQuota
  @Column({ default: 0 })
  totalQuota: number;

  // 原: @Column({ name: 'used_tokens', default: 0 }) → DB 列名 usedQuota
  @Column({ default: 0 })
  usedQuota: number;

  // 原: @Column({ name: 'balance_tokens', default: 0 }) → DB 无此列（balanceTokens 在 user_token_balances 表）
  // 移除该字段映射，避免 INSERT/UPDATE 写入不存在的列导致 500

  @Column({ default: 'subscription' })
  type: string; // subscription | recharge

  // DB 实际列名: createdAt, updatedAt（camelCase）
  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
