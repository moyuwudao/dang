import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Plan } from './plan.entity';

@Entity('plan_api_policies')
export class PlanApiPolicy {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'plan_id' })
  planId: string;

  @Column()
  provider: string;

  @Column({ name: 'model_pattern', nullable: true })
  modelPattern: string;

  @Column({ type: 'decimal', precision: 3, scale: 1, default: 1.0 })
  multiplier: number;

  @Column({ name: 'is_allowed', default: true })
  isAllowed: boolean;

  @ManyToOne(() => Plan)
  @JoinColumn({ name: 'plan_id' })
  plan: Plan;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
