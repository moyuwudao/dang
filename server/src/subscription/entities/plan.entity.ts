import { Entity, PrimaryColumn, Column } from 'typeorm';

@Entity('plans')
export class Plan {
  @PrimaryColumn()
  id: string;

  @Column()
  name: string;

  @Column({ nullable: true })
  description: string;

  @Column({ name: 'price_cents' })
  priceCents: number;

  @Column({ name: 'token_quota', nullable: true })
  tokenQuota: number;

  @Column({ name: 'duration_days', default: 30 })
  durationDays: number;

  @Column({ default: 'monthly' })
  type: string; // monthly | recharge

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  // 兼容历史：原 simple-array 在 PG 中存为 text，但 TypeORM 0.3.x update 时会强制数组化导致 malformed array literal
  // 改为 text 类型，业务层自行 join/split
  @Column('text', { name: 'allowed_models', nullable: true })
  allowedModels: string;

  // WEB端问题3修复：套餐默认API配置（按功能类型分类）
  // 数据结构：{ "textAnalysis": "alibabaQwenMax", "speechTranscribe": "alibabaQwenAsr", "speechRealtime": "alibabaQwenAsrRealtime", "speechOffline": "alibabaQwenAsrOffline", "imageRecognition": "alibabaQwenVlMax" }
  @Column('jsonb', { name: 'default_configs', default: () => "'{}'::jsonb" })
  defaultConfigs: Record<string, string>;

  // 套餐可用 API 策略（含计费系数和是否允许）
  // 数据结构：[
  //   { provider: 'alibabaQwen', model: 'qwen-turbo', modelPattern: 'qwen-turbo', multiplier: 0.5, isAllowed: true },
  //   ...
  // ]
  @Column('jsonb', { name: 'api_policies', default: () => "'[]'::jsonb" })
  apiPolicies: Array<{
    provider: string;
    model?: string;
    modelPattern?: string;
    multiplier: number;
    isAllowed?: boolean;
  }>;
}
