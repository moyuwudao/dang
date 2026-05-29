export interface User {
  id: string;
  phone: string;
  email?: string;
  nickname?: string;
  status: string;
  role: string;
  createdAt: string;
  subscriptionCount?: number;
  balance?: number;
}

export interface PlanFeatureQuota {
  id: string;
  planId: string;
  featureType: string;
  quotaValue: number;
  quotaUnit: string;
  multiplier: number;
}

export interface Plan {
  id: string;
  name: string;
  description?: string;
  priceCents: number;
  durationDays: number;
  quotaType: string;
  quotaValue?: number;
  isActive: boolean;
  type?: string;
  features?: string[];
  isRecommended?: boolean;
  allowedModels?: string[];
  featureQuotas?: PlanFeatureQuota[];
}

export interface Subscription {
  id: string;
  userId: string;
  userPhone?: string;
  userNickname?: string;
  planId: string;
  planName?: string;
  status: string;
  startedAt: string;
  expiresAt: string;
  totalQuota: number;
  usedQuota: number;
  createdAt: string;
}

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

export interface ApiKey {
  id: string;
  provider: ApiKeyProvider;
  name: string;
  description?: string;
  apiKey?: string;
  apiSecret?: string;
  model: string;
  baseUrl?: string;
  status: ApiKeyStatus;
  scopes?: ApiKeyScope[];
  rateLimitPerMin: number;
  maxConcurrentRequests: number;
  dailyQuota: number;
  dailyUsage: number;
  expiresAt?: string;
  isDefault: boolean;
  lastUsedAt?: string;
  lastHealthCheckAt?: string;
  lastHealthCheckStatus?: string;
  createdAt: string;
  updatedAt: string;
}

export interface ApiKeyStats {
  total: number;
  active: number;
  inactive: number;
  expired: number;
  providers: { provider: string; count: number }[];
}

export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  totalPages: number;
}

export interface LoginResponse {
  accessToken: string;
  refreshToken: string;
}

export interface DashboardStats {
  totalUsers: number;
  activeSubscriptions: number;
  apiKeyCount: number;
  totalRevenue: number;
}

export interface ChartDataPoint {
  date: string;
  value: number;
}

export interface RechargeRecord {
  id: string;
  userId: string;
  userPhone?: string;
  amountCents: number;
  type: string;
  paymentMethod?: string;
  status: string;
  remark?: string;
  createdAt: string;
}

export interface SystemInfo {
  hostname: string;
  platform: string;
  uptime: number;
  cpu: {
    usage: number;
    cores: number;
    model: string;
  };
  memory: {
    total: number;
    used: number;
    free: number;
    usagePercent: number;
  };
  disk: {
    total: number;
    used: number;
    free: number;
    usagePercent: number;
  };
  load: number[];
  timestamp: string;
}

export interface ServiceStatus {
  name: string;
  status: string;
  active: boolean;
}
