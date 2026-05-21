'use client';

import { useState, useEffect } from 'react';
import { Card, CardBody, Button, Switch, Select, SelectItem, Spinner } from '@nextui-org/react';
import { Bell, Shield, Database, Globe, Save, Info, Download, Trash2, Server } from 'lucide-react';
import Layout from '@/components/Layout';
import { monitorAPI } from '@/services/api';

interface SettingsData {
  notifications: {
    email: boolean;
    push: boolean;
    marketing: boolean;
  };
  security: {
    twoFactor: boolean;
    sessionTimeout: number;
    ipWhitelist: boolean;
  };
  language: string;
  timezone: string;
}

const defaultSettings: SettingsData = {
  notifications: {
    email: true,
    push: true,
    marketing: false,
  },
  security: {
    twoFactor: false,
    sessionTimeout: 30,
    ipWhitelist: true,
  },
  language: 'zh-CN',
  timezone: 'Asia/Shanghai',
};

export default function SettingsPage() {
  const [settings, setSettings] = useState<SettingsData>(defaultSettings);
  const [systemInfo, setSystemInfo] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saveMessage, setSaveMessage] = useState('');

  useEffect(() => {
    // 从 localStorage 加载设置
    const saved = localStorage.getItem('adminSettings');
    if (saved) {
      try {
        setSettings(JSON.parse(saved));
      } catch {
        setSettings(defaultSettings);
      }
    }

    // 获取系统信息
    monitorAPI.getSystemInfo()
      .then(setSystemInfo)
      .catch(() => null)
      .finally(() => setLoading(false));
  }, []);

  const handleSave = () => {
    setSaving(true);
    localStorage.setItem('adminSettings', JSON.stringify(settings));
    setTimeout(() => {
      setSaving(false);
      setSaveMessage('设置已保存！');
      setTimeout(() => setSaveMessage(''), 3000);
    }, 500);
  };

  const updateNotifications = (key: keyof SettingsData['notifications'], value: boolean) => {
    setSettings(prev => ({
      ...prev,
      notifications: { ...prev.notifications, [key]: value },
    }));
  };

  const updateSecurity = (key: keyof SettingsData['security'], value: boolean | number) => {
    setSettings(prev => ({
      ...prev,
      security: { ...prev.security, [key]: value },
    }));
  };

  const handleExportData = () => {
    const data = {
      settings,
      exportTime: new Date().toISOString(),
    };
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `admin-settings-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleBackup = async () => {
    try {
      const res = await monitorAPI.executeCommand('cd /home/admin/dang && pg_dump -U appuser appdb > /tmp/backup.sql && echo "Backup completed"', 60);
      alert('数据库备份已创建：/tmp/backup.sql');
    } catch (err: any) {
      alert('备份失败：' + (err.response?.data?.message || err.message));
    }
  };

  return (
    <Layout currentPage="settings">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-semibold text-gray-900">系统设置</h1>
            <p className="text-sm text-gray-500 mt-1">配置系统参数和偏好设置</p>
          </div>
          <div className="flex items-center gap-3">
            {saveMessage && (
              <span className="text-sm text-green-600 font-medium">{saveMessage}</span>
            )}
            <Button
              color="primary"
              className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white"
              onClick={handleSave}
              isLoading={saving}
            >
              <Save className="w-4 h-4" />
              保存设置
            </Button>
          </div>
        </div>

        {/* Notification Settings */}
        <Card className="bg-white border border-gray-100">
          <CardBody className="p-6">
            <div className="flex items-center gap-4 mb-6">
              <div className="w-12 h-12 rounded-lg bg-blue-50 flex items-center justify-center">
                <Bell className="w-6 h-6 text-blue-600" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-800">通知设置</h2>
                <p className="text-sm text-gray-500">管理系统通知偏好</p>
              </div>
            </div>
            <div className="space-y-5">
              <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg border border-gray-100 hover:bg-gray-100 transition-colors">
                <div>
                  <p className="font-medium text-gray-800">邮件通知</p>
                  <p className="text-sm text-gray-500">接收重要更新和告警邮件</p>
                </div>
                <Switch
                  isSelected={settings.notifications.email}
                  onValueChange={(v) => updateNotifications('email', v)}
                  classNames={{ wrapper: 'group-data-[selected=true]:bg-blue-600' }}
                />
              </div>
              <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg border border-gray-100 hover:bg-gray-100 transition-colors">
                <div>
                  <p className="font-medium text-gray-800">推送通知</p>
                  <p className="text-sm text-gray-500">接收浏览器推送通知</p>
                </div>
                <Switch
                  isSelected={settings.notifications.push}
                  onValueChange={(v) => updateNotifications('push', v)}
                  classNames={{ wrapper: 'group-data-[selected=true]:bg-blue-600' }}
                />
              </div>
              <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg border border-gray-100 hover:bg-gray-100 transition-colors">
                <div>
                  <p className="font-medium text-gray-800">营销邮件</p>
                  <p className="text-sm text-gray-500">接收产品更新和促销信息</p>
                </div>
                <Switch
                  isSelected={settings.notifications.marketing}
                  onValueChange={(v) => updateNotifications('marketing', v)}
                  classNames={{ wrapper: 'group-data-[selected=true]:bg-blue-600' }}
                />
              </div>
            </div>
          </CardBody>
        </Card>

        {/* Security Settings */}
        <Card className="bg-white border border-gray-100">
          <CardBody className="p-6">
            <div className="flex items-center gap-4 mb-6">
              <div className="w-12 h-12 rounded-lg bg-blue-50 flex items-center justify-center">
                <Shield className="w-6 h-6 text-blue-600" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-800">安全设置</h2>
                <p className="text-sm text-gray-500">管理账户安全选项</p>
              </div>
            </div>
            <div className="space-y-5">
              <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg border border-gray-100 hover:bg-gray-100 transition-colors">
                <div>
                  <p className="font-medium text-gray-800">双因素认证</p>
                  <p className="text-sm text-gray-500">登录时需要额外验证</p>
                </div>
                <Switch
                  isSelected={settings.security.twoFactor}
                  onValueChange={(v) => updateSecurity('twoFactor', v)}
                  classNames={{ wrapper: 'group-data-[selected=true]:bg-blue-600' }}
                />
              </div>
              <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg border border-gray-100 hover:bg-gray-100 transition-colors">
                <div>
                  <p className="font-medium text-gray-800">IP白名单</p>
                  <p className="text-sm text-gray-500">只允许白名单IP访问管理后台</p>
                </div>
                <Switch
                  isSelected={settings.security.ipWhitelist}
                  onValueChange={(v) => updateSecurity('ipWhitelist', v)}
                  classNames={{ wrapper: 'group-data-[selected=true]:bg-blue-600' }}
                />
              </div>
              <div className="p-4 bg-gray-50 rounded-lg border border-gray-100">
                <p className="font-medium text-gray-800 mb-3">会话超时时间</p>
                <Select
                  label="超时时间"
                  selectedKeys={[String(settings.security.sessionTimeout)]}
                  onSelectionChange={(keys) => updateSecurity('sessionTimeout', parseInt(Array.from(keys)[0] as string))}
                  classNames={{ trigger: 'bg-white border border-gray-200 rounded-xl' }}
                >
                  <SelectItem key="15" value="15">15分钟</SelectItem>
                  <SelectItem key="30" value="30">30分钟</SelectItem>
                  <SelectItem key="60" value="60">1小时</SelectItem>
                  <SelectItem key="120" value="120">2小时</SelectItem>
                </Select>
              </div>
            </div>
          </CardBody>
        </Card>

        {/* Language & Region */}
        <Card className="bg-white border border-gray-100">
          <CardBody className="p-6">
            <div className="flex items-center gap-4 mb-6">
              <div className="w-12 h-12 rounded-lg bg-blue-50 flex items-center justify-center">
                <Globe className="w-6 h-6 text-blue-600" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-800">语言与地区</h2>
                <p className="text-sm text-gray-500">设置界面语言和时区</p>
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              <div className="p-4 bg-gray-50 rounded-lg border border-gray-100">
                <p className="font-medium text-gray-800 mb-3">语言</p>
                <Select
                  label="选择语言"
                  selectedKeys={[settings.language]}
                  onSelectionChange={(keys) => setSettings(prev => ({ ...prev, language: Array.from(keys)[0] as string }))}
                  classNames={{ trigger: 'bg-white border border-gray-200 rounded-xl' }}
                >
                  <SelectItem key="zh-CN" value="zh-CN">简体中文</SelectItem>
                  <SelectItem key="en-US" value="en-US">English</SelectItem>
                </Select>
              </div>
              <div className="p-4 bg-gray-50 rounded-lg border border-gray-100">
                <p className="font-medium text-gray-800 mb-3">时区</p>
                <Select
                  label="选择时区"
                  selectedKeys={[settings.timezone]}
                  onSelectionChange={(keys) => setSettings(prev => ({ ...prev, timezone: Array.from(keys)[0] as string }))}
                  classNames={{ trigger: 'bg-white border border-gray-200 rounded-xl' }}
                >
                  <SelectItem key="Asia/Shanghai" value="Asia/Shanghai">中国标准时间 (UTC+8)</SelectItem>
                  <SelectItem key="UTC" value="UTC">UTC (UTC+0)</SelectItem>
                </Select>
              </div>
            </div>
          </CardBody>
        </Card>

        {/* Data Management */}
        <Card className="bg-white border border-gray-100">
          <CardBody className="p-6">
            <div className="flex items-center gap-4 mb-6">
              <div className="w-12 h-12 rounded-lg bg-blue-50 flex items-center justify-center">
                <Database className="w-6 h-6 text-blue-600" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-800">数据管理</h2>
                <p className="text-sm text-gray-500">管理数据备份和清理</p>
              </div>
            </div>
            <div className="space-y-3">
              <Button
                variant="bordered"
                className="w-full justify-start h-12 text-left bg-gray-50 border-gray-200 hover:bg-gray-100 rounded-xl"
                onClick={handleExportData}
              >
                <span className="flex items-center gap-3">
                  <Download className="w-5 h-5 text-blue-500" />
                  <span className="font-medium">导出设置数据</span>
                </span>
              </Button>
              <Button
                variant="bordered"
                className="w-full justify-start h-12 text-left bg-gray-50 border-gray-200 hover:bg-gray-100 rounded-xl"
                onClick={handleBackup}
              >
                <span className="flex items-center gap-3">
                  <Database className="w-5 h-5 text-green-500" />
                  <span className="font-medium">创建数据库备份</span>
                </span>
              </Button>
            </div>
          </CardBody>
        </Card>

        {/* System Info */}
        <Card className="bg-white border border-gray-100">
          <CardBody className="p-6">
            <div className="flex items-center gap-4 mb-5">
              <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
                <Info className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-800">系统信息</h2>
                <p className="text-sm text-gray-500">当前系统运行状态</p>
              </div>
            </div>
            {loading ? (
              <div className="h-20 flex items-center justify-center">
                <Spinner size="sm" />
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="p-4 bg-gray-50 rounded-lg border border-gray-100">
                  <p className="text-sm text-gray-500">主机名</p>
                  <p className="font-semibold text-gray-800">{systemInfo?.hostname || '-'}</p>
                </div>
                <div className="p-4 bg-gray-50 rounded-lg border border-gray-100">
                  <p className="text-sm text-gray-500">操作系统</p>
                  <p className="font-semibold text-gray-800">{systemInfo?.platform || '-'}</p>
                </div>
                <div className="p-4 bg-gray-50 rounded-lg border border-gray-100">
                  <p className="text-sm text-gray-500">CPU 核心数</p>
                  <p className="font-semibold text-gray-800">{systemInfo?.cpu?.cores || '-'} 核</p>
                </div>
                <div className="p-4 bg-gray-50 rounded-lg border border-gray-100">
                  <p className="text-sm text-gray-500">服务器状态</p>
                  <p className="font-semibold text-green-600 flex items-center gap-2">
                    <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>
                    运行正常
                  </p>
                </div>
              </div>
            )}
          </CardBody>
        </Card>
      </div>
    </Layout>
  );
}
