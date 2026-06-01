import { Entity, PrimaryColumn, Column } from 'typeorm';

@Entity('plans')
export class Plan {
  @PrimaryColumn()
  id: string;

  @Column()
  name: string;

  @Column({ nullable: true })
  description: string;

  @Column({ name: 'price_cents' })
  priceCents: number;

  @Column({ name: 'token_quota', nullable: true })
  tokenQuota: number;

  @Column({ name: 'duration_days', default: 30 })
  durationDays: number;

  @Column({ default: 'monthly' })
  type: string; // monthly | recharge

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @Column('simple-array', { name: 'allowed_models', nullable: true })
  allowedModels: string[];
}
