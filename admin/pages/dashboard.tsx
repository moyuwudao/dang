'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import { Card, CardBody, Button, Badge, Spinner } from '@nextui-org/react';
import { Users, CreditCard, Key, TrendingUp, Activity, ArrowUpRight, Server } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar } from 'recharts';
import Layout from '@/components/Layout';
import { adminAPI, apiKeyAPI, monitorAPI } from '@/services/api';
import type { DashboardStats, Plan, ApiKey, ChartDataPoint } from '@/types';
import { ApiKeyStatus } from '@/types';

const StatCard = ({ icon: Icon, title, value, change, changeType, loading }: { icon: React.ElementType, title: string, value: string | number, change?: string, changeType?: 'up' | 'down', loading?: boolean }) => (
  <Card className="bg-white border border-gray-100 hover:shadow-sm transition-shadow duration-200">
    <CardBody className="p-5">
      <div className="flex items-start justify-between">
        <div className="space-y-2">
          <p className="text-sm text-gray-500 font-medium">{title}</p>
          {loading ? (
            <Spinner size="sm" color="primary" />
          ) : (
            <p className="text-2xl font-semibold text-gray-900">{value}</p>
          )}
          {change && (
            <div className={`flex items-center gap-1 ${changeType === 'up' ? 'text-green-600' : 'text-red-500'}`}>
              <ArrowUpRight className="w-4 h-4" />
              <span className="text-sm font-medium">{change}</span>
            </div>
          )}
        </div>
        <div className="w-12 h-12 rounded-lg bg-blue-50 flex items-center justify-center">
          <Icon className="w-6 h-6 text-blue-600" />
        </div>
      </div>
    </CardBody>
  </Card>
);

