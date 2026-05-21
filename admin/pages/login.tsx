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
    <div className="min-h-screen flex items-center justify-center bg-blue-600">
      {/* Login Card */}
      <Card className="w-full max-w-md mx-4 bg-white shadow-lg rounded-2xl">
        <CardBody className="p-8">
          {/* Logo & Title */}
          <div className="text-center mb-8">
            <div className="w-20 h-20 rounded-2xl bg-blue-600 flex items-center justify-center mx-auto mb-5">
              <Sparkles className="w-10 h-10 text-white" />
            </div>
            <h1 className="text-3xl font-bold text-gray-900 mb-2">畅记云管理后台</h1>
            <p className="text-sm text-gray-500">Changji Cloud Admin</p>
          </div>

          {error && (
            <Alert color="danger" className="mb-6 bg-red-50 border border-red-200 rounded-xl">
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
                  inputWrapper: 'bg-white border border-gray-200 rounded-xl hover:bg-gray-50 focus-within:bg-white transition-colors',
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
                  inputWrapper: 'bg-white border border-gray-200 rounded-xl hover:bg-gray-50 focus-within:bg-white transition-colors',
                }}
              />
              <Button
                type="submit"
                className="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold text-lg rounded-xl h-14 transition-colors duration-200"
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
