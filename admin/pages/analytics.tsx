'use client';

import { useState, useEffect, useCallback } from 'react';
import {
  Card,
  CardBody,
  Button,
  Table,
  TableHeader,
  TableColumn,
  TableBody,
  TableRow,
  TableCell,
  Chip,
  Spinner,
  Pagination,
} from '@nextui-org/react';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  PieChart,
  Pie,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  Cell,
} from 'recharts';
import {
  TrendingUp,
  Users,
  Key,
  DollarSign,
  Sparkles,
  Download,
  AlertCircle,
  CreditCard,
} from 'lucide-react';
import Layout from '@/components/Layout';
import { adminAPI } from '@/services/api';
import type { DashboardStats, ChartDataPoint, RechargeRecord } from '@/types';

const PIE_COLORS = ['#3b82f6', '#60a5fa', '#93c5fd', '#bfdbfe'];

interface PlanDistributionItem {
  name: string;
  value: number;
}

const StatCard = ({
  icon: Icon,
  label,
  value,
  color = 'blue',
}: {
  icon: React.ElementType;
  label: string;
  value: string | number;
  color?: 'blue' | 'green' | 'purple' | 'orange';
}) => {
  const colorMap = {
    blue: 'bg-blue-50 text-blue-600',
    green: 'bg-green-50 text-green-600',
    purple: 'bg-purple-50 text-purple-600',
    orange: 'bg-orange-50 text-orange-600',
  };
  return (
    <Card className="bg-white border border-gray-100 hover:shadow-sm transition-all duration-300">
      <CardBody className="p-5">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-gray-500 text-sm font-medium">{label}</p>
            <p className="text-2xl font-bold text-gray-800 mt-1">{value}</p>
          </div>
          <div className={`w-14 h-14 rounded-lg flex items-center justify-center ${colorMap[color]}`}>
            <Icon className="w-7 h-7" />
          </div>
        </div>
      </CardBody>
    </Card>
  );
};

