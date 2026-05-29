import { useState, useEffect } from 'react';
import Layout from '../components/Layout';
import { adminAPI } from '../services/api';
import { Card, CardBody, Button, Input, Table, TableHeader, TableColumn, TableBody, TableRow, TableCell, Chip } from '@nextui-org/react';
import { Search, TrendingUp, TrendingDown, DollarSign, Package, Users, Calculator } from 'lucide-react';

interface RevenueStats {
  totalRevenue: number;
  totalOrders: number;
  totalCost: number;
  totalProfit: number;
  profitMargin: number;
  byPaymentMethod: Array<{
    method: string;
    amount: number;
    count: number;
  }>;
  byDay: Array<{
    date: string;
    amount: number;
    cost: number;
    profit: number;
    count: number;
  }>;
  byPlan: Array<{
    planId: string;
    planName: string;
    revenue: number;
    cost: number;
    profit: number;
    orders: number;
  }>;
}

export default function RevenuePage() {
  const [stats, setStats] = useState<RevenueStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const response = await adminAPI.getRevenueStats(startDate, endDate);
      setStats(response.data);
    } catch (err: any) {
      setError(err.message || '获取收入统计失败');
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = () => {
    setLoading(true);
    fetchStats();
  };

  if (loading) {
    return (
      <Layout currentPage="revenue">
        <div className="flex items-center justify-center h-64">
          <div className="text-lg">加载中...</div>
        </div>
      </Layout>
    );
  }

  if (error) {
    return (
      <Layout currentPage="revenue">
        <div className="text-red-500 p-4">{error}</div>
      </Layout>
    );
  }

  return (
    <Layout currentPage="revenue">
      <div className="space-y-6 p-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-800">收益分析报表</h1>
            <p className="text-gray-500 mt-1">收入、成本、毛利综合分析</p>
          </div>
        </div>

        {/* 筛选 */}
        <Card className="shadow-sm">
          <CardBody className="flex gap-4 items-end">
            <div>
              <label className="block text-sm font-medium mb-1">开始日期</label>
              <Input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                classNames={{ inputWrapper: 'rounded-xl' }}
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">结束日期</label>
              <Input
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                classNames={{ inputWrapper: 'rounded-xl' }}
              />
            </div>
            <Button
              color="primary"
              className="bg-blue-600"
              onClick={handleSearch}
              startContent={<Search className="w-4 h-4" />}
            >
              查询
            </Button>
          </CardBody>
        </Card>

        {/* 核心指标 - 4列 */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card className="shadow-sm">
            <CardBody>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
                  <DollarSign className="w-5 h-5 text-blue-600" />
                </div>
                <div>
                  <div className="text-sm text-gray-500">总收入</div>
                  <div className="text-2xl font-bold text-gray-800">
                    ¥{((stats?.totalRevenue || 0) / 100).toFixed(2)}
                  </div>
                </div>
              </div>
            </CardBody>
          </Card>

          <Card className="shadow-sm">
            <CardBody>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-red-50 flex items-center justify-center">
                  <TrendingDown className="w-5 h-5 text-red-600" />
                </div>
                <div>
                  <div className="text-sm text-gray-500">总成本</div>
                  <div className="text-2xl font-bold text-gray-800">
                    ¥{((stats?.totalCost || 0) / 100).toFixed(2)}
                  </div>
                </div>
              </div>
            </CardBody>
          </Card>

          <Card className="shadow-sm">
            <CardBody>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-green-50 flex items-center justify-center">
                  <TrendingUp className="w-5 h-5 text-green-600" />
                </div>
                <div>
                  <div className="text-sm text-gray-500">毛利</div>
                  <div className="text-2xl font-bold text-gray-800">
                    ¥{((stats?.totalProfit || 0) / 100).toFixed(2)}
                  </div>
                </div>
              </div>
            </CardBody>
          </Card>

          <Card className="shadow-sm">
            <CardBody>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-purple-50 flex items-center justify-center">
                  <Calculator className="w-5 h-5 text-purple-600" />
                </div>
                <div>
                  <div className="text-sm text-gray-500">毛利率</div>
                  <div className="text-2xl font-bold text-gray-800">
                    {stats?.profitMargin?.toFixed(1) || 0}%
                  </div>
                </div>
              </div>
            </CardBody>
          </Card>
        </div>

        {/* 套餐收益分析 */}
        <Card className="shadow-sm">
          <CardBody>
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
                <Package className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-800">套餐收益分析</h2>
                <p className="text-sm text-gray-500">各套餐的收入、成本、毛利对比</p>
              </div>
            </div>
            {stats?.byPlan && stats.byPlan.length > 0 ? (
              <Table>
                <TableHeader>
                  <TableColumn>套餐名称</TableColumn>
                  <TableColumn>订单数</TableColumn>
                  <TableColumn>收入</TableColumn>
                  <TableColumn>成本</TableColumn>
                  <TableColumn>毛利</TableColumn>
                  <TableColumn>毛利率</TableColumn>
                </TableHeader>
                <TableBody>
                  {stats.byPlan.map((item) => (
                    <TableRow key={item.planId}>
                      <TableCell className="font-medium">{item.planName}</TableCell>
                      <TableCell>{item.orders}</TableCell>
                      <TableCell className="text-blue-600">¥{(item.revenue / 100).toFixed(2)}</TableCell>
                      <TableCell className="text-red-500">¥{(item.cost / 100).toFixed(2)}</TableCell>
                      <TableCell className="text-green-600 font-medium">¥{(item.profit / 100).toFixed(2)}</TableCell>
                      <TableCell>
                        <Chip
                          size="sm"
                          className={
                            (item.profit / item.revenue * 100) > 40
                              ? 'bg-green-100 text-green-700'
                              : (item.profit / item.revenue * 100) > 20
                              ? 'bg-yellow-100 text-yellow-700'
                              : 'bg-red-100 text-red-700'
                          }
                        >
                          {(item.profit / item.revenue * 100).toFixed(1)}%
                        </Chip>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            ) : (
              <div className="text-gray-500 text-center py-4">暂无数据</div>
            )}
          </CardBody>
        </Card>

        {/* 支付方式分布 */}
        <Card className="shadow-sm">
          <CardBody>
            <h2 className="text-lg font-semibold text-gray-800 mb-4">支付方式分布</h2>
            {stats?.byPaymentMethod && stats.byPaymentMethod.length > 0 ? (
              <Table>
                <TableHeader>
                  <TableColumn>支付方式</TableColumn>
                  <TableColumn>金额</TableColumn>
                  <TableColumn>订单数</TableColumn>
                </TableHeader>
                <TableBody>
                  {stats.byPaymentMethod.map((item) => (
                    <TableRow key={item.method}>
                      <TableCell>
                        {item.method === 'wechat' ? '微信支付' :
                         item.method === 'alipay' ? '支付宝' : item.method}
                      </TableCell>
                      <TableCell>¥{(item.amount / 100).toFixed(2)}</TableCell>
                      <TableCell>{item.count}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            ) : (
              <div className="text-gray-500 text-center py-4">暂无数据</div>
            )}
          </CardBody>
        </Card>

        {/* 每日收益 */}
        <Card className="shadow-sm">
          <CardBody>
            <h2 className="text-lg font-semibold text-gray-800 mb-4">每日收益</h2>
            {stats?.byDay && stats.byDay.length > 0 ? (
              <Table>
                <TableHeader>
                  <TableColumn>日期</TableColumn>
                  <TableColumn>收入</TableColumn>
                  <TableColumn>成本</TableColumn>
                  <TableColumn>毛利</TableColumn>
                  <TableColumn>订单数</TableColumn>
                </TableHeader>
                <TableBody>
                  {stats.byDay.map((item) => (
                    <TableRow key={item.date}>
                      <TableCell>{item.date}</TableCell>
                      <TableCell className="text-blue-600">¥{(item.amount / 100).toFixed(2)}</TableCell>
                      <TableCell className="text-red-500">¥{(item.cost / 100).toFixed(2)}</TableCell>
                      <TableCell className="text-green-600 font-medium">¥{(item.profit / 100).toFixed(2)}</TableCell>
                      <TableCell>{item.count}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            ) : (
              <div className="text-gray-500 text-center py-4">暂无数据</div>
            )}
          </CardBody>
        </Card>
      </div>
    </Layout>
  );
}
