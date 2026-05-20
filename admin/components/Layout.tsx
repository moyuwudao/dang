'use client';

import React, { useState } from 'react';
import { Navbar, NavbarContent, NavbarBrand, Button } from '@nextui-org/react';
import { LayoutDashboard, Users, CreditCard, Key, Settings, LogOut, Menu, X, BarChart3, ChevronLeft, Sparkles } from 'lucide-react';

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
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-indigo-50/30 to-purple-50/20">
      {/* Header */}
      <header className="fixed top-0 left-0 right-0 h-16 bg-white/80 backdrop-blur-xl border-b border-indigo-100/50 z-50 shadow-sm">
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
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 flex items-center justify-center shadow-lg shadow-indigo-500/30">
                <Sparkles className="w-5 h-5 text-white" />
              </div>
              <div>
                <span className="font-bold text-lg bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent">畅记云管理</span>
                <p className="text-xs text-gray-400 hidden sm:block">Changji Cloud Admin</p>
              </div>
            </div>
          </div>
          <Button
            variant="light"
            color="danger"
            onClick={handleLogout}
            className="flex items-center gap-2 font-medium"
          >
            <LogOut className="w-4 h-4" />
            <span className="hidden sm:inline">退出登录</span>
          </Button>
        </div>
      </header>

      <div className="flex pt-16">
        {/* Sidebar */}
        <aside 
          className={`fixed left-0 top-16 bottom-0 bg-white/60 backdrop-blur-xl border-r border-indigo-100/50 transition-all duration-300 z-40 ${
            sidebarOpen ? 'w-64' : 'w-0 -translate-x-full lg:translate-x-0'
          } overflow-hidden shadow-xl lg:shadow-none`}
        >
          <div className="flex flex-col h-full">
            <nav className="flex-1 p-4 space-y-1.5 overflow-y-auto">
              {menuItems.map((item) => {
                const Icon = item.icon;
                const isActive = currentPage === item.id;
                return (
                  <button
                    key={item.id}
                    onClick={() => {
                      if (typeof window !== 'undefined') {
                        window.location.href = `/${item.id}`;
                      }
                    }}
                    className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 ${
                      isActive 
                        ? 'bg-gradient-to-r from-indigo-500 to-purple-500 text-white shadow-lg shadow-indigo-500/30' 
                        : 'text-gray-600 hover:bg-indigo-50 hover:text-indigo-600'
                    }`}
                  >
                    <Icon className="w-5 h-5 flex-shrink-0" />
                    <span className="font-medium">{item.label}</span>
                    {isActive && (
                      <div className="ml-auto w-1.5 h-1.5 rounded-full bg-white shadow-sm" />
                    )}
                  </button>
                );
              })}
            </nav>
            
            {/* Sidebar Footer */}
            <div className="p-4 border-t border-indigo-100/50">
              <div className="bg-gradient-to-r from-indigo-500/10 to-purple-500/10 rounded-xl p-4">
                <div className="flex items-center gap-2 mb-2">
                  <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                  <span className="text-sm font-medium text-gray-700">系统运行正常</span>
                </div>
                <p className="text-xs text-gray-500">v1.0.0</p>
              </div>
            </div>
          </div>
        </aside>

        {/* Main Content */}
        <main className={`flex-1 min-h-[calc(100vh-64px)] p-6 transition-all duration-300 ${sidebarOpen ? 'lg:ml-64' : ''}`}>
          {children}
        </main>
      </div>
    </div>
  );
}
