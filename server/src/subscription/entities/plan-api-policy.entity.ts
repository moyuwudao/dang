import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Plan } from './plan.entity';

@Entity('plan_api_policies')
export class PlanApiPolicy {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  planId: string;

  @Column()
  provider: string;

  @Column({ nullable: true })
  modelPattern: string;

  @Column({ type: 'decimal', precision: 3, scale: 1, default: 1.0 })
  multiplier: number;

  @Column({ default: true })
  isAllowed: boolean;

  @ManyToOne(() => Plan)
  @JoinColumn({ name: 'planId' })
  plan: Plan;

  @CreateDateColumn()
  createdAt: Date;
}