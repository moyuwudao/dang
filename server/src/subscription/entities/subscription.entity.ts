import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { User } from '../../auth/entities/user.entity';
import { Plan } from './plan.entity';

@Entity('subscriptions')
export class Subscription {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'userId' })
  userId: string;

  @Column({ name: 'planId' })
  planId: string;

  @Column({ default: 'active' })
  status: string;

  @Column({ name: 'startedAt', type: 'timestamp' })
  startedAt: Date;

  @Column({ name: 'expiresAt', type: 'timestamp' })
  expiresAt: Date;

  @Column({ name: 'totalQuota', default: 0 })
  totalQuota: number;

  @Column({ name: 'usedQuota', default: 0 })
  usedQuota: number;

  @Column({ name: 'balance_quota', default: 0 })
  balanceQuota: number;

  @Column({ default: 'subscription' })
  type: string; // subscription | package

  @ManyToOne(() => User, user => user.subscriptions)
  @JoinColumn({ name: 'userId' })
  user: User;

  @ManyToOne(() => Plan)
  @JoinColumn({ name: 'planId' })
  plan: Plan;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
