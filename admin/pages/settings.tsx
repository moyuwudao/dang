'use client';

import { useState } from 'react';
import { Card, CardBody, Button, Switch, Select, SelectItem } from '@nextui-org/react';
import { Bell, Shield, Database, Globe, Save } from 'lucide-react';
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
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-800">系统设置</h1>
            <p className="text-gray-500 mt-1">配置系统参数和偏好设置</p>
          </div>
          <Button color="primary" className="flex items-center gap-2" onClick={handleSave}>
            <Save className="w-4 h-4" />
            保存设置
          </Button>
        </div>

        <Card className="bg-white border border-gray-200">
          <CardBody className="p-6">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 rounded-lg bg-blue-500 flex items-center justify-center">
                <Bell className="w-5 h-5 text-white" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-800">通知设置</h2>
                <p className="text-sm text-gray-500">管理系统通知偏好</p>
              </div>
            </div>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium text-gray-800">邮件通知</p>
                  <p className="text-sm text-gray-500">接收重要更新和告警邮件</p>
                </div>
                <Switch isSelected={notifications.email} onValueChange={(value) => setNotifications({ ...notifications, email: value })} />
              </div>
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium text-gray-800">推送通知</p>
                  <p className="text-sm text-gray-500">接收浏览器推送通知</p>
                </div>
                <Switch isSelected={notifications.push} onValueChange={(value) => setNotifications({ ...notifications, push: value })} />
              </div>
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium text-gray-800">营销邮件</p>
                  <p className="text-sm text-gray-500">接收产品更新和促销信息</p>
                </div>
                <Switch isSelected={notifications.marketing} onValueChange={(value) => setNotifications({ ...notifications, marketing: value })} />
              </div>
            </div>
          </CardBody>
        </Card>

        <Card className="bg-white border border-gray-200">
          <CardBody className="p-6">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 rounded-lg bg-green-500 flex items-center justify-center">
                <Shield className="w-5 h-5 text-white" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-800">安全设置</h2>
                <p className="text-sm text-gray-500">管理账户安全选项</p>
              </div>
            </div>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium text-gray-800">双因素认证</p>
                  <p className="text-sm text-gray-500">登录时需要额外验证</p>
                </div>
                <Switch isSelected={security.twoFactor} onValueChange={(value) => setSecurity({ ...security, twoFactor: value })} />
              </div>
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium text-gray-800">IP白名单</p>
                  <p className="text-sm text-gray-500">只允许白名单IP访问管理后台</p>
                </div>
                <Switch isSelected={security.ipWhitelist} onValueChange={(value) => setSecurity({ ...security, ipWhitelist: value })} />
              </div>
              <div>
                <p className="font-medium text-gray-800 mb-2">会话超时时间</p>
                <Select label="超时时间" value={String(security.sessionTimeout)} onChange={(e) => setSecurity({ ...security, sessionTimeout: parseInt(e.target.value) })}>
                  <SelectItem key="15" value="15">15分钟</SelectItem>
                  <SelectItem key="30" value="30">30分钟</SelectItem>
                  <SelectItem key="60" value="60">1小时</SelectItem>
                  <SelectItem key="120" value="120">2小时</SelectItem>
                </Select>
              </div>
            </div>
          </CardBody>
        </Card>

        <Card className="bg-white border border-gray-200">
          <CardBody className="p-6">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 rounded-lg bg-purple-500 flex items-center justify-center">
                <Globe className="w-5 h-5 text-white" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-800">语言与地区</h2>
                <p className="text-sm text-gray-500">设置界面语言和时区</p>
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <p className="font-medium text-gray-800 mb-2">语言</p>
                <Select label="选择语言" value={language} onChange={(e) => setLanguage(e.target.value)}>
                  <SelectItem key="zh-CN" value="zh-CN">简体中文</SelectItem>
                  <SelectItem key="en-US" value="en-US">English</SelectItem>
                </Select>
              </div>
              <div>
                <p className="font-medium text-gray-800 mb-2">时区</p>
                <Select label="选择时区" value={timezone} onChange={(e) => setTimezone(e.target.value)}>
                  <SelectItem key="Asia/Shanghai" value="Asia/Shanghai">中国标准时间 (UTC+8)</SelectItem>
                  <SelectItem key="UTC" value="UTC">UTC (UTC+0)</SelectItem>
                </Select>
              </div>
            </div>
          </CardBody>
        </Card>

        <Card className="bg-white border border-gray-200">
          <CardBody className="p-6">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 rounded-lg bg-orange-500 flex items-center justify-center">
                <Database className="w-5 h-5 text-white" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-800">数据管理</h2>
                <p className="text-sm text-gray-500">管理数据备份和清理</p>
              </div>
            </div>
            <div className="space-y-3">
              <Button variant="bordered" className="w-full justify-start">导出所有数据</Button>
              <Button variant="bordered" className="w-full justify-start">创建数据库备份</Button>
              <Button variant="bordered" color="warning" className="w-full justify-start">清理过期数据（保留30天）</Button>
            </div>
          </CardBody>
        </Card>

        <Card className="bg-white border border-gray-200">
          <CardBody className="p-6">
            <h2 className="text-lg font-semibold text-gray-800 mb-4">系统信息</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="p-4 bg-gray-50 rounded-lg">
                <p className="text-sm text-gray-500">系统版本</p>
                <p className="font-medium">v1.0.0</p>
              </div>
              <div className="p-4 bg-gray-50 rounded-lg">
                <p className="text-sm text-gray-500">构建时间</p>
                <p className="font-medium">2026-05-20 14:30:00</p>
              </div>
              <div className="p-4 bg-gray-50 rounded-lg">
                <p className="text-sm text-gray-500">API 版本</p>
                <p className="font-medium">v1</p>
              </div>
              <div className="p-4 bg-gray-50 rounded-lg">
                <p className="text-sm text-gray-500">服务器状态</p>
                <p className="font-medium text-green-600">运行正常</p>
              </div>
            </div>
          </CardBody>
        </Card>
      </div>
    </Layout>
  );
}
