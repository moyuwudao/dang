import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Subscription } from './subscription.entity';
import { ApiKey } from '../../api-key/entities/api-key.entity';
import { User } from '../../auth/entities/user.entity';

@Entity('api_usage_logs')
export class ApiUsageLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({ name: 'subscription_id', nullable: true })
  subscriptionId: string;

  @Column({ name: 'api_key_id', nullable: true })
  apiKeyId: string;

  @Column()
  provider: string;

  @Column()
  model: string;

  @Column({ name: 'prompt_tokens', default: 0 })
  promptTokens: number;

  @Column({ name: 'completion_tokens', default: 0 })
  completionTokens: number;

  @Column({ name: 'quota_consumed' })
  quotaConsumed: number;

  @Column({ name: 'cost_cents', nullable: true })
  costCents: number;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @ManyToOne(() => Subscription)
  @JoinColumn({ name: 'subscription_id' })
  subscription: Subscription;

  @ManyToOne(() => ApiKey)
  @JoinColumn({ name: 'api_key_id' })
  apiKey: ApiKey;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
