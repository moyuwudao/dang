import axios from 'axios';
import type { 
  User, 
  Plan, 
  Subscription, 
  ApiKey, 
  LoginResponse,
  ApiResponse,
  DashboardStats,
  ChartDataPoint
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
    const response = await axiosInstance.get<ApiResponse<User>>('/auth/profile');
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
  getUsers: async (): Promise<User[]> => {
    const response = await axiosInstance.get<ApiResponse<User[]>>('/auth/users');
    return response.data.data;
  },
  
  getStats: async (): Promise<DashboardStats> => {
    const response = await axiosInstance.get<ApiResponse<DashboardStats>>('/admin/stats');
    return response.data.data;
  },
  
  getUserSubscriptions: async (): Promise<{ userId: string; phone: string; planId: string; planName: string; status: string; expiresAt: string | null; totalQuota: number; usedQuota: number; remainingQuota: number }[]> => {
    const response = await axiosInstance.get<ApiResponse<{ userId: string; phone: string; planId: string; planName: string; status: string; expiresAt: string | null; totalQuota: number; usedQuota: number; remainingQuota: number }[]>>(
      '/admin/subscriptions'
    );
    return response.data.data;
  },
  
  getActivityLog: async (): Promise<ChartDataPoint[]> => {
    const response = await axiosInstance.get<ApiResponse<ChartDataPoint[]>>('/admin/activity');
    return response.data.data;
  },
};

export default axiosInstance;
