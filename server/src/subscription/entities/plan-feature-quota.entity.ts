import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { Plan } from './plan.entity';

@Entity('plan_feature_quotas')
export class PlanFeatureQuota {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'plan_id' })
  planId: string;

  @Column({ name: 'feature_type' })
  featureType: string; // transcription | text_analysis | image_recognition | ocr | ai_chat | tts

  @Column({ name: 'quota_value' })
  quotaValue: number;

  @Column({ name: 'quota_unit' })
  quotaUnit: string; // minutes | thousand_chars | images | tokens

  // 成本系数（不同模型不同系数）
  @Column({ default: 1.0 })
  multiplier: number;

  @ManyToOne(() => Plan, plan => plan.featureQuotas)
  @JoinColumn({ name: 'planId' })
  plan: Plan;
}
