export interface User {
  id: string;
  phone: string;
  createdAt: string;
}

export interface Plan {
  id: string;
  name: string;
  description: string;
  priceCents: number;
  durationDays: number;
  quotaType: string;
  quotaValue: number;
  isActive: boolean;
}

export interface Subscription {
  id: string;
  userId: string;
  planId: string;
  planName: string;
  startDate: string;
  endDate: string;
  status: string;
  totalQuota: number;
  usedQuota: number;
}

export interface UserSubscription extends Subscription {
  userId: string;
  phone: string;
}

export interface ApiKey {
  id: string;
  provider: string;
  model: string;
  isActive: boolean;
  rateLimitPerMin: number;
  createdAt: string;
}

export interface UserApiKey {
  provider: string;
  apiKey: string;
  model: string;
  rateLimitPerMin: number;
  expiresAt: string;
}

export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}

export interface LoginResponse {
  accessToken: string;
  refreshToken: string;
}

export interface DashboardStats {
  totalUsers: number;
  activeSubscriptions: number;
  apiKeyCount: number;
  totalQuotaUsed: number;
}

export interface ChartDataPoint {
  date: string;
  value: number;
}
