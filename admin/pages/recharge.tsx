import { useState, useEffect } from 'react';
import Layout from '../components/Layout';
import { paymentAPI } from '../services/api';

interface RechargeRecord {
  id: string;
  amount: number;
  paymentMethod: string;
  status: string;
  description: string;
  createdAt: string;
  paidAt: string | null;
}

export default function RechargePage() {
  const [records, setRecords] = useState<RechargeRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [amount, setAmount] = useState(1000); // 默认10元
  const [paymentMethod, setPaymentMethod] = useState('wechat');
  const [creating, setCreating] = useState(false);

  useEffect(() => {
    fetchRecords();
  }, []);

  const fetchRecords = async () => {
    try {
      const response = await paymentAPI.getRechargeRecords();
      setRecords(response.data?.records || []);
    } catch (err: any) {
      setError(err.message || '获取充值记录失败');
    } finally {
      setLoading(false);
    }
  };

  const handleRecharge = async () => {
    setCreating(true);
    try {
      const response = await paymentAPI.createRechargeOrder({
        amount,
        paymentMethod,
      });
      alert('订单创建成功！订单号: ' + response.data?.orderId);
      fetchRecords();
    } catch (err: any) {
      alert('创建订单失败: ' + (err.message || '未知错误'));
    } finally {
      setCreating(false);
    }
  };

  if (loading) {
    return (
      <Layout currentPage="recharge">
        <div className="flex items-center justify-center h-64">
          <div className="text-lg">加载中...</div>
        </div>
      </Layout>
    );
  }

  return (
    <Layout currentPage="recharge">
      <div className="space-y-6 p-6">
        <h1 className="text-2xl font-bold">充值中心</h1>

        {/* 充值表单 */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-lg font-semibold mb-4">创建充值订单</h2>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-1">充值金额</label>
              <div className="flex gap-2">
                {[10, 50, 100, 200, 500].map((amt) => (
                  <button
                    key={amt}
                    onClick={() => setAmount(amt * 100)}
                    className={`px-4 py-2 rounded border ${
                      amount === amt * 100
                        ? 'bg-blue-500 text-white border-blue-500'
                        : 'bg-white text-gray-700 border-gray-300 hover:border-blue-500'
                    }`}
                  >
                    {amt}元
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium mb-1">支付方式</label>
              <div className="flex gap-2">
                <button
                  onClick={() => setPaymentMethod('wechat')}
                  className={`px-4 py-2 rounded border ${
                    paymentMethod === 'wechat'
                      ? 'bg-green-500 text-white border-green-500'
                      : 'bg-white text-gray-700 border-gray-300'
                  }`}
                >
                  微信支付
                </button>
                <button
                  onClick={() => setPaymentMethod('alipay')}
                  className={`px-4 py-2 rounded border ${
                    paymentMethod === 'alipay'
                      ? 'bg-blue-500 text-white border-blue-500'
                      : 'bg-white text-gray-700 border-gray-300'
                  }`}
                >
                  支付宝
                </button>
              </div>
            </div>

            <button
              onClick={handleRecharge}
              disabled={creating}
              className="w-full py-3 bg-blue-500 text-white rounded-lg hover:bg-blue-600 disabled:bg-gray-400"
            >
              {creating ? '创建中...' : `立即充值 ${amount / 100} 元`}
            </button>
          </div>
        </div>

        {/* 充值记录 */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-lg font-semibold mb-4">充值记录</h2>
          {records.length === 0 ? (
            <div className="text-gray-500 text-center py-4">暂无充值记录</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-2">订单号</th>
                    <th className="text-left py-2">金额</th>
                    <th className="text-left py-2">支付方式</th>
                    <th className="text-left py-2">状态</th>
                    <th className="text-left py-2">时间</th>
                  </tr>
                </thead>
                <tbody>
                  {records.map((record) => (
                    <tr key={record.id} className="border-b">
                      <td className="py-2">{record.id}</td>
                      <td className="py-2">{(record.amount / 100).toFixed(2)}元</td>
                      <td className="py-2">
                        {record.paymentMethod === 'wechat' ? '微信支付' : '支付宝'}
                      </td>
                      <td className="py-2">
                        <span
                          className={`px-2 py-1 rounded text-sm ${
                            record.status === 'success'
                              ? 'bg-green-100 text-green-800'
                              : record.status === 'pending'
                              ? 'bg-yellow-100 text-yellow-800'
                              : 'bg-red-100 text-red-800'
                          }`}
                        >
                          {record.status === 'success'
                            ? '成功'
                            : record.status === 'pending'
                            ? '待支付'
                            : '失败'}
                        </span>
                      </td>
                      <td className="py-2">
                        {new Date(record.createdAt).toLocaleString()}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </Layout>
  );
}
