import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('user_feature_usage')
export class UserFeatureUsage {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({ name: 'subscription_id' })
  subscriptionId: string;

  @Column({ name: 'feature_type' })
  featureType: string;

  @Column({ name: 'used_amount', default: 0 })
  usedAmount: number;

  @Column({ name: 'total_amount' })
  totalAmount: number;

  @Column({ name: 'unit' })
  unit: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