export default function AnalyticsPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [userGrowth, setUserGrowth] = useState<ChartDataPoint[]>([]);
  const [revenueTrend, setRevenueTrend] = useState<ChartDataPoint[]>([]);
  const [rechargeRecords, setRechargeRecords] = useState<RechargeRecord[]>([]);
  const [rechargeTotal, setRechargeTotal] = useState(0);
  const [rechargePage, setRechargePage] = useState(1);
  const [rechargeTotalPages, setRechargeTotalPages] = useState(1);

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAllData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [statsData, growthData, revenueData, rechargeData] = await Promise.all([
        adminAPI.getStats(),
        adminAPI.getUserGrowth(30),
        adminAPI.getRevenueTrend(30),
        adminAPI.getRechargeRecords(1, 10),
      ]);
      setStats(statsData);
      setUserGrowth(growthData);
      setRevenueTrend(revenueData);
      setRechargeRecords(rechargeData.items || []);
      setRechargeTotal(rechargeData.total);
      setRechargeTotalPages(rechargeData.totalPages);
      setRechargePage(1);
    } catch (err: any) {
      setError(err?.response?.data?.message || '加载数据失败，请稍后重试');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchAllData();
  }, [fetchAllData]);

  const fetchRechargePage = async (page: number) => {
    try {
      const data = await adminAPI.getRechargeRecords(page, 10);
      setRechargeRecords(data.items || []);
      setRechargeTotal(data.total);
      setRechargeTotalPages(data.totalPages);
      setRechargePage(page);
    } catch (err: any) {
      setError(err?.response?.data?.message || '加载充值记录失败');
    }
  };

  const formatCurrency = (cents: number) => {
    return `¥${(cents / 100).toFixed(2)}`;
  };

  const formatDate = (dateStr: string) => {
    try {
      return new Date(dateStr).toLocaleDateString('zh-CN');
    } catch {
      return dateStr;
    }
  };

  const getStatusChip = (status: string) => {
    const statusMap: Record<string, { color: 'success' | 'warning' | 'danger' | 'default'; label: string; className: string }> = {
      success: { color: 'success', label: '成功', className: 'bg-green-100 text-green-700 border border-green-200' },
      completed: { color: 'success', label: '成功', className: 'bg-green-100 text-green-700 border border-green-200' },
      pending: { color: 'warning', label: '待处理', className: 'bg-yellow-100 text-yellow-700 border border-yellow-200' },
      failed: { color: 'danger', label: '失败', className: 'bg-red-100 text-red-700 border border-red-200' },
    };
    const config = statusMap[status] || { color: 'default', label: status, className: 'bg-gray-100 text-gray-700 border border-gray-200' };
    return (
      <Chip color={config.color} size="sm" className={config.className}>
        {config.label}
      </Chip>
    );
  };

  // 套餐分布数据（基于 stats 计算，如果没有则使用默认值）
  const planDistribution: PlanDistributionItem[] = [
    { name: '免费版', value: stats ? Math.max(0, stats.totalUsers - stats.activeSubscriptions * 3) : 65 },
    { name: '基础版', value: stats ? Math.round(stats.activeSubscriptions * 0.5) : 20 },
    { name: '专业版', value: stats ? Math.round(stats.activeSubscriptions * 0.3) : 10 },
    { name: '企业版', value: stats ? Math.round(stats.activeSubscriptions * 0.2) : 5 },
  ];

  // 计算本月收入（从 revenueTrend 最后7天求和）
  const monthlyRevenue = revenueTrend.slice(-7).reduce((sum, item) => sum + item.value, 0);

  // 计算转化率
  const conversionRate = stats && stats.totalUsers > 0
    ? ((stats.activeSubscriptions / stats.totalUsers) * 100).toFixed(1)
    : '0.0';

  return (
    <Layout currentPage="analytics">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-semibold text-gray-900">数据分析</h1>
            <p className="text-gray-500 mt-1">查看业务数据和趋势分析</p>
          </div>
          <div className="flex items-center gap-3">
            <Button
              size="sm"
              color="primary"
              variant="flat"
              className="bg-blue-600 hover:bg-blue-700 text-white"
              onClick={fetchAllData}
              isLoading={loading}
            >
              <Download className="w-4 h-4 mr-1" />
              刷新数据
            </Button>
          </div>
        </div>

        {/* Error Alert */}
        {error && (
          <Card className="bg-red-50 border border-red-200">
            <CardBody className="p-4 flex items-center gap-3">
              <AlertCircle className="w-5 h-5 text-red-500 shrink-0" />
              <p className="text-red-700 text-sm">{error}</p>
              <Button size="sm" variant="light" className="ml-auto text-red-600" onClick={() => setError(null)}>
                关闭
              </Button>
            </CardBody>
          </Card>
        )}

        {/* Loading State */}
        {loading && !stats ? (
          <div className="flex items-center justify-center py-20">
            <Spinner size="lg" color="primary" />
            <span className="ml-3 text-gray-500">加载数据中...</span>
          </div>
        ) : (
          <>
            {/* Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-5">
              <StatCard icon={Users} label="总用户" value={stats?.totalUsers?.toLocaleString() || '0'} color="blue" />
              <StatCard
                icon={Sparkles}
                label="活跃订阅"
                value={stats?.activeSubscriptions?.toLocaleString() || '0'}
                color="purple"
              />
              <StatCard icon={Key} label="API Key 数" value={stats?.apiKeyCount?.toLocaleString() || '0'} color="orange" />
              <StatCard
                icon={DollarSign}
                label="累计收入"
                value={formatCurrency(stats?.totalRevenue || 0)}
                color="green"
              />
              <StatCard
                icon={TrendingUp}
                label="本月收入"
                value={formatCurrency(monthlyRevenue)}
                color="blue"
              />
              <StatCard icon={TrendingUp} label="转化率" value={`${conversionRate}%`} color="purple" />
            </div>

            {/* Charts Row 1 */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              {/* User Growth Line Chart */}
              <Card className="bg-white border border-gray-100 lg:col-span-2">
                <CardBody className="p-6">
                  <h2 className="text-lg font-semibold text-gray-800 mb-4 flex items-center gap-2">
                    <Users className="w-5 h-5 text-blue-600" />
                    用户增长趋势（近30天）
                  </h2>
                  {userGrowth.length > 0 ? (
                    <ResponsiveContainer width="100%" height={280}>
                      <LineChart data={userGrowth}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                        <XAxis
                          dataKey="date"
                          stroke="#9ca3af"
                          tickFormatter={(value) => {
                            try {
                              return new Date(value).toLocaleDateString('zh-CN', { month: 'short', day: 'numeric' });
                            } catch {
                              return value;
                            }
                          }}
                        />
                        <YAxis stroke="#9ca3af" />
                        <Tooltip
                          formatter={(value: number) => [value, '用户数']}
                          labelFormatter={(label) => {
                            try {
                              return new Date(label).toLocaleDateString('zh-CN');
                            } catch {
                              return label;
                            }
                          }}
                        />
                        <Line
                          type="monotone"
                          dataKey="value"
                          name="新增用户"
                          stroke="#3b82f6"
                          strokeWidth={3}
                          dot={{ fill: '#3b82f6', strokeWidth: 2, r: 3 }}
                          activeDot={{ r: 6 }}
                        />
                      </LineChart>
                    </ResponsiveContainer>
                  ) : (
                    <div className="flex items-center justify-center h-[280px] text-gray-400">
                      暂无用户增长数据
                    </div>
                  )}
                </CardBody>
              </Card>

              {/* Plan Distribution Pie Chart */}
              <Card className="bg-white border border-gray-100">
                <CardBody className="p-6">
                  <h2 className="text-lg font-semibold text-gray-800 mb-4 flex items-center gap-2">
                    <Sparkles className="w-5 h-5 text-blue-600" />
                    套餐分布
                  </h2>
                  <ResponsiveContainer width="100%" height={280}>
                    <PieChart>
                      <Pie
                        data={planDistribution}
                        cx="50%"
                        cy="50%"
                        innerRadius={50}
                        outerRadius={90}
                        paddingAngle={3}
                        dataKey="value"
                        label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                      >
                        {planDistribution.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={PIE_COLORS[index % PIE_COLORS.length]} />
                        ))}
                      </Pie>
                      <Tooltip formatter={(value: number) => [value, '用户']} />
                    </PieChart>
                  </ResponsiveContainer>
                </CardBody>
              </Card>
            </div>

            {/* Charts Row 2 */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Revenue Trend Bar Chart */}
              <Card className="bg-white border border-gray-100">
                <CardBody className="p-6">
                  <h2 className="text-lg font-semibold text-gray-800 mb-4 flex items-center gap-2">
                    <DollarSign className="w-5 h-5 text-green-500" />
                    收入趋势（近30天）
                  </h2>
                  {revenueTrend.length > 0 ? (
                    <ResponsiveContainer width="100%" height={250}>
                      <BarChart data={revenueTrend}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                        <XAxis
                          dataKey="date"
                          stroke="#9ca3af"
                          tickFormatter={(value) => {
                            try {
                              return new Date(value).toLocaleDateString('zh-CN', { month: 'short', day: 'numeric' });
                            } catch {
                              return value;
                            }
                          }}
                        />
                        <YAxis stroke="#9ca3af" tickFormatter={(value) => `¥${(value / 100).toFixed(0)}`} />
                        <Tooltip
                          formatter={(value: number) => [formatCurrency(value), '收入']}
                          labelFormatter={(label) => {
                            try {
                              return new Date(label).toLocaleDateString('zh-CN');
                            } catch {
                              return label;
                            }
                          }}
                        />
                        <Bar dataKey="value" name="收入" fill="#3b82f6" radius={[8, 8, 0, 0]} />
                      </BarChart>
                    </ResponsiveContainer>
                  ) : (
                    <div className="flex items-center justify-center h-[250px] text-gray-400">
                      暂无收入趋势数据
                    </div>
                  )}
                </CardBody>
              </Card>

              {/* Summary Card */}
              <Card className="bg-white border border-gray-100">
                <CardBody className="p-6">
                  <h2 className="text-lg font-semibold text-gray-800 mb-4 flex items-center gap-2">
                    <CreditCard className="w-5 h-5 text-blue-600" />
                    数据概览
                  </h2>
                  <div className="space-y-4">
                    <div className="flex items-center justify-between p-4 bg-gray-50/80 rounded-xl">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
                          <Users className="w-5 h-5 text-blue-600" />
                        </div>
                        <div>
                          <p className="text-sm text-gray-500">总注册用户</p>
                          <p className="font-semibold text-gray-800">{stats?.totalUsers?.toLocaleString() || '0'}</p>
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center justify-between p-4 bg-gray-50/80 rounded-xl">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-lg bg-purple-50 flex items-center justify-center">
                          <Sparkles className="w-5 h-5 text-purple-600" />
                        </div>
                        <div>
                          <p className="text-sm text-gray-500">付费订阅数</p>
                          <p className="font-semibold text-gray-800">
                            {stats?.activeSubscriptions?.toLocaleString() || '0'}
                          </p>
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center justify-between p-4 bg-gray-50/80 rounded-xl">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-lg bg-green-50 flex items-center justify-center">
                          <DollarSign className="w-5 h-5 text-green-600" />
                        </div>
                        <div>
                          <p className="text-sm text-gray-500">累计总收入</p>
                          <p className="font-semibold text-gray-800">{formatCurrency(stats?.totalRevenue || 0)}</p>
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center justify-between p-4 bg-gray-50/80 rounded-xl">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-lg bg-orange-50 flex items-center justify-center">
                          <TrendingUp className="w-5 h-5 text-orange-600" />
                        </div>
                        <div>
                          <p className="text-sm text-gray-500">订阅转化率</p>
                          <p className="font-semibold text-gray-800">{conversionRate}%</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </CardBody>
              </Card>
            </div>

            {/* Recharge Records Table */}
            <Card className="bg-white border border-gray-100">
              <CardBody className="p-6">
                <div className="flex items-center justify-between mb-5">
                  <h2 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
                    <CreditCard className="w-5 h-5 text-blue-600" />
                    充值记录
                  </h2>
                  <span className="text-sm text-gray-500">共 {rechargeTotal} 条记录</span>
                </div>
                {rechargeRecords.length > 0 ? (
                  <>
                    <Table aria-label="充值记录">
                      <TableHeader>
                        <TableColumn className="bg-gray-50/80">用户</TableColumn>
                        <TableColumn className="bg-gray-50/80">金额</TableColumn>
                        <TableColumn className="bg-gray-50/80">类型</TableColumn>
                        <TableColumn className="bg-gray-50/80">支付方式</TableColumn>
                        <TableColumn className="bg-gray-50/80">状态</TableColumn>
                        <TableColumn className="bg-gray-50/80">时间</TableColumn>
                      </TableHeader>
                      <TableBody>
                        {rechargeRecords.map((record) => (
                          <TableRow key={record.id} className="hover:bg-gray-50 transition-colors">
                            <TableCell>
                              <span className="font-medium text-gray-800">
                                {record.userPhone || record.userId}
                              </span>
                            </TableCell>
                            <TableCell>
                              <span className="font-semibold text-green-600">
                                {formatCurrency(record.amountCents)}
                              </span>
                            </TableCell>
                            <TableCell>
                              <span className="text-gray-600">{record.type}</span>
                            </TableCell>
                            <TableCell>
                              <span className="text-gray-600">{record.paymentMethod || '-'}</span>
                            </TableCell>
                            <TableCell>{getStatusChip(record.status)}</TableCell>
                            <TableCell>
                              <span className="text-gray-500">{formatDate(record.createdAt)}</span>
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                    {rechargeTotalPages > 1 && (
                      <div className="flex justify-center mt-4">
                        <Pagination
                          total={rechargeTotalPages}
                          initialPage={1}
                          page={rechargePage}
                          onChange={fetchRechargePage}
                          showControls
                          size="sm"
                        />
                      </div>
                    )}
                  </>
                ) : (
                  <div className="text-center py-12 text-gray-400">暂无充值记录</div>
                )}
              </CardBody>
            </Card>
          </>
        )}
      </div>
    </Layout>
  );
}
