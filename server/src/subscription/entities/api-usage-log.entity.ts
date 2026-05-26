import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Subscription } from './subscription.entity';
import { ApiKey } from '../../api-key/entities/api-key.entity';

@Entity('api_usage_logs')
export class ApiUsageLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @Column({ nullable: true })
  subscriptionId: string;

  @Column({ nullable: true })
  apiKeyId: string;

  @Column()
  provider: string;

  @Column()
  model: string;

  @Column({ default: 0 })
  promptTokens: number;

  @Column({ default: 0 })
  completionTokens: number;

  @Column()
  quotaConsumed: number;

  @Column({ nullable: true })
  costCents: number;

  @ManyToOne(() => Subscription)
  @JoinColumn({ name: 'subscriptionId' })
  subscription: Subscription;

  @ManyToOne(() => ApiKey)
  @JoinColumn({ name: 'apiKeyId' })
  apiKey: ApiKey;

  @CreateDateColumn()
  createdAt: Date;
}