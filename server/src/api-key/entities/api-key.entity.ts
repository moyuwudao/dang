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

  @Column()
  apiKeyEncrypted: string;

  @Column({ nullable: true })
  apiSecretEncrypted: string;

  @Column()
  model: string;

  @Column({ nullable: true })
  baseUrl: string;

  @Column({
    type: 'enum',
    enum: ApiKeyStatus,
    default: ApiKeyStatus.ACTIVE,
  })
  status: ApiKeyStatus;

  @Column({ type: 'simple-array', nullable: true })
  scopes: ApiKeyScope[];

  @Column({ default: 60 })
  rateLimitPerMin: number;

  @Column({ default: 5 })
  maxConcurrentRequests: number;

  @Column({ default: 1000 })
  dailyQuota: number;

  @Column({ default: 0 })
  dailyUsage: number;

  @Column({ type: 'date', nullable: true })
  expiresAt: Date;

  @Column({ default: false })
  isDefault: boolean;

  @Column({ nullable: true })
  lastUsedAt: Date;

  @Column({ nullable: true })
  lastHealthCheckAt: Date;

  @Column({ nullable: true })
  lastHealthCheckStatus: string;

  @Column({ nullable: true })
  allowedIpRanges: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
