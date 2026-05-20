'use client';

import { useState } from 'react';
import { Button, Input, Card, CardBody, Alert } from '@nextui-org/react';
import { Eye, EyeOff, LogIn, Sparkles, Shield, Zap } from 'lucide-react';
import { authAPI } from '@/services/api';

export default function LoginPage() {
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const response = await authAPI.login(phone, password);
      if (typeof window !== 'undefined') {
        localStorage.setItem('accessToken', response.accessToken);
        localStorage.setItem('refreshToken', response.refreshToken);
        window.location.href = '/dashboard';
      }
    } catch (err) {
      setError('登录失败，请检查账号密码');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center relative overflow-hidden">
      {/* Animated Background */}
      <div className="absolute inset-0 bg-gradient-to-br from-indigo-600 via-purple-600 to-pink-500">
        <div className="absolute inset-0 opacity-30">
          <div className="absolute top-0 -left-4 w-72 h-72 bg-purple-400 rounded-full mix-blend-multiply filter blur-xl animate-pulse"></div>
          <div className="absolute top-0 -right-4 w-72 h-72 bg-yellow-400 rounded-full mix-blend-multiply filter blur-xl animate-pulse" style={{ animationDelay: '2s' }}></div>
          <div className="absolute -bottom-8 left-20 w-72 h-72 bg-pink-400 rounded-full mix-blend-multiply filter blur-xl animate-pulse" style={{ animationDelay: '4s' }}></div>
          <div className="absolute bottom-0 right-20 w-72 h-72 bg-indigo-400 rounded-full mix-blend-multiply filter blur-xl animate-pulse" style={{ animationDelay: '1s' }}></div>
        </div>
      </div>

      {/* Glass Card */}
      <Card className="w-full max-w-md mx-4 relative z-10 backdrop-blur-2xl bg-white/80 shadow-2xl shadow-indigo-500/20 border border-white/20 rounded-3xl">
        <CardBody className="p-8">
          {/* Logo & Title */}
          <div className="text-center mb-8">
            <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 flex items-center justify-center mx-auto mb-5 shadow-xl shadow-indigo-500/40">
              <Sparkles className="w-10 h-10 text-white" />
            </div>
            <h1 className="text-3xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent mb-2">畅记云管理后台</h1>
            <p className="text-sm text-gray-500">Changji Cloud Admin</p>
          </div>

          {error && (
            <Alert color="danger" className="mb-6 backdrop-blur-sm bg-red-50/80 border border-red-200/50 rounded-xl">
              {error}
            </Alert>
          )}

          <form onSubmit={handleSubmit}>
            <div className="space-y-5">
              <Input
                label="手机号"
                placeholder="请输入手机号"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                className="w-full"
                size="lg"
                classNames={{
                  input: 'text-lg',
                  inputWrapper: 'bg-white/50 backdrop-blur-sm border border-gray-200/50 rounded-xl hover:bg-white/70 focus-within:bg-white transition-colors',
                }}
              />
              <Input
                label="密码"
                placeholder="请输入密码"
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                endContent={
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="focus:outline-none"
                  >
                    {showPassword ? (
                      <EyeOff className="w-5 h-5 text-gray-400" />
                    ) : (
                      <Eye className="w-5 h-5 text-gray-400" />
                    )}
                  </button>
                }
                className="w-full"
                size="lg"
                classNames={{
                  input: 'text-lg',
                  inputWrapper: 'bg-white/50 backdrop-blur-sm border border-gray-200/50 rounded-xl hover:bg-white/70 focus-within:bg-white transition-colors',
                }}
              />
              <Button
                type="submit"
                className="w-full bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500 hover:from-indigo-600 hover:via-purple-600 hover:to-pink-600 text-white font-semibold text-lg shadow-xl shadow-indigo-500/30 rounded-xl h-14 transition-all duration-200 hover:shadow-2xl hover:shadow-indigo-500/40"
                isDisabled={loading}
              >
                {loading ? (
                  <div className="flex items-center gap-2">
                    <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                    登录中...
                  </div>
                ) : (
                  <div className="flex items-center gap-2">
                    <LogIn className="w-5 h-5" />
                    登录
                  </div>
                )}
              </Button>
            </div>
          </form>

          {/* Features */}
          <div className="mt-8 pt-6 border-t border-gray-100">
            <div className="grid grid-cols-2 gap-4">
              <div className="flex items-center gap-2 text-sm text-gray-500">
                <Shield className="w-4 h-4 text-green-500" />
                <span>安全加密</span>
              </div>
              <div className="flex items-center gap-2 text-sm text-gray-500">
                <Zap className="w-4 h-4 text-yellow-500" />
                <span>快速响应</span>
              </div>
            </div>
          </div>
        </CardBody>
      </Card>
    </div>
  );
}
