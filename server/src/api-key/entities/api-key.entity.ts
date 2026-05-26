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

  @Column({ name: 'baseUrl', nullable: true })
  baseUrl: string;

  @Column({
    type: 'enum',
    enum: ApiKeyStatus,
    default: ApiKeyStatus.ACTIVE,
  })
  status: ApiKeyStatus;

  @Column({ type: 'simple-array', nullable: true })
  scopes: ApiKeyScope[];

  @Column({ name: 'rateLimitPerMin', default: 60 })
  rateLimitPerMin: number;

  @Column({ name: 'maxConcurrentRequests', default: 5 })
  maxConcurrentRequests: number;

  @Column({ name: 'dailyQuota', default: 1000 })
  dailyQuota: number;

  @Column({ name: 'dailyUsage', default: 0 })
  dailyUsage: number;

  @Column({ name: 'expiresAt', type: 'date', nullable: true })
  expiresAt: Date;

  @Column({ name: 'isDefault', default: false })
  isDefault: boolean;

  @Column({ name: 'lastUsedAt', nullable: true })
  lastUsedAt: Date;

  @Column({ name: 'lastHealthCheckAt', nullable: true })
  lastHealthCheckAt: Date;

  @Column({ name: 'lastHealthCheckStatus', nullable: true })
  lastHealthCheckStatus: string;

  @Column({ name: 'allowedIpRanges', nullable: true })
  allowedIpRanges: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
