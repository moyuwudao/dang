'use client';

import { useEffect, useState } from 'react';
import { Card, CardBody, Button, Badge } from '@nextui-org/react';
import { Users, CreditCard, Key, TrendingUp, Activity, ArrowUpRight, ArrowDownRight } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar } from 'recharts';
import Layout from '@/components/Layout';
import { subscriptionAPI, apiKeyAPI } from '@/services/api';
import type { DashboardStats, Plan, ApiKey, ChartDataPoint } from '@/types';

const mockStats: DashboardStats = {
  totalUsers: 1247,
  activeSubscriptions: 342,
  apiKeyCount: 12,
  totalQuotaUsed: 12560,
};

const mockChartData: ChartDataPoint[] = [
  { date: '05-14', value: 120 },
  { date: '05-15', value: 180 },
  { date: '05-16', value: 150 },
  { date: '05-17', value: 220 },
  { date: '05-18', value: 190 },
  { date: '05-19', value: 250 },
  { date: '05-20', value: 280 },
];

const mockPlans: Plan[] = [
  { id: 'free', name: '免费版', description: '免费体验', priceCents: 0, durationDays: 30, quotaType: 'minutes', quotaValue: 30, isActive: true },
  { id: 'basic', name: '基础版', description: '基础功能', priceCents: 9900, durationDays: 30, quotaType: 'minutes', quotaValue: 300, isActive: true },
  { id: 'pro', name: '专业版', description: '专业功能', priceCents: 29900, durationDays: 30, quotaType: 'minutes', quotaValue: 1000, isActive: true },
  { id: 'enterprise', name: '企业版', description: '无限使用', priceCents: 99900, durationDays: 30, quotaType: 'unlimited', quotaValue: 0, isActive: true },
];

const mockApiKeys: ApiKey[] = [
  { id: '1', provider: 'qwen', model: 'qwen-max', isActive: true, rateLimitPerMin: 60, createdAt: '2026-05-15' },
  { id: '2', provider: 'qwen', model: 'qwen-plus', isActive: true, rateLimitPerMin: 30, createdAt: '2026-05-16' },
];

const StatCard = ({ icon: Icon, title, value, change, changeType }: { icon: React.ElementType, title: string, value: string | number, change: string, changeType: 'up' | 'down' }) => (
  <Card className="bg-white border border-gray-100 hover:shadow-sm transition-shadow duration-200">
    <CardBody className="p-5">
      <div className="flex items-start justify-between">
        <div className="space-y-2">
          <p className="text-sm text-gray-500 font-medium">{title}</p>
          <p className="text-2xl font-semibold text-gray-900">{value}</p>
          <div className={`flex items-center gap-1 ${changeType === 'up' ? 'text-green-600' : 'text-red-500'}`}>
            {changeType === 'up' ? <ArrowUpRight className="w-4 h-4" /> : <ArrowDownRight className="w-4 h-4" />}
            <span className="text-sm font-medium">{change}</span>
          </div>
        </div>
        <div className="w-12 h-12 rounded-lg bg-blue-50 flex items-center justify-center">
          <Icon className="w-6 h-6 text-blue-600" />
        </div>
      </div>
    </CardBody>
  </Card>
);

