import { useState, useEffect } from 'react';
import Layout from '../components/Layout';
import { adminAPI } from '../services/api';

interface RevenueStats {
  totalRevenue: number;
  totalOrders: number;
  byPaymentMethod: Array<{
    method: string;
    amount: number;
    count: number;
  }>;
  byDay: Array<{
    date: string;
    amount: number;
    count: number;
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
        <h1 className="text-2xl font-bold">收入统计报表</h1>

        {/* 筛选 */}
        <div className="bg-white rounded-lg shadow p-4 flex gap-4 items-end">
          <div>
            <label className="block text-sm font-medium mb-1">开始日期</label>
            <input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className="border rounded px-3 py-2"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">结束日期</label>
            <input
              type="date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              className="border rounded px-3 py-2"
            />
          </div>
          <button
            onClick={handleSearch}
            className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
          >
            查询
          </button>
        </div>

        {/* 核心指标 */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="bg-white rounded-lg shadow p-4">
            <div className="text-sm text-gray-500 mb-1">总收入</div>
            <div className="text-2xl font-bold">
              ¥{(stats?.totalRevenue || 0) / 100}
            </div>
          </div>
          <div className="bg-white rounded-lg shadow p-4">
            <div className="text-sm text-gray-500 mb-1">总订单数</div>
            <div className="text-2xl font-bold">{stats?.totalOrders || 0}</div>
          </div>
        </div>

        {/* 支付方式分布 */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-lg font-semibold mb-4">支付方式分布</h2>
          {stats?.byPaymentMethod && stats.byPaymentMethod.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="min-w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-2">支付方式</th>
                    <th className="text-left py-2">金额</th>
                    <th className="text-left py-2">订单数</th>
                  </tr>
                </thead>
                <tbody>
                  {stats.byPaymentMethod.map((item) => (
                    <tr key={item.method} className="border-b">
                      <td className="py-2">
                        {item.method === 'wechat' ? '微信支付' : 
                         item.method === 'alipay' ? '支付宝' : item.method}
                      </td>
                      <td className="py-2">¥{item.amount / 100}</td>
                      <td className="py-2">{item.count}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="text-gray-500 text-center py-4">暂无数据</div>
          )}
        </div>

        {/* 每日收入 */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-lg font-semibold mb-4">每日收入</h2>
          {stats?.byDay && stats.byDay.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="min-w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-2">日期</th>
                    <th className="text-left py-2">金额</th>
                    <th className="text-left py-2">订单数</th>
                  </tr>
                </thead>
                <tbody>
                  {stats.byDay.map((item) => (
                    <tr key={item.date} className="border-b">
                      <td className="py-2">{item.date}</td>
                      <td className="py-2">¥{item.amount / 100}</td>
                      <td className="py-2">{item.count}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="text-gray-500 text-center py-4">暂无数据</div>
          )}
        </div>
      </div>
    </Layout>
  );
}