export default function DashboardPage() {
  const router = useRouter();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [plans, setPlans] = useState<Plan[]>([]);
  const [apiKeys, setApiKeys] = useState<ApiKey[]>([]);
  const [userGrowth, setUserGrowth] = useState<ChartDataPoint[]>([]);
  const [revenueTrend, setRevenueTrend] = useState<ChartDataPoint[]>([]);
  const [systemInfo, setSystemInfo] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      const [statsRes, plansRes, keysRes, growthRes, revenueRes, systemRes] = await Promise.all([
        adminAPI.getStats(),
        adminAPI.getPlans(),
        apiKeyAPI.getApiKeys(),
        adminAPI.getUserGrowth(7),
        adminAPI.getRevenueTrend(7),
        monitorAPI.getSystemInfo().catch(() => null),
      ]);

      setStats(statsRes);
      setPlans(plansRes);
      setApiKeys(keysRes);
      setUserGrowth(growthRes);
      setRevenueTrend(revenueRes);
      setSystemInfo(systemRes);
    } catch (err: any) {
      setError(err.response?.data?.message || '加载数据失败');
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return `${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
  };

  const chartData = userGrowth.map(d => ({
    date: formatDate(d.date),
    users: d.value,
    revenue: revenueTrend.find(r => formatDate(r.date) === formatDate(d.date))?.value || 0,
  }));

  return (
    <Layout currentPage="dashboard">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-semibold text-gray-900">仪表板</h1>
            <p className="text-sm text-gray-500 mt-1">欢迎回来，查看系统概览</p>
          </div>
          <div className="flex items-center gap-3">
            <Button size="sm" variant="light" onClick={fetchData} isLoading={loading}>
              刷新
            </Button>
            <Badge variant="flat" className="bg-green-50 text-green-700 border-green-200 px-3 py-1.5">
              <Activity className="w-3.5 h-3.5 mr-1.5" />
              系统运行正常
            </Badge>
          </div>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
            {error}
          </div>
        )}

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard
            icon={Users}
            title="总用户数"
            value={stats?.totalUsers?.toLocaleString() || '-'}
            change="+12.5%"
            changeType="up"
            loading={loading && !stats}
          />
          <StatCard
            icon={CreditCard}
            title="活跃订阅"
            value={stats?.activeSubscriptions || '-'}
            change="+8.3%"
            changeType="up"
            loading={loading && !stats}
          />
          <StatCard
            icon={Key}
            title="API Key数量"
            value={stats?.apiKeyCount || '-'}
            change="+2"
            changeType="up"
            loading={loading && !stats}
          />
          <StatCard
            icon={TrendingUp}
            title="累计收入"
            value={stats ? `¥${(stats.totalRevenue / 100).toLocaleString()}` : '-'}
            change="+15.2%"
            changeType="up"
            loading={loading && !stats}
          />
        </div>

        {/* System Info */}
        {systemInfo && (
          <Card className="bg-white border border-gray-100">
            <CardBody className="p-5">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-base font-semibold text-gray-900 flex items-center gap-2">
                  <Server className="w-5 h-5 text-blue-600" />
                  服务器状态
                </h2>
                <Button size="sm" variant="light" className="text-blue-600" onClick={() => router.push('/server-monitor')}>
                  查看详情
                </Button>
              </div>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="bg-gray-50 rounded-lg p-3">
                  <p className="text-xs text-gray-500">CPU 使用率</p>
                  <p className="text-lg font-semibold text-gray-900">{systemInfo.cpu?.usage?.toFixed(1) || '-'}%</p>
                </div>
                <div className="bg-gray-50 rounded-lg p-3">
                  <p className="text-xs text-gray-500">内存使用</p>
                  <p className="text-lg font-semibold text-gray-900">{systemInfo.memory?.usagePercent?.toFixed(1) || '-'}%</p>
                </div>
                <div className="bg-gray-50 rounded-lg p-3">
                  <p className="text-xs text-gray-500">磁盘使用</p>
                  <p className="text-lg font-semibold text-gray-900">{systemInfo.disk?.usagePercent?.toFixed(1) || '-'}%</p>
                </div>
                <div className="bg-gray-50 rounded-lg p-3">
                  <p className="text-xs text-gray-500">运行时间</p>
                  <p className="text-lg font-semibold text-gray-900">{systemInfo.uptime ? `${Math.floor(systemInfo.uptime / 3600)}h` : '-'}</p>
                </div>
              </div>
            </CardBody>
          </Card>
        )}

        {/* Charts */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <Card className="bg-white border border-gray-100">
            <CardBody className="p-5">
              <h2 className="text-base font-semibold text-gray-900 mb-4">用户增长趋势</h2>
              {loading && !userGrowth.length ? (
                <div className="h-[240px] flex items-center justify-center">
                  <Spinner />
                </div>
              ) : (
                <ResponsiveContainer width="100%" height={240}>
                  <LineChart data={chartData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
                    <XAxis dataKey="date" stroke="#9ca3af" tick={{ fontSize: 12 }} />
                    <YAxis stroke="#9ca3af" tick={{ fontSize: 12 }} />
                    <Tooltip 
                      contentStyle={{ 
                        backgroundColor: '#fff', 
                        border: '1px solid #e5e7eb',
                        borderRadius: '8px',
                        padding: '8px 12px'
                      }} 
                    />
                    <Line type="monotone" dataKey="users" stroke="#3b82f6" strokeWidth={2} dot={{ fill: '#3b82f6', strokeWidth: 2, r: 4 }} />
                  </LineChart>
                </ResponsiveContainer>
              )}
            </CardBody>
          </Card>

          <Card className="bg-white border border-gray-100">
            <CardBody className="p-5">
              <h2 className="text-base font-semibold text-gray-900 mb-4">收入趋势</h2>
              {loading && !revenueTrend.length ? (
                <div className="h-[240px] flex items-center justify-center">
                  <Spinner />
                </div>
              ) : (
                <ResponsiveContainer width="100%" height={240}>
                  <BarChart data={chartData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
                    <XAxis dataKey="date" stroke="#9ca3af" tick={{ fontSize: 12 }} />
                    <YAxis stroke="#9ca3af" tick={{ fontSize: 12 }} />
                    <Tooltip 
                      contentStyle={{ 
                        backgroundColor: '#fff', 
                        border: '1px solid #e5e7eb',
                        borderRadius: '8px',
                        padding: '8px 12px'
                      }} 
                    />
                    <Bar dataKey="revenue" fill="#3b82f6" radius={[6, 6, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              )}
            </CardBody>
          </Card>
        </div>

        {/* Bottom Cards */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <Card className="bg-white border border-gray-100">
            <CardBody className="p-5">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-base font-semibold text-gray-900">套餐列表</h2>
                <Button size="sm" variant="light" className="text-blue-600 hover:text-blue-700" onClick={() => router.push('/subscriptions')}>
                  查看全部
                </Button>
              </div>
              <div className="space-y-3">
                {loading && !plans.length ? (
                  <div className="h-20 flex items-center justify-center">
                    <Spinner size="sm" />
                  </div>
                ) : (
                  plans.map((plan) => (
                    <div key={plan.id} className="flex items-center justify-between px-4 py-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                      <div>
                        <p className="font-medium text-gray-900">{plan.name}</p>
                        <p className="text-sm text-gray-500">{plan.description || '-'}</p>
                      </div>
                      <div className="text-right">
                        <p className="font-semibold text-gray-900">¥{(plan.priceCents / 100).toFixed(0)}</p>
                        <Badge variant="flat" className={plan.isActive ? 'bg-green-50 text-green-700' : 'bg-gray-50 text-gray-500'}>
                          {plan.isActive ? '启用' : '停用'}
                        </Badge>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </CardBody>
          </Card>

          <Card className="bg-white border border-gray-100">
            <CardBody className="p-5">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-base font-semibold text-gray-900">API Key 状态</h2>
                <Button size="sm" variant="light" className="text-blue-600 hover:text-blue-700" onClick={() => router.push('/api-keys')}>
                  管理 Keys
                </Button>
              </div>
              <div className="space-y-3">
                {loading && !apiKeys.length ? (
                  <div className="h-20 flex items-center justify-center">
                    <Spinner size="sm" />
                  </div>
                ) : (
                  apiKeys.map((key) => (
                    <div key={key.id} className="flex items-center justify-between px-4 py-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                      <div>
                        <p className="font-medium text-gray-900">{key.provider} - {key.model}</p>
                        <p className="text-sm text-gray-500">限流: {key.rateLimitPerMin}/min</p>
                      </div>
                      <Badge
                        variant="flat"
                        className={key.status === ApiKeyStatus.ACTIVE ? 'bg-green-50 text-green-700 border-green-200' : 'bg-red-50 text-red-700 border-red-200'}
                      >
                        {key.status === ApiKeyStatus.ACTIVE ? '活跃' : '停用'}
                      </Badge>
                    </div>
                  ))
                )}
              </div>
            </CardBody>
          </Card>
        </div>
      </div>
    </Layout>
  );
}
