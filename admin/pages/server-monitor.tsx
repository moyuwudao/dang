'use client';

import { useEffect, useState } from 'react';
import { Card, CardBody, Button, Badge, Spinner, Textarea, Select, SelectItem } from '@nextui-org/react';
import { Server, Cpu, HardDrive, MemoryStick, Clock, Activity, RefreshCw, Terminal, FileText } from 'lucide-react';
import Layout from '@/components/Layout';
import { monitorAPI } from '@/services/api';
import type { SystemInfo, ServiceStatus } from '@/types';

const LOG_SERVICES = [
  { value: 'nginx', label: 'Nginx' },
  { value: 'system', label: 'System' },
  { value: 'postgresql', label: 'PostgreSQL' },
  { value: 'redis', label: 'Redis' },
  { value: 'ssh', label: 'SSH' },
  { value: 'agent', label: 'Agent' },
];

// 模拟数据，用于演示
const MOCK_SYSTEM_INFO: SystemInfo = {
  hostname: 'changji-server',
  platform: 'linux',
  uptime: 86400 * 3 + 3600 * 5 + 1800,
  cpu: { usage: 23.5, cores: 4, model: 'Intel Xeon' },
  memory: { total: 8589934592, used: 4294967296, free: 4294967296, usagePercent: 50 },
  disk: { total: 107374182400, used: 21474836480, free: 85899345920, usagePercent: 20 },
  load: [0.5, 0.3, 0.2],
  timestamp: new Date().toISOString(),
};

const MOCK_SERVICES: ServiceStatus[] = [
  { name: 'nginx', status: 'active', active: true },
  { name: 'changji-api', status: 'active', active: true },
  { name: 'postgresql', status: 'active', active: true },
  { name: 'redis', status: 'active', active: true },
  { name: 'ssh', status: 'active', active: true },
];

const QUICK_COMMANDS = [
  { label: 'PM2状态', command: 'pm2 status changji-api', icon: '📊' },
  { label: 'Nginx状态', command: 'systemctl status nginx --no-pager -l', icon: '📊' },
  { label: 'PM2列表', command: 'pm2 list', icon: '📋' },
  { label: 'PM2日志', command: 'pm2 logs changji-api --lines 50 --nostream', icon: '📄' },
  { label: '磁盘空间', command: 'df -h', icon: '💾' },
  { label: '内存使用', command: 'free -h', icon: '🧠' },
  { label: '端口监听', command: 'ss -tlnp', icon: '🔌' },
  { label: '最近登录', command: 'last -10', icon: '🔐' },
  { label: '系统负载', command: 'uptime', icon: '⚡' },
  { label: '进程Top10', command: 'ps aux --sort=-%mem | head -11', icon: '📈' },
];

