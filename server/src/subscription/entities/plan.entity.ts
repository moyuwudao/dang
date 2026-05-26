import { Entity, PrimaryColumn, Column } from 'typeorm';

@Entity('plans')
export class Plan {
  @PrimaryColumn()
  id: string;

  @Column()
  name: string;

  @Column({ nullable: true })
  description: string;

  @Column()
  priceCents: number;

  @Column()
  durationDays: number;

  @Column({ default: 'subscription' })
  type: string; // subscription | package | recharge

  @Column({ default: 'all' })
  apiPolicyType: string; // all | domestic | basic | custom

  @Column('simple-array', { nullable: true })
  features: string[];

  @Column({ default: false })
  isRecommended: boolean;

  @Column()
  quotaType: string;

  @Column({ nullable: true })
  quotaValue: number;

  @Column({ default: true })
  isActive: boolean;
}
