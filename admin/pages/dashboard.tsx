'use client';

import { useEffect, useState } from 'react';
import { Card, CardBody, Chip, Button } from '@nextui-org/react';
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

const StatCard = ({ icon: Icon, title, value, change, changeType, color }: { icon: React.ElementType, title: string, value: string | number, change: string, changeType: 'up' | 'down', color: string }) => (
  <Card className="bg-white border border-gray-200 hover:shadow-lg transition-shadow">
    <CardBody className="p-4">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-gray-500 text-sm">{title}</p>
          <p className="text-2xl font-bold text-gray-800 mt-1">{value}</p>
          <div className={`flex items-center gap-1 mt-2 ${changeType === 'up' ? 'text-green-500' : 'text-red-500'}`}>
            {changeType === 'up' ? <ArrowUpRight className="w-4 h-4" /> : <ArrowDownRight className="w-4 h-4" />}
            <span className="text-sm">{change}</span>
          </div>
        </div>
        <div className={`w-12 h-12 rounded-full ${color} flex items-center justify-center`}>
          <Icon className="w-6 h-6 text-white" />
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
  const [loading] = useState(true);

  const totalRevenue = plans.reduce((acc, plan) => acc + (plan.priceCents * 10), 0);

  return (
    <Layout currentPage="dashboard">
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-800">仪表板</h1>
            <p className="text-gray-500 mt-1">欢迎回来，查看系统概览</p>
          </div>
          <Chip color="success" variant="flat" className="flex items-center gap-2">
            <Activity className="w-4 h-4" />
            系统运行正常
          </Chip>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard
            icon={Users}
            title="总用户数"
            value={stats.totalUsers.toLocaleString()}
            change="+12.5%"
            changeType="up"
            color="bg-blue-500"
          />
          <StatCard
            icon={CreditCard}
            title="活跃订阅"
            value={stats.activeSubscriptions}
            change="+8.3%"
            changeType="up"
            color="bg-green-500"
          />
          <StatCard
            icon={Key}
            title="API Key数量"
            value={stats.apiKeyCount}
            change="+2"
            changeType="up"
            color="bg-purple-500"
          />
          <StatCard
            icon={TrendingUp}
            title="今日收入"
            value={`¥${(totalRevenue / 100).toLocaleString()}`}
            change="+15.2%"
            changeType="up"
            color="bg-orange-500"
          />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card className="bg-white border border-gray-200">
            <CardBody className="p-6">
              <h2 className="text-lg font-semibold text-gray-800 mb-4">用户增长趋势</h2>
              <ResponsiveContainer width="100%" height={250}>
                <LineChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip />
                  <Line type="monotone" dataKey="value" stroke="#6366f1" strokeWidth={2} />
                </LineChart>
              </ResponsiveContainer>
            </CardBody>
          </Card>

          <Card className="bg-white border border-gray-200">
            <CardBody className="p-6">
              <h2 className="text-lg font-semibold text-gray-800 mb-4">套餐分布</h2>
              <ResponsiveContainer width="100%" height={250}>
                <BarChart data={plans.map(p => ({ name: p.name, value: p.quotaValue || 100 }))}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="value" fill="#8b5cf6" />
                </BarChart>
              </ResponsiveContainer>
            </CardBody>
          </Card>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card className="bg-white border border-gray-200">
            <CardBody className="p-6">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-lg font-semibold text-gray-800">套餐列表</h2>
                <Button size="sm" color="primary" variant="ghost">查看全部</Button>
              </div>
              <div className="space-y-3">
                {plans.map((plan) => (
                  <div key={plan.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                    <div>
                      <p className="font-medium text-gray-800">{plan.name}</p>
                      <p className="text-sm text-gray-500">{plan.description}</p>
                    </div>
                    <p className="font-semibold text-gray-800">¥{(plan.priceCents / 100).toFixed(0)}</p>
                  </div>
                ))}
              </div>
            </CardBody>
          </Card>

          <Card className="bg-white border border-gray-200">
            <CardBody className="p-6">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-lg font-semibold text-gray-800">API Key 状态</h2>
                <Button size="sm" color="primary" variant="ghost">添加 Key</Button>
              </div>
              <div className="space-y-3">
                {apiKeys.map((key) => (
                  <div key={key.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                    <div>
                      <p className="font-medium text-gray-800">{key.provider} - {key.model}</p>
                      <p className="text-sm text-gray-500">创建于 {key.createdAt}</p>
                    </div>
                    <Chip color={key.isActive ? 'success' : 'danger'} size="sm">
                      {key.isActive ? '活跃' : '停用'}
                    </Chip>
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
