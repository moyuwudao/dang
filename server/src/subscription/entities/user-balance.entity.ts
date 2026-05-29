import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, OneToOne, JoinColumn } from 'typeorm';
import { User } from '../../auth/entities/user.entity';

@Entity('user_balances')
export class UserBalance {
  @PrimaryColumn()
  userId: string;

  @Column({ default: 0 })
  balanceCents: number;

  @Column({ default: 0 })
  totalRechargedCents: number;

  @Column({ default: 0 })
  totalRefundedCents: number;

  @Column({ name: 'gift_balance_cents', default: 0 })
  giftBalanceCents: number;

  @OneToOne(() => User, user => user.balance)
  @JoinColumn({ name: 'userId' })
  user: User;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
