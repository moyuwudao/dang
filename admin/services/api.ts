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

// 请求拦截器：添加 Token
axiosInstance.interceptors.request.use((config) => {
  if (typeof window !== 'undefined') {
    const token = localStorage.getItem('accessToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
  }
  return config;
});

// Token 刷新状态
let isRefreshing = false;
let refreshSubscribers: Array<(token: string) => void> = [];

function subscribeTokenRefresh(callback: (token: string) => void) {
  refreshSubscribers.push(callback);
}

function onTokenRefreshed(newToken: string) {
  refreshSubscribers.forEach((callback) => callback(newToken));
  refreshSubscribers = [];
}

// 跳转到登录页
function redirectToLogin() {
  if (typeof window !== 'undefined') {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    window.location.href = '/login';
  }
}

// 响应拦截器：处理 401 和 Token 刷新
axiosInstance.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    // 如果不是 401，直接抛出错误
    if (error.response?.status !== 401) {
      return Promise.reject(error);
    }

    // 如果是登录/注册/刷新接口本身，直接抛出错误
    const url = originalRequest?.url || '';
    if (url.includes('/auth/login') || url.includes('/auth/register') || url.includes('/auth/refresh')) {
      return Promise.reject(error);
    }

    // 如果已经重试过，直接跳转登录
    if (originalRequest._retry) {
      redirectToLogin();
      return Promise.reject(error);
    }

    // 如果正在刷新，等待刷新完成
    if (isRefreshing) {
      return new Promise((resolve, reject) => {
        subscribeTokenRefresh((newToken: string) => {
          originalRequest.headers.Authorization = `Bearer ${newToken}`;
          resolve(axiosInstance(originalRequest));
        });
        setTimeout(() => {
          reject(new Error('Token refresh timeout'));
        }, 10000);
      });
    }

    originalRequest._retry = true;
    isRefreshing = true;

    try {
      const refreshToken = typeof window !== 'undefined' ? localStorage.getItem('refreshToken') : null;
      if (!refreshToken) {
        throw new Error('No refresh token');
      }

      // 使用独立的 axios 实例调用刷新接口（避免拦截器循环）
      const response = await axios.post(`${API_URL}/auth/refresh`, {
        refreshToken,
      });

      const { accessToken, refreshToken: newRefreshToken } = response.data.data;

      // 更新存储
      localStorage.setItem('accessToken', accessToken);
      localStorage.setItem('refreshToken', newRefreshToken);

      // 通知其他等待的请求
      onTokenRefreshed(accessToken);

      // 重试原始请求
      originalRequest.headers.Authorization = `Bearer ${accessToken}`;
      return axiosInstance(originalRequest);
    } catch (refreshError) {
      redirectToLogin();
      return Promise.reject(refreshError);
    } finally {
      isRefreshing = false;
    }
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
  
  subscribe: async (planId: string, userId?: string): Promise<Subscription> => {
    const response = await axiosInstance.post<ApiResponse<Subscription>>(
      '/subscription/subscribe',
      { planId, userId }
    );
    return response.data.data;
  },
  
  unsubscribe: async (userId?: string): Promise<void> => {
    await axiosInstance.post('/subscription/unsubscribe', { userId });
  },
  
  recharge: async (amount: number, paymentMethod: string): Promise<void> => {
    await axiosInstance.post('/subscription/recharge', {
      amount,
      paymentMethod,
    });
  },
  
  getRechargeRecords: async (page = 1, limit = 20): Promise<PaginatedResponse<RechargeRecord>> => {
    const response = await axiosInstance.get<ApiResponse<PaginatedResponse<RechargeRecord>>>(
      `/subscription/recharge-records?page=${page}&limit=${limit}`
    );
    return response.data.data;
  },
  
  getBalance: async (): Promise<{ balanceCents: number }> => {
    const response = await axiosInstance.get<ApiResponse<{ balanceCents: number }>>('/subscription/balance');
    return response.data.data;
  },

  getPlanApiPolicies: async (planId: string): Promise<any> => {
    const response = await axiosInstance.get<ApiResponse<any>>(`/subscription/plans/${planId}/policies`);
    return response.data.data;
  },

  updatePlanApiPolicy: async (planId: string, model: string, data: any): Promise<any> => {
    const response = await axiosInstance.post<ApiResponse<any>>(`/subscription/plans/${planId}/policies`, data);
    return response.data.data;
  },

  deletePlanApiPolicy: async (planId: string, policyId: string): Promise<void> => {
    await axiosInstance.delete(`/subscription/plans/${planId}/policies/${policyId}`);
  },
};

