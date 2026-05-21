import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

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

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
