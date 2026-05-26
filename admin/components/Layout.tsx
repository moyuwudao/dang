'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/router';
import { Button } from '@nextui-org/react';
import {
  LayoutDashboard,
  Users,
  CreditCard,
  Key,
  Settings,
  LogOut,
  Menu,
  X,
  BarChart3,
  Sparkles,
  Server,
  Sliders,
} from 'lucide-react';

interface LayoutProps {
  children: React.ReactNode;
  currentPage: string;
}

const menuItems = [
  { id: 'dashboard', label: '仪表板', icon: LayoutDashboard },
  { id: 'users', label: '用户管理', icon: Users },
  { id: 'subscriptions', label: '订阅管理', icon: CreditCard },
  { id: 'api-keys', label: 'API Key管理', icon: Key },
  { id: 'api-policies', label: 'API系数配置', icon: Sliders },
  { id: 'monitor', label: 'API监控', icon: BarChart3 },
  { id: 'recharge', label: '充值中心', icon: CreditCard },
  { id: 'analytics', label: '数据分析', icon: BarChart3 },
  { id: 'server-monitor', label: '服务器监控', icon: Server },
  { id: 'settings', label: '系统设置', icon: Settings },
];

export default function Layout({ children, currentPage }: LayoutProps) {
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const router = useRouter();

  const handleLogout = () => {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('accessToken');
      localStorage.removeItem('refreshToken');
      router.push('/login');
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="fixed top-0 left-0 right-0 h-14 bg-white border-b border-gray-200 z-50">
        <div className="flex items-center justify-between h-full px-4">
          <div className="flex items-center gap-3">
            <Button
              variant="light"
              size="sm"
              isIconOnly
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="lg:hidden"
            >
              {sidebarOpen ? <X className="w-5 h-5 text-gray-600" /> : <Menu className="w-5 h-5 text-gray-600" />}
            </Button>
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center">
                <Sparkles className="w-4 h-4 text-white" />
              </div>
              <span className="font-semibold text-base text-gray-900">畅记云管理</span>
            </div>
          </div>
          <Button
            variant="light"
            size="sm"
            onClick={handleLogout}
            className="flex items-center gap-1.5 text-gray-500 hover:text-red-500"
          >
            <LogOut className="w-4 h-4" />
            <span className="hidden sm:inline text-sm">退出</span>
          </Button>
        </div>
      </header>

      <div className="flex pt-14">
        {/* Sidebar */}
        <aside
          className={`fixed left-0 top-14 bottom-0 bg-white border-r border-gray-200 transition-all duration-200 z-40 ${
            sidebarOpen ? 'w-56' : 'w-0 -translate-x-full lg:translate-x-0'
          } overflow-hidden`}
        >
          <div className="flex flex-col h-full">
            <nav className="flex-1 py-3 px-3 space-y-0.5 overflow-y-auto">
              {menuItems.map((item) => {
                const Icon = item.icon;
                const isActive = currentPage === item.id;
                return (
                  <button
                    key={item.id}
                    onClick={() => {
                      router.push(`/${item.id}`);
                    }}
                    className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-colors duration-150 ${
                      isActive
                        ? 'bg-blue-50 text-blue-600 font-medium'
                        : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                    }`}
                  >
                    <Icon className={`w-[18px] h-[18px] flex-shrink-0 ${isActive ? 'text-blue-600' : 'text-gray-400'}`} />
                    <span>{item.label}</span>
                    {isActive && (
                      <div className="ml-auto w-1 h-1 rounded-full bg-blue-600" />
                    )}
                  </button>
                );
              })}
            </nav>

            {/* Sidebar Footer */}
            <div className="p-3 border-t border-gray-100">
              <div className="flex items-center gap-2 px-3 py-2">
                <div className="w-2 h-2 rounded-full bg-green-500" />
                <span className="text-xs text-gray-500">系统运行正常</span>
              </div>
            </div>
          </div>
        </aside>

        {/* Main Content */}
        <main className={`flex-1 min-h-[calc(100vh-56px)] p-6 transition-all duration-200 ${sidebarOpen ? 'lg:ml-56' : ''}`}>
          {children}
        </main>
      </div>
    </div>
  );
}
