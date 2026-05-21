import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, OneToOne } from 'typeorm';
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

  @OneToOne(() => User, user => user.balance)
  user: User;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
