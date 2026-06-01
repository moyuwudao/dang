import axios from 'axios';

const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

const api = axios.create({
  baseURL: API_BASE,
  timeout: 10000,
});

// 请求拦截器 - 添加token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('accessToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// 响应拦截器 - 统一提取 data 字段
api.interceptors.response.use(
  (response) => {
    if (response.data && response.data.code === 200 && 'data' in response.data) {
      return { ...response, data: response.data.data };
    }
    return response;
  },
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('accessToken');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export const adminAPI = {
  // 仪表板统计
  getStats: () => api.get('/admin/stats').then(r => r.data),

  // 用户管理
  getUsers: (page?: number, pageSize?: number, search?: string) => api.get('/admin/users', { params: { page, pageSize, search } }).then(r => r.data),
  getUserById: (id: string) => api.get(`/admin/users/${id}`).then(r => r.data),
  createUser: (data: any) => api.post('/admin/users', data).then(r => r.data),
  updateUser: (id: string, data: any) => api.put(`/admin/users/${id}`, data).then(r => r.data),
  deleteUser: (id: string) => api.delete(`/admin/users/${id}`).then(r => r.data),
  assignPlanToUser: (userId: string, planId: string) => api.post(`/admin/users/${userId}/subscribe`, { planId }).then(r => r.data),
  adjustUserQuota: (userId: string, data: any) => api.post(`/admin/users/${userId}/adjust-quota`, data).then(r => r.data),

  // 套餐管理
  getPlans: () => api.get('/admin/plans').then(r => r.data),
  getPlanById: (id: string) => api.get(`/admin/plans/${id}`).then(r => r.data),
  createPlan: (data: any) => api.post('/admin/plans', data).then(r => r.data),
  updatePlan: (id: string, data: any) => api.put(`/admin/plans/${id}`, data).then(r => r.data),
  deletePlan: (id: string) => api.delete(`/admin/plans/${id}`).then(r => r.data),

  // 订阅管理
  getSubscriptions: (page?: number, pageSize?: number) => api.get('/admin/subscriptions', { params: { page, pageSize } }).then(r => r.data),
  updateSubscription: (id: string, data: any) => api.put(`/admin/subscriptions/${id}`, data).then(r => r.data),

  // 图表数据
  getUserGrowth: (days?: number) => api.get('/admin/charts/user-growth', { params: { days } }).then(r => r.data),
  getRevenueTrend: (days?: number) => api.get('/admin/charts/revenue-trend', { params: { days } }).then(r => r.data),

  // 收入统计
  getRevenueStats: (startDate?: string, endDate?: string) => api.get('/admin/revenue-stats', { params: { startDate, endDate } }).then(r => r.data),
  getRechargeRecords: (page?: number, pageSize?: number) => api.get('/admin/recharge-records', { params: { page, pageSize } }).then(r => r.data),

  // API使用日志
  getApiUsageLogs: (params?: any) => api.get('/admin/api-usage-logs', { params }).then(r => r.data),

  // 计费标准
  getBillingStandards: () => api.get('/admin/billing-standards').then(r => r.data),
  createBillingStandard: (data: any) => api.post('/admin/billing-standards', data).then(r => r.data),
  updateBillingStandard: (id: string, data: any) => api.put(`/admin/billing-standards/${id}`, data).then(r => r.data),
  deleteBillingStandard: (id: string) => api.delete(`/admin/billing-standards/${id}`).then(r => r.data),

  // 模型价格
  getTokenPricing: () => api.get('/admin/token-pricing').then(r => r.data),
  createTokenPricing: (data: any) => api.post('/admin/token-pricing', data).then(r => r.data),
  updateTokenPricing: (id: string, data: any) => api.put(`/admin/token-pricing/${id}`, data).then(r => r.data),
  deleteTokenPricing: (id: string) => api.delete(`/admin/token-pricing/${id}`).then(r => r.data),

  // API策略
  getApiPolicies: () => api.get('/admin/api-policies').then(r => r.data),
  createApiPolicy: (data: any) => api.post('/admin/api-policies', data).then(r => r.data),
  updateApiPolicy: (id: string, data: any) => api.put(`/admin/api-policies/${id}`, data).then(r => r.data),
  deleteApiPolicy: (id: string) => api.delete(`/admin/api-policies/${id}`).then(r => r.data),
};

export const apiKeyAPI = {
  getApiKeys: () => api.get('/admin/api-keys').then(r => r.data),
  getApiKeyStats: () => api.get('/admin/api-keys/stats').then(r => r.data),
  createApiKey: (data: any) => api.post('/admin/api-keys', data).then(r => r.data),
  batchCreateApiKeys: (keys: any[]) => api.post('/admin/api-keys/batch', { keys }).then(r => r.data),
  testApiKey: (id: string) => api.post(`/admin/api-keys/${id}/test`).then(r => r.data),
  updateApiKey: (id: string, data: any) => api.put(`/admin/api-keys/${id}`, data).then(r => r.data),
  deleteApiKey: (id: string) => api.delete(`/admin/api-keys/${id}`).then(r => r.data),
};

export const authAPI = {
  login: (phone: string, password: string) => api.post('/auth/login', { phone, password }).then(r => r.data),
};

export const monitorAPI = {
  getRealtimeMetrics: () => api.get('/admin/monitor/realtime').then(r => r.data),
  getTrendData: () => api.get('/admin/monitor/trend').then(r => r.data),
  getSystemInfo: () => api.get('/admin/monitor/system-info').then(r => r.data),
  getServices: () => api.get('/admin/monitor/services').then(r => r.data),
  getLogs: (service: string, lines: number) => api.get('/admin/monitor/logs', { params: { service, lines } }).then(r => r.data),
  executeCommand: (command: string, timeout?: number) => api.post('/admin/monitor/execute', { command, timeout }).then(r => r.data),
};

export default api;
