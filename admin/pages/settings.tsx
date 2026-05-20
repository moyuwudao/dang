'use client';

import { useState } from 'react';
import { Card, CardBody, Button, Switch, Select, SelectItem } from '@nextui-org/react';
import { Bell, Shield, Database, Globe, Save, Sparkles, Info, Download, Trash2 } from 'lucide-react';
import Layout from '@/components/Layout';

export default function SettingsPage() {
  const [notifications, setNotifications] = useState({
    email: true,
    push: true,
    marketing: false,
  });

  const [security, setSecurity] = useState({
    twoFactor: false,
    sessionTimeout: 30,
    ipWhitelist: true,
  });

  const [language, setLanguage] = useState('zh-CN');
  const [timezone, setTimezone] = useState('Asia/Shanghai');

  const handleSave = () => {
    alert('设置已保存！');
  };

  return (
    <Layout currentPage="settings">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent">系统设置</h1>
            <p className="text-gray-500 mt-1">配置系统参数和偏好设置</p>
          </div>
          <Button color="primary" className="flex items-center gap-2 bg-gradient-to-r from-indigo-500 to-purple-500 shadow-lg shadow-indigo-500/30" onClick={handleSave}>
            <Save className="w-4 h-4" />
            保存设置
          </Button>
        </div>

        {/* Notification Settings */}
        <Card className="bg-white/80 backdrop-blur-sm border border-indigo-100/50">
          <CardBody className="p-6">
            <div className="flex items-center gap-4 mb-6">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-500 to-indigo-500 flex items-center justify-center shadow-lg">
                <Bell className="w-6 h-6 text-white" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-800">通知设置</h2>
                <p className="text-sm text-gray-500">管理系统通知偏好</p>
              </div>
            </div>
            <div className="space-y-5">
              <div className="flex items-center justify-between p-4 bg-gradient-to-r from-blue-50/50 to-indigo-50/50 rounded-xl border border-blue-100/30">
                <div>
                  <p className="font-medium text-gray-800">邮件通知</p>
                  <p className="text-sm text-gray-500">接收重要更新和告警邮件</p>
                </div>
                <Switch isSelected={notifications.email} onValueChange={(value) => setNotifications({ ...notifications, email: value })} classNames={{ wrapper: 'group-data-[selected=true]:bg-indigo-500' }} />
              </div>
              <div className="flex items-center justify-between p-4 bg-gradient-to-r from-purple-50/50 to-pink-50/50 rounded-xl border border-purple-100/30">
                <div>
                  <p className="font-medium text-gray-800">推送通知</p>
                  <p className="text-sm text-gray-500">接收浏览器推送通知</p>
                </div>
                <Switch isSelected={notifications.push} onValueChange={(value) => setNotifications({ ...notifications, push: value })} classNames={{ wrapper: 'group-data-[selected=true]:bg-indigo-500' }} />
              </div>
              <div className="flex items-center justify-between p-4 bg-gradient-to-r from-gray-50/50 to-gray-50/50 rounded-xl border border-gray-100/30">
                <div>
                  <p className="font-medium text-gray-800">营销邮件</p>
                  <p className="text-sm text-gray-500">接收产品更新和促销信息</p>
                </div>
                <Switch isSelected={notifications.marketing} onValueChange={(value) => setNotifications({ ...notifications, marketing: value })} classNames={{ wrapper: 'group-data-[selected=true]:bg-indigo-500' }} />
              </div>
            </div>
          </CardBody>
        </Card>

        {/* Security Settings */}
        <Card className="bg-white/80 backdrop-blur-sm border border-indigo-100/50">
          <CardBody className="p-6">
            <div className="flex items-center gap-4 mb-6">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-green-500 to-emerald-500 flex items-center justify-center shadow-lg">
                <Shield className="w-6 h-6 text-white" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-800">安全设置</h2>
                <p className="text-sm text-gray-500">管理账户安全选项</p>
              </div>
            </div>
            <div className="space-y-5">
              <div className="flex items-center justify-between p-4 bg-gradient-to-r from-green-50/50 to-emerald-50/50 rounded-xl border border-green-100/30">
                <div>
                  <p className="font-medium text-gray-800">双因素认证</p>
                  <p className="text-sm text-gray-500">登录时需要额外验证</p>
                </div>
                <Switch isSelected={security.twoFactor} onValueChange={(value) => setSecurity({ ...security, twoFactor: value })} classNames={{ wrapper: 'group-data-[selected=true]:bg-indigo-500' }} />
              </div>
              <div className="flex items-center justify-between p-4 bg-gradient-to-r from-emerald-50/50 to-teal-50/50 rounded-xl border border-emerald-100/30">
                <div>
                  <p className="font-medium text-gray-800">IP白名单</p>
                  <p className="text-sm text-gray-500">只允许白名单IP访问管理后台</p>
                </div>
                <Switch isSelected={security.ipWhitelist} onValueChange={(value) => setSecurity({ ...security, ipWhitelist: value })} classNames={{ wrapper: 'group-data-[selected=true]:bg-indigo-500' }} />
              </div>
              <div className="p-4 bg-gradient-to-r from-teal-50/50 to-cyan-50/50 rounded-xl border border-teal-100/30">
                <p className="font-medium text-gray-800 mb-3">会话超时时间</p>
                <Select label="超时时间" value={String(security.sessionTimeout)} onChange={(e) => setSecurity({ ...security, sessionTimeout: parseInt(e.target.value) })} classNames={{ trigger: 'bg-white/80 border border-gray-200/50 rounded-xl' }}>
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
        <Card className="bg-white/80 backdrop-blur-sm border border-indigo-100/50">
          <CardBody className="p-6">
            <div className="flex items-center gap-4 mb-6">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-purple-500 to-pink-500 flex items-center justify-center shadow-lg">
                <Globe className="w-6 h-6 text-white" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-800">语言与地区</h2>
                <p className="text-sm text-gray-500">设置界面语言和时区</p>
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              <div className="p-4 bg-gradient-to-r from-purple-50/50 to-pink-50/50 rounded-xl border border-purple-100/30">
                <p className="font-medium text-gray-800 mb-3">语言</p>
                <Select label="选择语言" value={language} onChange={(e) => setLanguage(e.target.value)} classNames={{ trigger: 'bg-white/80 border border-gray-200/50 rounded-xl' }}>
                  <SelectItem key="zh-CN" value="zh-CN">简体中文</SelectItem>
                  <SelectItem key="en-US" value="en-US">English</SelectItem>
                </Select>
              </div>
              <div className="p-4 bg-gradient-to-r from-pink-50/50 to-rose-50/50 rounded-xl border border-pink-100/30">
                <p className="font-medium text-gray-800 mb-3">时区</p>
                <Select label="选择时区" value={timezone} onChange={(e) => setTimezone(e.target.value)} classNames={{ trigger: 'bg-white/80 border border-gray-200/50 rounded-xl' }}>
                  <SelectItem key="Asia/Shanghai" value="Asia/Shanghai">中国标准时间 (UTC+8)</SelectItem>
                  <SelectItem key="UTC" value="UTC">UTC (UTC+0)</SelectItem>
                </Select>
              </div>
            </div>
          </CardBody>
        </Card>

        {/* Data Management */}
        <Card className="bg-white/80 backdrop-blur-sm border border-indigo-100/50">
          <CardBody className="p-6">
            <div className="flex items-center gap-4 mb-6">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-orange-500 to-yellow-500 flex items-center justify-center shadow-lg">
                <Database className="w-6 h-6 text-white" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-800">数据管理</h2>
                <p className="text-sm text-gray-500">管理数据备份和清理</p>
              </div>
            </div>
            <div className="space-y-3">
              <Button variant="bordered" className="w-full justify-start h-12 text-left bg-gradient-to-r from-blue-50/50 to-indigo-50/50 border-blue-200/50 hover:from-blue-100/50 hover:to-indigo-100/50 rounded-xl">
                <span className="flex items-center gap-3">
                  <Download className="w-5 h-5 text-blue-500" />
                  <span className="font-medium">导出所有数据</span>
                </span>
              </Button>
              <Button variant="bordered" className="w-full justify-start h-12 text-left bg-gradient-to-r from-green-50/50 to-emerald-50/50 border-green-200/50 hover:from-green-100/50 hover:to-emerald-100/50 rounded-xl">
                <span className="flex items-center gap-3">
                  <Database className="w-5 h-5 text-green-500" />
                  <span className="font-medium">创建数据库备份</span>
                </span>
              </Button>
              <Button variant="bordered" color="warning" className="w-full justify-start h-12 text-left bg-gradient-to-r from-yellow-50/50 to-orange-50/50 border-yellow-200/50 hover:from-yellow-100/50 hover:to-orange-100/50 rounded-xl">
                <span className="flex items-center gap-3">
                  <Trash2 className="w-5 h-5 text-orange-500" />
                  <span className="font-medium">清理过期数据（保留30天）</span>
                </span>
              </Button>
            </div>
          </CardBody>
        </Card>

        {/* System Info */}
        <Card className="bg-white/80 backdrop-blur-sm border border-indigo-100/50">
          <CardBody className="p-6">
            <div className="flex items-center gap-4 mb-5">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-500 flex items-center justify-center">
                <Info className="w-5 h-5 text-white" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-800">系统信息</h2>
                <p className="text-sm text-gray-500">当前系统运行状态</p>
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="p-4 bg-gradient-to-r from-indigo-50/50 to-purple-50/50 rounded-xl border border-indigo-100/30">
                <p className="text-sm text-gray-500">系统版本</p>
                <p className="font-semibold text-gray-800">v1.0.0</p>
              </div>
              <div className="p-4 bg-gradient-to-r from-purple-50/50 to-pink-50/50 rounded-xl border border-purple-100/30">
                <p className="text-sm text-gray-500">构建时间</p>
                <p className="font-semibold text-gray-800">2026-05-20 14:30:00</p>
              </div>
              <div className="p-4 bg-gradient-to-r from-pink-50/50 to-rose-50/50 rounded-xl border border-pink-100/30">
                <p className="text-sm text-gray-500">API 版本</p>
                <p className="font-semibold text-gray-800">v1</p>
              </div>
              <div className="p-4 bg-gradient-to-r from-green-50/50 to-emerald-50/50 rounded-xl border border-green-100/30">
                <p className="text-sm text-gray-500">服务器状态</p>
                <p className="font-semibold text-green-600 flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>
                  运行正常
                </p>
              </div>
            </div>
          </CardBody>
        </Card>
      </div>
    </Layout>
  );
}
