import axios from 'axios';
import Router from 'next/router';
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

// Token 刷新状态
let isRefreshing = false;
let refreshSubscribers: ((token: string) => void)[] = [];
let isRedirecting = false;

// 订阅 Token 刷新
function subscribeTokenRefresh(callback: (token: string) => void) {
  refreshSubscribers.push(callback);
}

// 通知所有订阅者
function onTokenRefreshed(newToken: string) {
  refreshSubscribers.forEach((callback) => callback(newToken));
  refreshSubscribers = [];
}

// 跳转到登录页（避免重复跳转）
function redirectToLogin() {
  if (isRedirecting) return;
  isRedirecting = true;
  
  localStorage.removeItem('accessToken');
  localStorage.removeItem('refreshToken');
  
  if (typeof window !== 'undefined' && window.location.pathname !== '/login') {
    // 使用 window.location 替代 Router.push，确保页面完全刷新
    window.location.href = '/login';
  }
  
  // 重置标志（3秒后）
  setTimeout(() => {
    isRedirecting = false;
  }, 3000);
}

axiosInstance.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    // 如果是 401 且不是刷新请求本身
    if (error.response?.status === 401 && !originalRequest._retry) {
      // 如果是登录/注册/刷新接口本身，直接抛出错误
      const url = originalRequest.url || '';
      if (url.includes('/auth/login') || url.includes('/auth/register') || url.includes('/auth/refresh')) {
        return Promise.reject(error);
      }

      if (isRefreshing) {
        // 等待刷新完成
        return new Promise((resolve, reject) => {
          subscribeTokenRefresh((newToken: string) => {
            originalRequest.headers.Authorization = `Bearer ${newToken}`;
            resolve(axiosInstance(originalRequest));
          });
          // 超时处理
          setTimeout(() => {
            reject(new Error('Token refresh timeout'));
          }, 10000);
        });
      }

      originalRequest._retry = true;
      isRefreshing = true;

      try {
        const refreshToken = localStorage.getItem('refreshToken');
        if (!refreshToken) {
          throw new Error('No refresh token');
        }

        // 调用刷新接口
        const response = await axios.post(`${API_URL}/auth/refresh`, {
          refreshToken,
        });

        const { accessToken, refreshToken: newRefreshToken } = response.data.data;

        // 更新存储
        localStorage.setItem('accessToken', accessToken);
        localStorage.setItem('refreshToken', newRefreshToken);

        // 更新原始请求
        originalRequest.headers.Authorization = `Bearer ${accessToken}`;

        // 通知其他等待的请求
        onTokenRefreshed(accessToken);

        return axiosInstance(originalRequest);
      } catch (refreshError) {
        // 刷新失败，清除 Token 并跳转登录
        redirectToLogin();
        return Promise.reject(refreshError);
      } finally {
        isRefreshing = false;
      }
    }

    return Promise.reject(error);
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
    const response = await axiosInstance.put<ApiResponse<any>>(`/subscription/plans/${planId}/policies/${model}`, data);
    return response.data.data;
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

// 管理后台 API
export const adminAPI = {
  getStats: async (): Promise<any> => {
    const response = await axiosInstance.get<ApiResponse<any>>('/admin/stats');
    return response.data;
  },

  getUsers: async (page = 1, limit = 20, search?: string): Promise<any> => {
    const response = await axiosInstance.get<ApiResponse<any>>('/admin/users', {
      params: { page, limit, search },
    });
    return response.data;
  },

  getUserById: async (id: string): Promise<any> => {
    const response = await axiosInstance.get<ApiResponse<any>>(`/admin/users/${id}`);
    return response.data;
  },

  updateUser: async (id: string, data: any): Promise<any> => {
    const response = await axiosInstance.put<ApiResponse<any>>(`/admin/users/${id}`, data);
    return response.data;
  },

  deleteUser: async (id: string): Promise<void> => {
    await axiosInstance.delete(`/admin/users/${id}`);
  },

  getPlans: async (): Promise<Plan[]> => {
    const response = await axiosInstance.get<ApiResponse<Plan[]>>('/admin/plans');
    return response.data.data;
  },

  createPlan: async (plan: any): Promise<any> => {
    const response = await axiosInstance.post<ApiResponse<any>>('/admin/plans', plan);
    return response.data;
  },

  updatePlan: async (id: string, plan: any): Promise<any> => {
    const response = await axiosInstance.put<ApiResponse<any>>(`/admin/plans/${id}`, plan);
    return response.data;
  },

  deletePlan: async (id: string): Promise<void> => {
    await axiosInstance.delete(`/admin/plans/${id}`);
  },

  getSubscriptions: async (page = 1, limit = 20): Promise<any> => {
    const response = await axiosInstance.get<ApiResponse<any>>('/admin/subscriptions', {
      params: { page, limit },
    });
    return response.data;
  },

  getRechargeRecords: async (page = 1, limit = 20): Promise<any> => {
    const response = await axiosInstance.get<ApiResponse<any>>('/admin/recharge-records', {
      params: { page, limit },
    });
    return response.data;
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

  getRevenueStats: async (startDate?: string, endDate?: string): Promise<any> => {
    const response = await axiosInstance.get<ApiResponse<any>>('/admin/revenue-stats', {
      params: { startDate, endDate },
    });
    return response.data;
  },

  getApiUsageLogs: async (page = 1, limit = 20, userId?: string, provider?: string): Promise<any> => {
    const response = await axiosInstance.get<ApiResponse<any>>('/admin/api-usage-logs', {
      params: { page, limit, userId, provider },
    });
    return response.data;
  },

  adjustUserQuota: async (userId: string, amount: number, reason?: string): Promise<any> => {
    const response = await axiosInstance.post<ApiResponse<any>>(`/admin/users/${userId}/adjust-quota`, {
      amount,
      reason,
    });
    return response.data;
  },
};

export default axiosInstance;