export default function DashboardPage() {
  const [stats] = useState<DashboardStats>(mockStats);
  const [plans] = useState<Plan[]>(mockPlans);
  const [apiKeys] = useState<ApiKey[]>(mockApiKeys);
  const [chartData] = useState<ChartDataPoint[]>(mockChartData);

  const totalRevenue = plans.reduce((acc, plan) => acc + (plan.priceCents * 10), 0);

  return (
    <Layout currentPage="dashboard">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-semibold text-gray-900">仪表板</h1>
            <p className="text-sm text-gray-500 mt-1">欢迎回来，查看系统概览</p>
          </div>
          <Badge variant="flat" className="bg-green-50 text-green-700 border-green-200 px-3 py-1.5">
            <Activity className="w-3.5 h-3.5 mr-1.5" />
            系统运行正常
          </Badge>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard
            icon={Users}
            title="总用户数"
            value={stats.totalUsers.toLocaleString()}
            change="+12.5%"
            changeType="up"
          />
          <StatCard
            icon={CreditCard}
            title="活跃订阅"
            value={stats.activeSubscriptions}
            change="+8.3%"
            changeType="up"
          />
          <StatCard
            icon={Key}
            title="API Key数量"
            value={stats.apiKeyCount}
            change="+2"
            changeType="up"
          />
          <StatCard
            icon={TrendingUp}
            title="今日收入"
            value={`¥${(totalRevenue / 100).toLocaleString()}`}
            change="+15.2%"
            changeType="up"
          />
        </div>

        {/* Charts */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <Card className="bg-white border border-gray-100">
            <CardBody className="p-5">
              <h2 className="text-base font-semibold text-gray-900 mb-4">用户增长趋势</h2>
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
                  <Line type="monotone" dataKey="value" stroke="#3b82f6" strokeWidth={2} dot={{ fill: '#3b82f6', strokeWidth: 2, r: 4 }} />
                </LineChart>
              </ResponsiveContainer>
            </CardBody>
          </Card>

          <Card className="bg-white border border-gray-100">
            <CardBody className="p-5">
              <h2 className="text-base font-semibold text-gray-900 mb-4">套餐分布</h2>
              <ResponsiveContainer width="100%" height={240}>
                <BarChart data={plans.map(p => ({ name: p.name, value: p.quotaValue || 100 }))}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
                  <XAxis dataKey="name" stroke="#9ca3af" tick={{ fontSize: 12 }} />
                  <YAxis stroke="#9ca3af" tick={{ fontSize: 12 }} />
                  <Tooltip 
                    contentStyle={{ 
                      backgroundColor: '#fff', 
                      border: '1px solid #e5e7eb',
                      borderRadius: '8px',
                      padding: '8px 12px'
                    }} 
                  />
                  <Bar dataKey="value" fill="#3b82f6" radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </CardBody>
          </Card>
        </div>

        {/* Bottom Cards */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <Card className="bg-white border border-gray-100">
            <CardBody className="p-5">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-base font-semibold text-gray-900">套餐列表</h2>
                <Button size="sm" variant="light" className="text-blue-600 hover:text-blue-700">查看全部</Button>
              </div>
              <div className="space-y-3">
                {plans.map((plan) => (
                  <div key={plan.id} className="flex items-center justify-between px-4 py-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                    <div>
                      <p className="font-medium text-gray-900">{plan.name}</p>
                      <p className="text-sm text-gray-500">{plan.description}</p>
                    </div>
                    <p className="font-semibold text-gray-900">¥{(plan.priceCents / 100).toFixed(0)}</p>
                  </div>
                ))}
              </div>
            </CardBody>
          </Card>

          <Card className="bg-white border border-gray-100">
            <CardBody className="p-5">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-base font-semibold text-gray-900">API Key 状态</h2>
                <Button size="sm" variant="light" className="text-blue-600 hover:text-blue-700">添加 Key</Button>
              </div>
              <div className="space-y-3">
                {apiKeys.map((key) => (
                  <div key={key.id} className="flex items-center justify-between px-4 py-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                    <div>
                      <p className="font-medium text-gray-900">{key.provider} - {key.model}</p>
                      <p className="text-sm text-gray-500">创建于 {key.createdAt}</p>
                    </div>
                    <Badge 
                      variant="flat" 
                      className={key.isActive ? 'bg-green-50 text-green-700 border-green-200' : 'bg-red-50 text-red-700 border-red-200'}
                    >
                      {key.isActive ? '活跃' : '停用'}
                    </Badge>
                  </div>
                ))}
              </div>
            </CardBody>
          </Card>
        </div>
      </div>
    </Layout>
  );
}
