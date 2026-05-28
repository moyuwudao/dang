import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

/**
 * 套餐场景默认模型配置
 * 为每个套餐的每个AI功能场景配置默认使用的模型
 */
@Entity('plan_default_configs')
export class PlanDefaultConfig {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'plan_id' })
  planId: string;

  /**
   * 功能场景：
   * - text_analysis: 文本分析
   * - voice_transcription: 语音转写
   * - realtime_transcription: 实时转写
   * - offline_transcription: 离线转写
   * - image_recognition: 图像识别
   */
  @Column({ name: 'function_type' })
  functionType: string;

  /**
   * 模型标识：格式为 "provider:model-name"
   * 例如："qwen:qwen3.6-plus", "deepseek:deepseek-v4-pro"
   */
  @Column({ name: 'model_pattern' })
  modelPattern: string;

  /**
   * 是否启用此默认配置
   */
  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
