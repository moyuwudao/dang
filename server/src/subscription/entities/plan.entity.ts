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

  @Column()
  quotaType: string;

  @Column({ nullable: true })
  quotaValue: number;

  @Column({ default: true })
  isActive: boolean;
}
