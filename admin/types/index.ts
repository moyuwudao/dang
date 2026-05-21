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

export interface ApiKey {
  id: string;
  provider: string;
  model: string;
  isActive: boolean;
  rateLimitPerMin: number;
  createdAt: string;
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
