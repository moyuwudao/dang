import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('api_usage_logs')
export class ApiUsageLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column()
  provider: string;

  @Column()
  model: string;

  @Column({ name: 'prompt_tokens', default: 0 })
  promptTokens: number;

  @Column({ name: 'completion_tokens', default: 0 })
  completionTokens: number;

  @Column({ name: 'token_consumed', default: 0 })
  tokenConsumed: number;

  @Column({ name: 'api_coefficient', type: 'decimal', precision: 10, scale: 4, default: 1.0 })
  apiCoefficient: number;

  @Column({ name: 'cost_yuan', type: 'decimal', precision: 10, scale: 4, nullable: true })
  costYuan: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
