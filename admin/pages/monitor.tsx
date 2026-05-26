import { useState, useEffect } from 'react';
import { Layout } from '../components/layout';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';
import { monitorAPI } from '../services/api';

interface MetricsData {
  totalCalls: number;
  totalTokens: number;
  totalQuotaConsumed: number;
  avgResponseTime: number;
  errorRate: number;
  callsByProvider: Record<string, number>;
  callsByHour: Record<string, number>;
}

export default function MonitorPage() {
  const [metrics, setMetrics] = useState<MetricsData | null>(null);
  const [trendData, setTrendData] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchMetrics();
    const interval = setInterval(fetchMetrics, 30000); // 每30秒刷新
    return () => clearInterval(interval);
  }, []);

  const fetchMetrics = async () => {
    try {
      const [realtimeRes, trendRes] = await Promise.all([
        monitorAPI.getRealtimeMetrics(),
        monitorAPI.getTrendData(),
      ]);
      setMetrics(realtimeRes.data);
      setTrendData(trendRes.data);
    } catch (err: any) {
      setError(err.message || '获取监控数据失败');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center h-64">
          <div className="text-lg">加载中...</div>
        </div>
      </Layout>
    );
  }

  if (error) {
    return (
      <Layout>
        <div className="text-red-500 p-4">{error}</div>
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="space-y-6">
        <h1 className="text-2xl font-bold">API 监控仪表盘</h1>

        {/* 核心指标卡片 */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium">近1小时调用量</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{metrics?.totalCalls || 0}</div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium">Token 消耗</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{metrics?.totalTokens?.toLocaleString() || 0}</div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium">配额消耗</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{metrics?.totalQuotaConsumed || 0}</div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium">错误率</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{metrics?.errorRate || 0}%</div>
            </CardContent>
          </Card>
        </div>

        {/* Provider 分布 */}
        <Card>
          <CardHeader>
            <CardTitle>Provider 调用分布</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {metrics?.callsByProvider && Object.entries(metrics.callsByProvider).map(([provider, count]) => (
                <div key={provider} className="flex items-center justify-between">
                  <span className="capitalize">{provider}</span>
                  <div className="flex items-center gap-2">
                    <div className="w-32 h-2 bg-gray-200 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-blue-500"
                        style={{
                          width: `${metrics.totalCalls > 0 ? (count / metrics.totalCalls) * 100 : 0}%`,
                        }}
                      />
                    </div>
                    <span className="text-sm text-gray-500">{count}</span>
                  </div>
                </div>
              ))}
              {(!metrics?.callsByProvider || Object.keys(metrics.callsByProvider).length === 0) && (
                <div className="text-gray-500 text-center py-4">暂无数据</div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* 7天趋势 */}
        <Card>
          <CardHeader>
            <CardTitle>7天调用趋势</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {trendData.map((day) => (
                <div key={day.date} className="flex items-center justify-between py-2 border-b">
                  <span>{day.date}</span>
                  <div className="flex gap-4 text-sm">
                    <span>调用: {day.totalCalls}</span>
                    <span>Token: {day.totalTokens?.toLocaleString()}</span>
                    <span>配额: {day.totalQuotaConsumed}</span>
                  </div>
                </div>
              ))}
              {trendData.length === 0 && (
                <div className="text-gray-500 text-center py-4">暂无数据</div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </Layout>
  );
}
