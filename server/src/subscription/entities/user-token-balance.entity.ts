import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('user_token_balances')
export class UserTokenBalance {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', unique: true })
  userId: string;

  @Column({ name: 'total_tokens', type: 'decimal', precision: 15, scale: 4, default: 0 })
  totalTokens: number;

  @Column({ name: 'used_tokens', type: 'decimal', precision: 15, scale: 4, default: 0 })
  usedTokens: number;

  @Column({ name: 'balance_tokens', type: 'decimal', precision: 15, scale: 4, default: 0 })
  balanceTokens: number;

  @Column({ name: 'free_tokens_remaining', type: 'decimal', precision: 15, scale: 4, default: 500 })
  freeTokensRemaining: number;

  @Column({ name: 'expires_at', nullable: true })
  expiresAt: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
