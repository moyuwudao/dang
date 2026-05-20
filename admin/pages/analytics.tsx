'use client';

import { useState } from 'react';
import { Card, CardBody, Select, SelectItem, Button } from '@nextui-org/react';
import { LineChart, Line, BarChart, Bar, PieChart, Pie, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, Cell } from 'recharts';
import { TrendingUp, Users, Volume2, DollarSign, Sparkles, Download } from 'lucide-react';
import Layout from '@/components/Layout';

const weeklyData = [
  { day: '周一', users: 120, usage: 1500, revenue: 850 },
  { day: '周二', users: 145, usage: 1800, revenue: 980 },
  { day: '周三', users: 130, usage: 1650, revenue: 920 },
  { day: '周四', users: 160, usage: 2100, revenue: 1200 },
  { day: '周五', users: 175, usage: 2400, revenue: 1350 },
  { day: '周六', users: 200, usage: 2800, revenue: 1580 },
  { day: '周日', users: 185, usage: 2500, revenue: 1420 },
];

const planDistribution = [
  { name: '免费版', value: 65 },
  { name: '基础版', value: 20 },
  { name: '专业版', value: 10 },
  { name: '企业版', value: 5 },
];

const monthlyData = [
  { month: '1月', users: 500, subscriptions: 80, revenue: 45000 },
  { month: '2月', users: 620, subscriptions: 105, revenue: 58000 },
  { month: '3月', users: 780, subscriptions: 130, revenue: 72000 },
  { month: '4月', users: 950, subscriptions: 165, revenue: 92000 },
  { month: '5月', users: 1180, subscriptions: 210, revenue: 118000 },
];

const COLORS = ['#6366f1', '#8b5cf6', '#a855f7', '#d946ef'];

const StatCard = ({ icon: Icon, label, value, change, color }: { icon: React.ElementType, label: string, value: string | number, change: string, color: string }) => (
  <Card className="bg-white/80 backdrop-blur-sm border border-indigo-100/50 hover:shadow-xl hover:shadow-indigo-500/10 transition-all duration-300 hover:-translate-y-1">
    <CardBody className="p-5">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-gray-500 text-sm font-medium">{label}</p>
          <p className="text-2xl font-bold text-gray-800 mt-1">{value}</p>
          <p className="text-green-500 text-sm mt-2 font-medium">{change}</p>
        </div>
        <div className={`w-14 h-14 rounded-2xl ${color} flex items-center justify-center shadow-lg`}>
          <Icon className="w-7 h-7 text-white" />
        </div>
      </div>
    </CardBody>
  </Card>
);

