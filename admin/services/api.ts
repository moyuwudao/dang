import axios from 'axios';
import type { 
  User, 
  Plan, 
  Subscription, 
  ApiKey, 
  LoginResponse,
  ApiResponse,
  DashboardStats,
  ChartDataPoint,
  PaginatedResponse,
  RechargeRecord,
  SystemInfo,
  ServiceStatus,
} from '@/types';

const API_URL = process.env.API_URL || 'http://101.133.238.249/api/v1';

const axiosInstance = axios.create({
  baseURL: API_URL,
});

axiosInstance.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

axiosInstance.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('accessToken');
      window.location.href = '/login';
    }
    throw error;
  }
);

export const authAPI = {
  login: async (phone: string, password: string): Promise<LoginResponse> => {
    const response = await axiosInstance.post<ApiResponse<LoginResponse>>(
      '/auth/login',
      { phone, password }
    );
    return response.data.data;
  },
  
  register: async (phone: string, password: string, smsCode: string): Promise<LoginResponse> => {
    const response = await axiosInstance.post<ApiResponse<LoginResponse>>(
      '/auth/register',
      { phone, password, smsCode }
    );
    return response.data.data;
  },
  
  getProfile: async (): Promise<User> => {
    const response = await axiosInstance.get<ApiResponse<User>>('/auth/me');
    return response.data.data;
  },
};

export const subscriptionAPI = {
  getPlans: async (): Promise<Plan[]> => {
    const response = await axiosInstance.get<ApiResponse<Plan[]>>('/subscription/plans');
    return response.data.data;
  },
  
  createPlan: async (plan: Omit<Plan, 'id'> & { id: string }): Promise<Plan> => {
    const response = await axiosInstance.post<ApiResponse<Plan>>(
      '/subscription/plans',
      plan
    );
    return response.data.data;
  },
  
  getSubscription: async (userId?: string): Promise<Subscription> => {
    const response = await axiosInstance.get<ApiResponse<Subscription>>(
      userId ? `/subscription/${userId}` : '/subscription'
    );
    return response.data.data;
  },
  
  useQuota: async (amount: number): Promise<{ usedQuota: number; remainingQuota: number }> => {
    const response = await axiosInstance.post<ApiResponse<{ usedQuota: number; remainingQuota: number }>>(
      '/subscription/quota/use',
      { amount }
    );
    return response.data.data;
  },
};

export const apiKeyAPI = {
  getApiKeys: async (): Promise<ApiKey[]> => {
    const response = await axiosInstance.get<ApiResponse<ApiKey[]>>('/api-key/admin/list');
    return response.data.data;
  },
  
  createApiKey: async (data: { provider: string; apiKey: string; model: string; rateLimitPerMin?: number }): Promise<ApiKey> => {
    const response = await axiosInstance.post<ApiResponse<ApiKey>>(
      '/api-key/admin/create',
      data
    );
    return response.data.data;
  },
  
  deleteApiKey: async (id: string): Promise<void> => {
    await axiosInstance.delete(`/api-key/admin/${id}`);
  },
  
  getMyApiKey: async (): Promise<{ provider: string; apiKey: string; model: string; rateLimitPerMin: number; expiresAt: string }> => {
    const response = await axiosInstance.get<ApiResponse<{ provider: string; apiKey: string; model: string; rateLimitPerMin: number; expiresAt: string }>>(
      '/api-key'
    );
    return response.data.data;
  },
};

export const adminAPI = {
  getStats: async (): Promise<DashboardStats> => {
    const response = await axiosInstance.get<ApiResponse<DashboardStats>>('/admin/stats');
    return response.data.data;
  },
  
  getUsers: async (page = 1, limit = 20, search?: string): Promise<PaginatedResponse<User>> => {
    const response = await axiosInstance.get<ApiResponse<PaginatedResponse<User>>>('/admin/users', {
      params: { page, limit, search },
    });
    return response.data.data;
  },
  
  updateUser: async (id: string, data: Partial<User>): Promise<User> => {
    const response = await axiosInstance.put<ApiResponse<User>>(`/admin/users/${id}`, data);
    return response.data.data;
  },
  
  deleteUser: async (id: string): Promise<void> => {
    await axiosInstance.delete(`/admin/users/${id}`);
  },
  
  getPlans: async (): Promise<Plan[]> => {
    const response = await axiosInstance.get<ApiResponse<Plan[]>>('/admin/plans');
    return response.data.data;
  },
  
  createPlan: async (plan: Partial<Plan>): Promise<Plan> => {
    const response = await axiosInstance.post<ApiResponse<Plan>>('/admin/plans', plan);
    return response.data.data;
  },
  
  updatePlan: async (id: string, data: Partial<Plan>): Promise<Plan> => {
    const response = await axiosInstance.put<ApiResponse<Plan>>(`/admin/plans/${id}`, data);
    return response.data.data;
  },
  
  deletePlan: async (id: string): Promise<void> => {
    await axiosInstance.delete(`/admin/plans/${id}`);
  },
  
  getSubscriptions: async (page = 1, limit = 20, status?: string): Promise<PaginatedResponse<Subscription>> => {
    const response = await axiosInstance.get<ApiResponse<PaginatedResponse<Subscription>>>('/admin/subscriptions', {
      params: { page, limit, status },
    });
    return response.data.data;
  },
  
  updateSubscription: async (id: string, data: Partial<Subscription>): Promise<Subscription> => {
    const response = await axiosInstance.put<ApiResponse<Subscription>>(`/admin/subscriptions/${id}`, data);
    return response.data.data;
  },
  
  getRechargeRecords: async (page = 1, limit = 20): Promise<PaginatedResponse<RechargeRecord>> => {
    const response = await axiosInstance.get<ApiResponse<PaginatedResponse<RechargeRecord>>>('/admin/recharge-records', {
      params: { page, limit },
    });
    return response.data.data;
  },
  
  getUserGrowth: async (days = 7): Promise<ChartDataPoint[]> => {
    const response = await axiosInstance.get<ApiResponse<ChartDataPoint[]>>('/admin/charts/user-growth', {
      params: { days },
    });
    return response.data.data;
  },
  
  getRevenueTrend: async (days = 7): Promise<ChartDataPoint[]> => {
    const response = await axiosInstance.get<ApiResponse<ChartDataPoint[]>>('/admin/charts/revenue-trend', {
      params: { days },
    });
    return response.data.data;
  },
};

export const monitorAPI = {
  getSystemInfo: async (): Promise<SystemInfo> => {
    const response = await axiosInstance.get<ApiResponse<SystemInfo>>('/monitor/system');
    return response.data.data;
  },
  
  getServices: async (): Promise<ServiceStatus[]> => {
    const response = await axiosInstance.get<ApiResponse<ServiceStatus[]>>('/monitor/services');
    return response.data.data;
  },
  
  getLogs: async (service: string, lines = 100): Promise<{ logs: string }> => {
    const response = await axiosInstance.post<ApiResponse<{ logs: string }>>('/monitor/logs', { service, lines });
    return response.data.data;
  },
  
  executeCommand: async (command: string, timeout = 30): Promise<{ output: string }> => {
    const response = await axiosInstance.post<ApiResponse<{ output: string }>>('/monitor/execute', { command, timeout });
    return response.data.data;
  },
};

export default axiosInstance;
