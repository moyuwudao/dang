import { Entity, PrimaryColumn, Column, OneToMany } from 'typeorm';
import { PlanFeatureQuota } from './plan-feature-quota.entity';

@Entity('plans')
export class Plan {
  @PrimaryColumn()
  id: string;

  @Column()
  name: string;

  @Column({ nullable: true })
  description: string;

  @Column({ name: 'priceCents' })
  priceCents: number;

  @Column({ name: 'durationDays' })
  durationDays: number;

  @Column({ default: 'subscription' })
  type: string; // subscription | package | recharge

  @Column({ name: 'api_policy_type', default: 'all' })
  apiPolicyType: string; // all | domestic | basic | custom

  @Column('simple-array', { nullable: true })
  features: string[];

  @Column({ name: 'isRecommended', default: false })
  isRecommended: boolean;

  @Column({ name: 'quotaType' })
  quotaType: string;

  @Column({ name: 'quotaValue', nullable: true })
  quotaValue: number;

  @Column({ name: 'isActive', default: true })
  isActive: boolean;

  @Column('simple-array', { name: 'allowed_models', nullable: true })
  allowedModels: string[];

  @OneToMany(() => PlanFeatureQuota, quota => quota.plan)
  featureQuotas: PlanFeatureQuota[];
}