export default function AnalyticsPage() {
  const [timeRange] = useState('7d');

  return (
    <Layout currentPage="analytics">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent">数据分析</h1>
            <p className="text-gray-500 mt-1">查看业务数据和趋势分析</p>
          </div>
          <div className="flex items-center gap-3">
            <Select label="时间范围" value={timeRange} size="sm" className="w-32" classNames={{ trigger: 'bg-white/80 border border-gray-200/50 rounded-xl' }}>
              <SelectItem key="7d" value="7d">近7天</SelectItem>
              <SelectItem key="30d" value="30d">近30天</SelectItem>
            </Select>
            <Button size="sm" color="primary" variant="flat" className="bg-gradient-to-r from-indigo-500 to-purple-500 text-white">
              <Download className="w-4 h-4 mr-1" />
              导出
            </Button>
          </div>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
          <StatCard icon={Users} label="活跃用户" value="1,247" change="+12.5% vs 上周" color="bg-gradient-to-br from-blue-500 to-indigo-500" />
          <StatCard icon={Volume2} label="音频使用时长" value="12,560分钟" change="+8.3% vs 上周" color="bg-gradient-to-br from-purple-500 to-pink-500" />
          <StatCard icon={DollarSign} label="月度收入" value="¥118,000" change="+15.2% vs 上月" color="bg-gradient-to-br from-green-500 to-emerald-500" />
          <StatCard icon={TrendingUp} label="转化率" value="24.8%" change="+3.1% vs 上周" color="bg-gradient-to-br from-orange-500 to-yellow-500" />
        </div>

        {/* Charts Row 1 */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <Card className="bg-white/80 backdrop-blur-sm border border-indigo-100/50 lg:col-span-2">
            <CardBody className="p-6">
              <h2 className="text-lg font-semibold text-gray-800 mb-4 flex items-center gap-2">
                <Sparkles className="w-5 h-5 text-indigo-500" />
                用户增长趋势
              </h2>
              <ResponsiveContainer width="100%" height={280}>
                <LineChart data={monthlyData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                  <XAxis dataKey="month" stroke="#9ca3af" />
                  <YAxis stroke="#9ca3af" />
                  <Tooltip />
                  <Legend />
                  <Line type="monotone" dataKey="users" name="用户数" stroke="#6366f1" strokeWidth={3} dot={{ fill: '#6366f1', strokeWidth: 2, r: 4 }} />
                  <Line type="monotone" dataKey="subscriptions" name="订阅数" stroke="#8b5cf6" strokeWidth={3} dot={{ fill: '#8b5cf6', strokeWidth: 2, r: 4 }} />
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
              <ResponsiveContainer width="100%" height={280}>
                <PieChart>
                  <Pie data={planDistribution} cx="50%" cy="50%" innerRadius={50} outerRadius={90} paddingAngle={3} dataKey="value" label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}>
                    {planDistribution.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </CardBody>
          </Card>
        </div>

        {/* Charts Row 2 */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card className="bg-white/80 backdrop-blur-sm border border-indigo-100/50">
            <CardBody className="p-6">
              <h2 className="text-lg font-semibold text-gray-800 mb-4 flex items-center gap-2">
                <TrendingUp className="w-5 h-5 text-blue-500" />
                本周每日数据
              </h2>
              <ResponsiveContainer width="100%" height={250}>
                <BarChart data={weeklyData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                  <XAxis dataKey="day" stroke="#9ca3af" />
                  <YAxis stroke="#9ca3af" />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="users" name="新增用户" fill="#6366f1" radius={[8, 8, 0, 0]} />
                  <Bar dataKey="usage" name="使用时长(百分钟)" fill="#8b5cf6" radius={[8, 8, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </CardBody>
          </Card>

          <Card className="bg-white/80 backdrop-blur-sm border border-indigo-100/50">
            <CardBody className="p-6">
              <h2 className="text-lg font-semibold text-gray-800 mb-4 flex items-center gap-2">
                <DollarSign className="w-5 h-5 text-green-500" />
                收入趋势
              </h2>
              <ResponsiveContainer width="100%" height={250}>
                <LineChart data={weeklyData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                  <XAxis dataKey="day" stroke="#9ca3af" />
                  <YAxis stroke="#9ca3af" />
                  <Tooltip />
                  <Line type="monotone" dataKey="revenue" name="收入(元)" stroke="#22c55e" strokeWidth={3} dot={{ fill: '#22c55e', strokeWidth: 2, r: 4 }} />
                </LineChart>
              </ResponsiveContainer>
            </CardBody>
          </Card>
        </div>

        {/* Report Cards */}
        <Card className="bg-white/80 backdrop-blur-sm border border-indigo-100/50">
          <CardBody className="p-6">
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
                <Sparkles className="w-5 h-5 text-indigo-500" />
                数据报告
              </h2>
              <Button size="sm" color="primary" variant="light" className="bg-indigo-50">
                <Download className="w-4 h-4 mr-1" />
                导出报告
              </Button>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div className="text-center p-5 bg-gradient-to-br from-blue-50/80 to-indigo-50/50 rounded-xl border border-blue-100/50">
                <p className="text-3xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">12,453</p>
                <p className="text-sm text-gray-500 mt-2 font-medium">累计用户数</p>
              </div>
              <div className="text-center p-5 bg-gradient-to-br from-purple-50/80 to-pink-50/50 rounded-xl border border-purple-100/50">
                <p className="text-3xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 bg-clip-text text-transparent">342</p>
                <p className="text-sm text-gray-500 mt-2 font-medium">活跃订阅</p>
              </div>
              <div className="text-center p-5 bg-gradient-to-br from-green-50/80 to-emerald-50/50 rounded-xl border border-green-100/50">
                <p className="text-3xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 bg-clip-text text-transparent">24.8%</p>
                <p className="text-sm text-gray-500 mt-2 font-medium">订阅转化率</p>
              </div>
              <div className="text-center p-5 bg-gradient-to-br from-orange-50/80 to-yellow-50/50 rounded-xl border border-orange-100/50">
                <p className="text-3xl font-bold bg-gradient-to-r from-orange-600 to-yellow-600 bg-clip-text text-transparent">¥587,000</p>
                <p className="text-sm text-gray-500 mt-2 font-medium">累计收入</p>
              </div>
            </div>
          </CardBody>
        </Card>
      </div>
    </Layout>
  );
}
