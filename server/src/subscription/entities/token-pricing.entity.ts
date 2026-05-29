import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('token_pricing')
export class TokenPricing {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'provider' })
  provider: string; // openai | anthropic | gemini

  @Column({ name: 'model_pattern' })
  modelPattern: string; // gpt-4 | claude-3-opus | *

  @Column({ name: 'prompt_price_per_1k' })
  promptPricePer1k: number; // 每1000 tokens输入价格（分）

  @Column({ name: 'completion_price_per_1k' })
  completionPricePer1k: number; // 每1000 tokens输出价格（分）

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
