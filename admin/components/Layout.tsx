'use client';

import React, { useState } from 'react';
import { Navbar, NavbarContent, NavbarBrand, Button } from '@nextui-org/react';
import { LayoutDashboard, Users, CreditCard, Key, Settings, LogOut, Menu, X, BarChart3 } from 'lucide-react';

interface LayoutProps {
  children: React.ReactNode;
  currentPage: string;
}

const menuItems = [
  { id: 'dashboard', label: '仪表板', icon: LayoutDashboard },
  { id: 'users', label: '用户管理', icon: Users },
  { id: 'subscriptions', label: '订阅管理', icon: CreditCard },
  { id: 'api-keys', label: 'API Key管理', icon: Key },
  { id: 'analytics', label: '数据分析', icon: BarChart3 },
  { id: 'settings', label: '系统设置', icon: Settings },
];

export default function Layout({ children, currentPage }: LayoutProps) {
  const [sidebarOpen, setSidebarOpen] = useState(true);

  const handleLogout = () => {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('accessToken');
      localStorage.removeItem('refreshToken');
      window.location.href = '/login';
    }
  };

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Header */}
      <header className="fixed top-0 left-0 right-0 h-16 bg-white border-b border-gray-200 z-50">
        <div className="flex items-center justify-between h-full px-4">
          <div className="flex items-center gap-4">
            <Button
              variant="light"
              size="sm"
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="lg:hidden"
            >
              {sidebarOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </Button>
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-r from-indigo-500 to-purple-500 flex items-center justify-center">
                <LayoutDashboard className="w-5 h-5 text-white" />
              </div>
              <span className="font-bold text-gray-800">畅记云管理</span>
            </div>
          </div>
          <Button
            variant="light"
            color="danger"
            onClick={handleLogout}
            className="flex items-center gap-2"
          >
            <LogOut className="w-4 h-4" />
            退出登录
          </Button>
        </div>
      </header>

      <div className="flex pt-16">
        {/* Sidebar */}
        <aside 
          className={`fixed left-0 top-16 bottom-0 bg-gray-50 border-r border-gray-200 transition-all duration-300 z-40 ${
            sidebarOpen ? 'w-64' : 'w-0 -translate-x-full lg:translate-x-0'
          } overflow-hidden`}
        >
          <nav className="p-4 space-y-2">
            {menuItems.map((item) => {
              const Icon = item.icon;
              const isActive = currentPage === item.id;
              return (
                <Button
                  key={item.id}
                  variant={isActive ? 'solid' : 'light'}
                  color={isActive ? 'primary' : 'default'}
                  className={`w-full justify-start ${isActive ? '' : 'text-gray-700'}`}
                  onClick={() => {
                    if (typeof window !== 'undefined') {
                      window.location.href = `/${item.id}`;
                    }
                  }}
                >
                  <Icon className="w-5 h-5 mr-3" />
                  {item.label}
                </Button>
              );
            })}
          </nav>
        </aside>

        {/* Main Content */}
        <main className={`flex-1 min-h-[calc(100vh-64px)] p-6 transition-all duration-300 ${sidebarOpen ? 'lg:ml-64' : ''}`}>
          {children}
        </main>
      </div>
    </div>
  );
}