export const apiKeyAPI = {
  getApiKeys: async (): Promise<ApiKey[]> => {
    const response = await axiosInstance.get<ApiResponse<ApiKey[]>>('/api-key/admin/list');
    return response.data.data;
  },
  
  getApiKeyStats: async (): Promise<any> => {
    const response = await axiosInstance.get<ApiResponse<any>>('/api-key/admin/stats');
    return response.data.data;
  },
  
  createApiKey: async (data: Partial<ApiKey>): Promise<ApiKey> => {
    const response = await axiosInstance.post<ApiResponse<ApiKey>>('/api-key/admin/create', data);
    return response.data.data;
  },
  
  updateApiKey: async (id: string, data: Partial<ApiKey>): Promise<ApiKey> => {
    const response = await axiosInstance.put<ApiResponse<ApiKey>>(`/api-key/admin/${id}`, data);
    return response.data.data;
  },
  
  deleteApiKey: async (id: string): Promise<void> => {
    await axiosInstance.delete(`/api-key/admin/${id}`);
  },
  
  testApiKey: async (id: string): Promise<any> => {
    const response = await axiosInstance.post<ApiResponse<any>>(`/api-key/admin/${id}/test`);
    return response.data.data;
  },

  batchCreateApiKeys: async (keys: Partial<ApiKey>[]): Promise<any[]> => {
    const response = await axiosInstance.post<ApiResponse<any[]>>(`/api-key/admin/batch`, keys);
    return response.data.data;
  },

  getHealthyModels: async (): Promise<any[]> => {
    const response = await axiosInstance.get<ApiResponse<any[]>>(`/api-key/admin/healthy-models`);
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
  
  getLogs: async (service: string, lines = 100): Promise<string> => {
    const response = await axiosInstance.post<ApiResponse<string>>('/monitor/logs', {
      service,
      lines,
    });
    return response.data.data;
  },
  
  executeCommand: async (command: string, timeout = 30): Promise<{ output: string }> => {
    const response = await axiosInstance.post<ApiResponse<{ output: string }>>('/monitor/execute', { command, timeout });
    return response.data.data;
  },

  getRealtimeMetrics: async (): Promise<any> => {
    const response = await axiosInstance.get<ApiResponse<any>>('/monitor/metrics/realtime');
    return response.data;
  },

  getDailyMetrics: async (date?: string): Promise<any> => {
    const response = await axiosInstance.get<ApiResponse<any>>('/monitor/metrics/daily', {
      params: { date },
    });
    return response.data;
  },

  getTrendData: async (days = 7): Promise<any> => {
    const response = await axiosInstance.get<ApiResponse<any>>('/monitor/metrics/trend', {
      params: { days },
    });
    return response.data;
  },
};

export const paymentAPI = {
  createRechargeOrder: async (params: { amount: number; paymentMethod: string }): Promise<ApiResponse<any>> => {
    const response = await axiosInstance.post<ApiResponse<any>>('/payment/recharge', params);
    return response.data;
  },

  getOrderStatus: async (orderId: string): Promise<ApiResponse<any>> => {
    const response = await axiosInstance.get<ApiResponse<any>>(`/payment/order/${orderId}`);
    return response.data;
  },

  getRechargeRecords: async (page = 1, limit = 20): Promise<ApiResponse<any>> => {
    const response = await axiosInstance.get<ApiResponse<any>>('/payment/records', {
      params: { page, limit },
    });
    return response.data;
  },
};

export const adminAPI = {
  getStats: async (): Promise<any> => {
    const response = await axiosInstance.get<ApiResponse<any>>('/admin/stats');
    return response.data;
  },

  getUsers: async (page = 1, limit = 20, search?: string): Promise<any> => {
    const response = await axiosInstance.get<ApiResponse<any>>('/admin/users', {
      params: { page, limit, search },
    });
    return response.data.data;
  },

  getUserById: async (id: string): Promise<any> => {
    const response = await axiosInstance.get<ApiResponse<any>>(`/admin/users/${id}`);
    return response.data.data;
  },

  updateUser: async (id: string, data: any): Promise<any> => {
    const response = await axiosInstance.put<ApiResponse<any>>(`/admin/users/${id}`, data);
    return response.data.data;
  },

  deleteUser: async (id: string): Promise<void> => {
    await axiosInstance.delete(`/admin/users/${id}`);
  },

  createUser: async (data: any): Promise<any> => {
    const response = await axiosInstance.post<ApiResponse<any>>('/admin/users', data);
    return response.data.data;
  },

  getPlans: async (): Promise<Plan[]> => {
    const response = await axiosInstance.get<ApiResponse<Plan[]>>('/admin/plans');
    return response.data.data;
  },

  createPlan: async (plan: any): Promise<any> => {
    const response = await axiosInstance.post<ApiResponse<any>>('/admin/plans', plan);
    return response.data.data;
  },

  updatePlan: async (id: string, plan: any): Promise<any> => {
    const response = await axiosInstance.put<ApiResponse<any>>(`/admin/plans/${id}`, plan);
    return response.data.data;
  },

  deletePlan: async (id: string): Promise<void> => {
    await axiosInstance.delete(`/admin/plans/${id}`);
  },

  getSubscriptions: async (page = 1, limit = 20): Promise<any> => {
    const response = await axiosInstance.get<ApiResponse<any>>('/admin/subscriptions', {
      params: { page, limit },
    });
    return response.data.data;
  },

  updateSubscription: async (id: string, data: any): Promise<any> => {
    const response = await axiosInstance.put<ApiResponse<any>>(`/admin/subscriptions/${id}`, data);
    return response.data.data;
  },

  getRechargeRecords: async (page = 1, limit = 20): Promise<any> => {
    const response = await axiosInstance.get<ApiResponse<any>>('/admin/recharge-records', {
      params: { page, limit },
    });
    return response.data.data;
  },

  getRevenueTrend: async (days = 7): Promise<ChartDataPoint[]> => {
    const response = await axiosInstance.get<ApiResponse<ChartDataPoint[]>>('/admin/charts/revenue-trend', {
      params: { days },
    });
    return response.data.data;
  },

  getUserGrowth: async (days = 7): Promise<ChartDataPoint[]> => {
    const response = await axiosInstance.get<ApiResponse<ChartDataPoint[]>>('/admin/charts/user-growth', {
      params: { days },
    });
    return response.data.data;
  },

  getRevenueStats: async (startDate?: string, endDate?: string): Promise<any> => {
    const response = await axiosInstance.get<ApiResponse<any>>('/admin/revenue-stats', {
      params: { startDate, endDate },
    });
    return response.data.data;
  },

  getApiUsageLogs: async (page = 1, limit = 20, userId?: string, provider?: string): Promise<any> => {
    const response = await axiosInstance.get<ApiResponse<any>>('/admin/api-usage-logs', {
      params: { page, limit, userId, provider },
    });
    return response.data.data;
  },

  adjustUserQuota: async (userId: string, amount: number, reason?: string): Promise<any> => {
    const response = await axiosInstance.post<ApiResponse<any>>(`/admin/users/${userId}/adjust-quota`, {
      amount,
      reason,
    });
    return response.data.data;
  },

  assignPlanToUser: async (userId: string, planId: string): Promise<any> => {
    const response = await axiosInstance.post<ApiResponse<any>>(`/admin/users/${userId}/subscribe`, {
      planId,
    });
    return response.data.data;
  },
};

export default axiosInstance;
