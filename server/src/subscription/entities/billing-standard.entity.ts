import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('billing_standards')
export class BillingStandard {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'plan_id', nullable: true })
  planId: string;

  @Column({ name: 'function_type' })
  functionType: string;

  @Column({ nullable: true })
  tier: string;

  @Column({ name: 'base_price_cents', type: 'int', nullable: true })
  basePriceCents: number;

  @Column({ nullable: true })
  unit: string;

  @Column({ nullable: true })
  provider: string;

  @Column({ name: 'model_pattern', nullable: true })
  modelPattern: string;

  @Column({ name: 'pricing_model', nullable: true })
  pricingModel: string;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @Column({ nullable: true })
  notes: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