export default function ServerMonitorPage() {
  const [systemInfo, setSystemInfo] = useState<SystemInfo | null>(null);
  const [services, setServices] = useState<ServiceStatus[]>([]);
  const [logs, setLogs] = useState('');
  const [selectedService, setSelectedService] = useState('nginx');
  const [logLines, setLogLines] = useState(100);
  const [command, setCommand] = useState('');
  const [commandOutput, setCommandOutput] = useState('');
  const [loading, setLoading] = useState(true);
  const [logsLoading, setLogsLoading] = useState(false);
  const [commandLoading, setCommandLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      const [systemRes, servicesRes] = await Promise.all([
        monitorAPI.getSystemInfo().catch(() => MOCK_SYSTEM_INFO),
        monitorAPI.getServices().catch(() => MOCK_SERVICES),
      ]);
      setSystemInfo(systemRes);
      setServices(servicesRes);
    } catch (err: any) {
      setError(err.response?.data?.message || '加载数据失败');
      // 使用模拟数据作为后备
      setSystemInfo(MOCK_SYSTEM_INFO);
      setServices(MOCK_SERVICES);
    } finally {
      setLoading(false);
    }
  };

  const fetchLogs = async () => {
    setLogsLoading(true);
    try {
      const res: any = await monitorAPI.getLogs(selectedService, logLines);
      setLogs(res.logs || res || '暂无日志数据');
    } catch (err: any) {
      setLogs('获取日志失败: ' + (err.response?.data?.message || err.message || '未知错误'));
    } finally {
      setLogsLoading(false);
    }
  };

  const executeCommand = async () => {
    if (!command.trim()) return;
    setCommandLoading(true);
    setCommandOutput('');
    try {
      const res = await monitorAPI.executeCommand(command, 30);
      setCommandOutput(res.output || '命令执行完成，无输出');
    } catch (err: any) {
      setCommandOutput('执行命令失败: ' + (err.response?.data?.message || err.message || '未知错误'));
    } finally {
      setCommandLoading(false);
    }
  };

  const executeCommandWithCmd = async (cmd: string) => {
    setCommandLoading(true);
    setCommandOutput('');
    try {
      const res = await monitorAPI.executeCommand(cmd, 30);
      setCommandOutput(res.output);
    } catch (err: any) {
      setCommandOutput(err.response?.data?.message || '执行命令失败');
    } finally {
      setCommandLoading(false);
    }
  };

  const formatBytes = (bytes: number) => {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const formatUptime = (seconds: number) => {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    if (days > 0) return `${days}天 ${hours}小时`;
    if (hours > 0) return `${hours}小时 ${minutes}分钟`;
    return `${minutes}分钟`;
  };

  return (
    <Layout currentPage="server-monitor">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-semibold text-gray-900">服务器监控</h1>
            <p className="text-sm text-gray-500 mt-1">实时查看服务器状态、日志和服务</p>
          </div>
          <Button size="sm" variant="light" onClick={fetchData} isLoading={loading}>
            <RefreshCw className="w-4 h-4 mr-1.5" />
            刷新
          </Button>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
            {error}
          </div>
        )}

        {/* System Overview */}
        {systemInfo && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <Card className="bg-white border border-gray-100">
              <CardBody className="p-5">
                <div className="flex items-start justify-between">
                  <div className="space-y-2">
                    <p className="text-sm text-gray-500 font-medium">CPU 使用率</p>
                    <p className="text-2xl font-semibold text-gray-900">{systemInfo.cpu?.usage?.toFixed(1)}%</p>
                    <p className="text-xs text-gray-400">{systemInfo.cpu?.cores} 核 · {systemInfo.cpu?.model}</p>
                  </div>
                  <div className="w-12 h-12 rounded-lg bg-blue-50 flex items-center justify-center">
                    <Cpu className="w-6 h-6 text-blue-600" />
                  </div>
                </div>
              </CardBody>
            </Card>

            <Card className="bg-white border border-gray-100">
              <CardBody className="p-5">
                <div className="flex items-start justify-between">
                  <div className="space-y-2">
                    <p className="text-sm text-gray-500 font-medium">内存使用</p>
                    <p className="text-2xl font-semibold text-gray-900">{systemInfo.memory?.usagePercent?.toFixed(1)}%</p>
                    <p className="text-xs text-gray-400">
                      {formatBytes(systemInfo.memory?.used || 0)} / {formatBytes(systemInfo.memory?.total || 0)}
                    </p>
                  </div>
                  <div className="w-12 h-12 rounded-lg bg-blue-50 flex items-center justify-center">
                    <MemoryStick className="w-6 h-6 text-blue-600" />
                  </div>
                </div>
              </CardBody>
            </Card>

            <Card className="bg-white border border-gray-100">
              <CardBody className="p-5">
                <div className="flex items-start justify-between">
                  <div className="space-y-2">
                    <p className="text-sm text-gray-500 font-medium">磁盘使用</p>
                    <p className="text-2xl font-semibold text-gray-900">{systemInfo.disk?.usagePercent?.toFixed(1)}%</p>
                    <p className="text-xs text-gray-400">
                      {formatBytes(systemInfo.disk?.used || 0)} / {formatBytes(systemInfo.disk?.total || 0)}
                    </p>
                  </div>
                  <div className="w-12 h-12 rounded-lg bg-blue-50 flex items-center justify-center">
                    <HardDrive className="w-6 h-6 text-blue-600" />
                  </div>
                </div>
              </CardBody>
            </Card>

            <Card className="bg-white border border-gray-100">
              <CardBody className="p-5">
                <div className="flex items-start justify-between">
                  <div className="space-y-2">
                    <p className="text-sm text-gray-500 font-medium">运行时间</p>
                    <p className="text-2xl font-semibold text-gray-900">{formatUptime(systemInfo.uptime || 0)}</p>
                    <p className="text-xs text-gray-400">{systemInfo.hostname} · {systemInfo.platform}</p>
                  </div>
                  <div className="w-12 h-12 rounded-lg bg-blue-50 flex items-center justify-center">
                    <Clock className="w-6 h-6 text-blue-600" />
                  </div>
                </div>
              </CardBody>
            </Card>
          </div>
        )}

        {/* Services Status */}
        <Card className="bg-white border border-gray-100">
          <CardBody className="p-5">
            <h2 className="text-base font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <Activity className="w-5 h-5 text-blue-600" />
              服务状态
            </h2>
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
              {loading && !services.length ? (
                <div className="col-span-full h-20 flex items-center justify-center">
                  <Spinner size="sm" />
                </div>
              ) : (
                services.map((service) => (
                  <div key={service.name} className="flex items-center gap-2 px-3 py-2 bg-gray-50 rounded-lg">
                    <div className={`w-2 h-2 rounded-full ${service.active ? 'bg-green-500' : 'bg-red-500'}`} />
                    <span className="text-sm font-medium text-gray-900">{service.name}</span>
                    <Badge variant="flat" className={service.active ? 'bg-green-50 text-green-700 ml-auto' : 'bg-red-50 text-red-700 ml-auto'}>
                      {service.status}
                    </Badge>
                  </div>
                ))
              )}
            </div>
          </CardBody>
        </Card>

        {/* Logs */}
        <Card className="bg-white border border-gray-100">
          <CardBody className="p-5">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-base font-semibold text-gray-900 flex items-center gap-2">
                <FileText className="w-5 h-5 text-blue-600" />
                日志查看
              </h2>
              <div className="flex items-center gap-2">
                <Select
                  size="sm"
                  selectedKeys={[selectedService]}
                  onSelectionChange={(keys) => setSelectedService(Array.from(keys)[0] as string)}
                  className="w-32"
                >
                  {LOG_SERVICES.map((s) => (
                    <SelectItem key={s.value} value={s.value}>
                      {s.label}
                    </SelectItem>
                  ))}
                </Select>
                <Select
                  size="sm"
                  selectedKeys={[logLines.toString()]}
                  onSelectionChange={(keys) => setLogLines(parseInt(Array.from(keys)[0] as string))}
                  className="w-24"
                >
                  <SelectItem key="50" value="50">50行</SelectItem>
                  <SelectItem key="100" value="100">100行</SelectItem>
                  <SelectItem key="200" value="200">200行</SelectItem>
                  <SelectItem key="500" value="500">500行</SelectItem>
                </Select>
                <Button size="sm" color="primary" onClick={fetchLogs} isLoading={logsLoading}>
                  查看
                </Button>
              </div>
            </div>
            <Textarea
              value={logs}
              readOnly
              minRows={10}
              maxRows={20}
              className="font-mono text-xs bg-gray-900 text-gray-100"
              placeholder='选择服务并点击"查看"获取日志...'
            />
          </CardBody>
        </Card>

        {/* Command Execution */}
        <Card className="bg-white border border-gray-100">
          <CardBody className="p-5">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-base font-semibold text-gray-900 flex items-center gap-2">
                <Terminal className="w-5 h-5 text-blue-600" />
                命令执行
              </h2>
            </div>
            {/* Quick Commands */}
            <div className="mb-4">
              <p className="text-sm text-gray-500 mb-2">快捷命令</p>
              <div className="flex flex-wrap gap-2">
                {QUICK_COMMANDS.map((cmd) => (
                  <Button
                    key={cmd.label}
                    size="sm"
                    variant="flat"
                    className="bg-gray-50 hover:bg-blue-50 hover:text-blue-600 text-gray-700 border border-gray-200"
                    onClick={() => {
                      setCommand(cmd.command);
                      executeCommandWithCmd(cmd.command);
                    }}
                  >
                    <span className="mr-1">{cmd.icon}</span>
                    {cmd.label}
                  </Button>
                ))}
              </div>
            </div>
            <div className="flex gap-2 mb-3">
              <input
                type="text"
                value={command}
                onChange={(e) => setCommand(e.target.value)}
                placeholder="输入命令..."
                className="flex-1 px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                onKeyDown={(e) => e.key === 'Enter' && executeCommand()}
              />
              <Button size="sm" color="primary" onClick={executeCommand} isLoading={commandLoading}>
                执行
              </Button>
            </div>
            {commandOutput && (
              <Textarea
                value={commandOutput}
                readOnly
                minRows={5}
                maxRows={15}
                className="font-mono text-xs bg-gray-900 text-gray-100"
              />
            )}
          </CardBody>
        </Card>
      </div>
    </Layout>
  );
}
