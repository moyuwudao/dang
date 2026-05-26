import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

export enum ApiKeyProvider {
  QWEN = 'qwen',
  OPENAI = 'openai',
  ANTHROPIC = 'anthropic',
  GEMINI = 'gemini',
  DEEPSEEK = 'deepseek',
  GROK = 'grok',
  CUSTOM = 'custom',
}

export enum ApiKeyStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  EXPIRED = 'expired',
  REVOKED = 'revoked',
}

export enum ApiKeyScope {
  TRANSCRIPTION = 'transcription',
  SUMMARY = 'summary',
  CHAT = 'chat',
  TRANSLATION = 'translation',
  ALL = 'all',
}

@Entity('api_keys')
export class ApiKey {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({
    type: 'enum',
    enum: ApiKeyProvider,
    default: ApiKeyProvider.CUSTOM,
  })
  provider: ApiKeyProvider;

  @Column()
  name: string;

  @Column({ nullable: true })
  description: string;

  @Column({ name: 'apiKeyEncrypted' })
  apiKeyEncrypted: string;

  @Column({ name: 'apiSecretEncrypted', nullable: true })
  apiSecretEncrypted: string;

  @Column()
  model: string;

  @Column({ name: 'base_url', nullable: true })
  baseUrl: string;

  @Column({
    type: 'enum',
    enum: ApiKeyStatus,
    default: ApiKeyStatus.ACTIVE,
  })
  status: ApiKeyStatus;

  @Column({ type: 'simple-array', nullable: true })
  scopes: ApiKeyScope[];

  @Column({ name: 'rate_limit_per_min', default: 60 })
  rateLimitPerMin: number;

  @Column({ name: 'max_concurrent_requests', default: 5 })
  maxConcurrentRequests: number;

  @Column({ name: 'daily_quota', default: 1000 })
  dailyQuota: number;

  @Column({ name: 'daily_usage', default: 0 })
  dailyUsage: number;

  @Column({ name: 'expires_at', type: 'date', nullable: true })
  expiresAt: Date;

  @Column({ name: 'is_default', default: false })
  isDefault: boolean;

  @Column({ name: 'last_used_at', nullable: true })
  lastUsedAt: Date;

  @Column({ name: 'last_health_check_at', nullable: true })
  lastHealthCheckAt: Date;

  @Column({ name: 'last_health_check_status', nullable: true })
  lastHealthCheckStatus: string;

  @Column({ name: 'allowed_ip_ranges', nullable: true })
  allowedIpRanges: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
