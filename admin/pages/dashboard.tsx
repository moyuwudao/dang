'use client';

import { useEffect, useState } from 'react';
import { Card, CardBody, Chip, Button } from '@nextui-org/react';
import { Users, CreditCard, Key, TrendingUp, Activity, ArrowUpRight, ArrowDownRight, Sparkles } from 'lucide-react';
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
  <Card className="bg-white/80 backdrop-blur-sm border border-indigo-100/50 hover:shadow-xl hover:shadow-indigo-500/10 transition-all duration-300 hover:-translate-y-1">
    <CardBody className="p-5">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-gray-500 text-sm font-medium">{title}</p>
          <p className="text-3xl font-bold bg-gradient-to-r from-gray-800 to-gray-900 bg-clip-text text-transparent mt-1">{value}</p>
          <div className={`flex items-center gap-1 mt-3 ${changeType === 'up' ? 'text-green-500' : 'text-red-500'}`}>
            {changeType === 'up' ? <ArrowUpRight className="w-4 h-4" /> : <ArrowDownRight className="w-4 h-4" />}
            <span className="text-sm font-medium">{change}</span>
          </div>
        </div>
        <div className={`w-14 h-14 rounded-2xl ${color} flex items-center justify-center shadow-lg`}>
          <Icon className="w-7 h-7 text-white" />
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
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent">仪表板</h1>
            <p className="text-gray-500 mt-1">欢迎回来，查看系统概览</p>
          </div>
          <Chip color="success" variant="flat" className="flex items-center gap-2 px-4 py-2 bg-green-50 text-green-600 border border-green-200">
            <Activity className="w-4 h-4" />
            系统运行正常
          </Chip>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
          <StatCard
            icon={Users}
            title="总用户数"
            value={stats.totalUsers.toLocaleString()}
            change="+12.5%"
            changeType="up"
            color="bg-gradient-to-br from-blue-500 to-indigo-500"
          />
          <StatCard
            icon={CreditCard}
            title="活跃订阅"
            value={stats.activeSubscriptions}
            change="+8.3%"
            changeType="up"
            color="bg-gradient-to-br from-green-500 to-emerald-500"
          />
          <StatCard
            icon={Key}
            title="API Key数量"
            value={stats.apiKeyCount}
            change="+2"
            changeType="up"
            color="bg-gradient-to-br from-purple-500 to-pink-500"
          />
          <StatCard
            icon={TrendingUp}
            title="今日收入"
            value={`¥${(totalRevenue / 100).toLocaleString()}`}
            change="+15.2%"
            changeType="up"
            color="bg-gradient-to-br from-orange-500 to-yellow-500"
          />
        </div>

        {/* Charts */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card className="bg-white/80 backdrop-blur-sm border border-indigo-100/50">
            <CardBody className="p-6">
              <h2 className="text-lg font-semibold text-gray-800 mb-4 flex items-center gap-2">
                <Sparkles className="w-5 h-5 text-indigo-500" />
                用户增长趋势
              </h2>
              <ResponsiveContainer width="100%" height={250}>
                <LineChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                  <XAxis dataKey="date" stroke="#9ca3af" />
                  <YAxis stroke="#9ca3af" />
                  <Tooltip />
                  <Line type="monotone" dataKey="value" stroke="#6366f1" strokeWidth={3} dot={{ fill: '#6366f1', strokeWidth: 2 }} />
                </LineChart>
              </ResponsiveContainer>
            </CardBody>
          </Card>

          <Card className="bg-white/80 backdrop-blur-sm border border-indigo-100/50">
            <CardBody className="p-6">
              <h2 className="text-lg font-semibold text-gray-800 mb-4 flex items-center gap-2">
                <Sparkles className="w-5 h-5 text-purple-500" />
                套餐分布
              </h2>
              <ResponsiveContainer width="100%" height={250}>
                <BarChart data={plans.map(p => ({ name: p.name, value: p.quotaValue || 100 }))}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                  <XAxis dataKey="name" stroke="#9ca3af" />
                  <YAxis stroke="#9ca3af" />
                  <Tooltip />
                  <Bar dataKey="value" fill="#8b5cf6" radius={[8, 8, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </CardBody>
          </Card>
        </div>

        {/* Bottom Cards */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card className="bg-white/80 backdrop-blur-sm border border-indigo-100/50">
            <CardBody className="p-6">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
                  <CreditCard className="w-5 h-5 text-indigo-500" />
                  套餐列表
                </h2>
                <Button size="sm" color="primary" variant="light" className="bg-indigo-50">查看全部</Button>
              </div>
              <div className="space-y-3">
                {plans.map((plan) => (
                  <div key={plan.id} className="flex items-center justify-between p-4 bg-gradient-to-r from-indigo-50/50 to-purple-50/50 rounded-xl border border-indigo-100/30 hover:shadow-md transition-shadow">
                    <div>
                      <p className="font-semibold text-gray-800">{plan.name}</p>
                      <p className="text-sm text-gray-500">{plan.description}</p>
                    </div>
                    <p className="font-bold text-lg bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent">¥{(plan.priceCents / 100).toFixed(0)}</p>
                  </div>
                ))}
              </div>
            </CardBody>
          </Card>

          <Card className="bg-white/80 backdrop-blur-sm border border-indigo-100/50">
            <CardBody className="p-6">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
                  <Key className="w-5 h-5 text-purple-500" />
                  API Key 状态
                </h2>
                <Button size="sm" color="primary" variant="light" className="bg-purple-50">添加 Key</Button>
              </div>
              <div className="space-y-3">
                {apiKeys.map((key) => (
                  <div key={key.id} className="flex items-center justify-between p-4 bg-gradient-to-r from-purple-50/50 to-pink-50/50 rounded-xl border border-purple-100/30 hover:shadow-md transition-shadow">
                    <div>
                      <p className="font-semibold text-gray-800">{key.provider} - {key.model}</p>
                      <p className="text-sm text-gray-500">创建于 {key.createdAt}</p>
                    </div>
                    <Chip color={key.isActive ? 'success' : 'danger'} size="sm" className={key.isActive ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}>
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
