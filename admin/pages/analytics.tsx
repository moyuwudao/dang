'use client';

import { useState } from 'react';
import { Card, CardBody, Select, SelectItem, Button } from '@nextui-org/react';
import { LineChart, Line, BarChart, Bar, PieChart, Pie, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, Cell } from 'recharts';
import { TrendingUp, Users, Volume2, DollarSign } from 'lucide-react';
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
  <Card className="bg-white border border-gray-200">
    <CardBody className="p-4">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-gray-500 text-sm">{label}</p>
          <p className="text-2xl font-bold text-gray-800 mt-1">{value}</p>
          <p className="text-green-500 text-sm mt-1">{change}</p>
        </div>
        <div className={`w-12 h-12 rounded-full ${color} flex items-center justify-center`}>
          <Icon className="w-6 h-6 text-white" />
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
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-800">数据分析</h1>
            <p className="text-gray-500 mt-1">查看业务数据和趋势分析</p>
          </div>
          <Select label="时间范围" value={timeRange} size="sm" className="w-32">
            <SelectItem key="7d" value="7d">近7天</SelectItem>
            <SelectItem key="30d" value="30d">近30天</SelectItem>
          </Select>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard icon={Users} label="活跃用户" value="1,247" change="+12.5% vs 上周" color="bg-blue-500" />
          <StatCard icon={Volume2} label="音频使用时长" value="12,560分钟" change="+8.3% vs 上周" color="bg-purple-500" />
          <StatCard icon={DollarSign} label="月度收入" value="¥118,000" change="+15.2% vs 上月" color="bg-green-500" />
          <StatCard icon={TrendingUp} label="转化率" value="24.8%" change="+3.1% vs 上周" color="bg-orange-500" />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <Card className="bg-white border border-gray-200 lg:col-span-2">
            <CardBody className="p-6">
              <h2 className="text-lg font-semibold text-gray-800 mb-4">用户增长趋势</h2>
              <ResponsiveContainer width="100%" height={280}>
                <LineChart data={monthlyData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="month" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Line type="monotone" dataKey="users" name="用户数" stroke="#6366f1" strokeWidth={2} />
                  <Line type="monotone" dataKey="subscriptions" name="订阅数" stroke="#8b5cf6" strokeWidth={2} />
                </LineChart>
              </ResponsiveContainer>
            </CardBody>
          </Card>

          <Card className="bg-white border border-gray-200">
            <CardBody className="p-6">
              <h2 className="text-lg font-semibold text-gray-800 mb-4">套餐分布</h2>
              <ResponsiveContainer width="100%" height={280}>
                <PieChart>
                  <Pie data={planDistribution} cx="50%" cy="50%" innerRadius={40} outerRadius={80} paddingAngle={2} dataKey="value" label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}>
                    {planDistribution.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip />
                  <Legend />
                </PieChart>
              </ResponsiveContainer>
            </CardBody>
          </Card>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card className="bg-white border border-gray-200">
            <CardBody className="p-6">
              <h2 className="text-lg font-semibold text-gray-800 mb-4">本周每日数据</h2>
              <ResponsiveContainer width="100%" height={250}>
                <BarChart data={weeklyData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="day" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="users" name="新增用户" fill="#6366f1" />
                  <Bar dataKey="usage" name="使用时长(百分钟)" fill="#8b5cf6" />
                </BarChart>
              </ResponsiveContainer>
            </CardBody>
          </Card>

          <Card className="bg-white border border-gray-200">
            <CardBody className="p-6">
              <h2 className="text-lg font-semibold text-gray-800 mb-4">收入趋势</h2>
              <ResponsiveContainer width="100%" height={250}>
                <LineChart data={weeklyData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="day" />
                  <YAxis />
                  <Tooltip />
                  <Line type="monotone" dataKey="revenue" name="收入(元)" stroke="#22c55e" strokeWidth={2} />
                </LineChart>
              </ResponsiveContainer>
            </CardBody>
          </Card>
        </div>

        <Card className="bg-white border border-gray-200">
          <CardBody className="p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-gray-800">数据报告</h2>
              <Button size="sm" color="primary" variant="light">导出报告</Button>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div className="text-center p-4 bg-gray-50 rounded-lg">
                <p className="text-3xl font-bold text-blue-600">12,453</p>
                <p className="text-sm text-gray-500 mt-1">累计用户数</p>
              </div>
              <div className="text-center p-4 bg-gray-50 rounded-lg">
                <p className="text-3xl font-bold text-purple-600">342</p>
                <p className="text-sm text-gray-500 mt-1">活跃订阅</p>
              </div>
              <div className="text-center p-4 bg-gray-50 rounded-lg">
                <p className="text-3xl font-bold text-green-600">24.8%</p>
                <p className="text-sm text-gray-500 mt-1">订阅转化率</p>
              </div>
              <div className="text-center p-4 bg-gray-50 rounded-lg">
                <p className="text-3xl font-bold text-orange-600">¥587,000</p>
                <p className="text-sm text-gray-500 mt-1">累计收入</p>
              </div>
            </div>
          </CardBody>
        </Card>
      </div>
    </Layout>
  );
}
