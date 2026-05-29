import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

/**
 * Token定价实体
 * 支持多种计费维度：
 * - ai_chat: AI对话 (按tokens计费，分输入/输出)
 * - transcription: 语音转写 (按分钟计费)
 * - realtime_transcription: 实时转写 (按分钟计费)
 * - text_analysis: 文本分析 (按千字符计费)
 * - image_recognition: 图像识别 (按张计费)
 * - ocr: OCR识别 (按张计费)
 * - tts: 语音合成 (按千字符计费)
 */
@Entity('token_pricing')
export class TokenPricing {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'provider' })
  provider: string; // qwen | deepseek | openai | anthropic | gemini | grok | internal

  @Column({ name: 'model_pattern' })
  modelPattern: string; // 模型标识，如 gpt-4, qwen-turbo, whisper-1 等

  @Column({ name: 'model_name', nullable: true })
  modelName: string; // 模型显示名称

  /**
   * 功能类型
   * - ai_chat: AI对话
   * - transcription: 语音转写
   * - realtime_transcription: 实时转写
   * - text_analysis: 文本分析
   * - image_recognition: 图像识别
   * - ocr: OCR识别
   * - tts: 语音合成
   */
  @Column({ name: 'feature_type', default: 'ai_chat' })
  featureType: string;

  /**
   * 计费维度
   * - tokens: 按token数量（AI对话）
   * - minutes: 按分钟（语音转写）
   * - thousand_chars: 按千字符（文本分析、语音合成）
   * - images: 按张数（图像识别、OCR）
   */
  @Column({ name: 'billing_unit', default: 'tokens' })
  billingUnit: string;

  @Column({ name: 'prompt_price_per_1k', type: 'decimal', precision: 10, scale: 6, default: 0 })
  promptPricePer1k: number; // 输入/基础价格（元/单位）

  @Column({ name: 'completion_price_per_1k', type: 'decimal', precision: 10, scale: 6, default: 0 })
  completionPricePer1k: number; // 输出价格（元/单位），仅AI对话有区分

  @Column({ name: 'currency', default: 'CNY' })
  currency: string; // CNY | USD

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
