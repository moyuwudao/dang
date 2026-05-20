'use client';

import { useState, useEffect } from 'react';
import { Card, CardBody, Button, Input, Select, SelectItem, Modal, ModalHeader, ModalBody, ModalFooter } from '@nextui-org/react';
import { Plus, Search, Edit, Package, Clock, Zap, Crown, Sparkles } from 'lucide-react';
import Layout from '@/components/Layout';
import { subscriptionAPI } from '@/services/api';
import type { Plan, Subscription } from '@/types';

const mockPlans: Plan[] = [
  { id: 'free', name: '免费版', description: '免费体验', priceCents: 0, durationDays: 30, quotaType: 'minutes', quotaValue: 30, isActive: true },
  { id: 'basic', name: '基础版', description: '基础功能', priceCents: 9900, durationDays: 30, quotaType: 'minutes', quotaValue: 300, isActive: true },
  { id: 'pro', name: '专业版', description: '专业功能', priceCents: 29900, durationDays: 30, quotaType: 'minutes', quotaValue: 1000, isActive: true },
  { id: 'enterprise', name: '企业版', description: '无限使用', priceCents: 99900, durationDays: 30, quotaType: 'unlimited', quotaValue: 0, isActive: true },
];

const mockSubscriptions: Subscription[] = [
  { id: 'sub_001', userId: '1', planId: 'basic', planName: '基础版', startDate: '2026-05-15', endDate: '2026-06-15', status: 'active', usedQuota: 150, totalQuota: 300 },
  { id: 'sub_002', userId: '2', planId: 'pro', planName: '专业版', startDate: '2026-05-10', endDate: '2026-06-10', status: 'active', usedQuota: 450, totalQuota: 1000 },
  { id: 'sub_003', userId: '3', planId: 'free', planName: '免费版', startDate: '2026-05-18', endDate: '2026-06-18', status: 'active', usedQuota: 10, totalQuota: 30 },
  { id: 'sub_004', userId: '4', planId: 'enterprise', planName: '企业版', startDate: '2026-05-01', endDate: '2026-06-01', status: 'active', usedQuota: 0, totalQuota: 0 },
  { id: 'sub_005', userId: '5', planId: 'basic', planName: '基础版', startDate: '2026-04-20', endDate: '2026-05-20', status: 'expired', usedQuota: 280, totalQuota: 300 },
];

const getPlanIcon = (planId: string) => {
  switch (planId) {
    case 'enterprise': return Crown;
    case 'pro': return Sparkles;
    default: return Package;
  }
};

const getPlanGradient = (planId: string) => {
  switch (planId) {
    case 'enterprise': return 'from-amber-500 to-orange-500';
    case 'pro': return 'from-purple-500 to-pink-500';
    case 'basic': return 'from-blue-500 to-indigo-500';
    default: return 'from-gray-400 to-gray-500';
  }
};

export default function SubscriptionsPage() {
  const [plans, setPlans] = useState<Plan[]>(mockPlans);
  const [subscriptions, setSubscriptions] = useState<Subscription[]>(mockSubscriptions);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [showAddPlanModal, setShowAddPlanModal] = useState(false);
  const [newPlan, setNewPlan] = useState({
    name: '',
    description: '',
    priceCents: 0,
    durationDays: 30,
    quotaType: 'minutes',
    quotaValue: 100,
  });

  useEffect(() => {
    const fetchPlans = async () => {
      try {
        const data = await subscriptionAPI.getPlans();
        setPlans(data);
      } catch (err) {
        console.error('Failed to fetch plans:', err);
      }
    };
    fetchPlans();
  }, []);

  const filteredSubscriptions = subscriptions.filter(sub => {
    const matchesSearch = sub.id.includes(searchTerm) || sub.userId.includes(searchTerm);
    const matchesStatus = statusFilter === 'all' || sub.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const handleAddPlan = () => {
    setPlans([...plans, { ...newPlan, id: `plan_${Date.now()}`, isActive: true }]);
    setShowAddPlanModal(false);
    setNewPlan({ name: '', description: '', priceCents: 0, durationDays: 30, quotaType: 'minutes', quotaValue: 100 });
  };

  const getStatusConfig = (status: string) => {
    switch (status) {
      case 'active': return { color: 'success', label: '生效中', className: 'bg-green-100 text-green-700 border-green-200' };
      case 'expired': return { color: 'danger', label: '已过期', className: 'bg-red-100 text-red-700 border-red-200' };
      case 'cancelled': return { color: 'warning', label: '已取消', className: 'bg-yellow-100 text-yellow-700 border-yellow-200' };
      default: return { color: 'default', label: status, className: 'bg-gray-100 text-gray-700 border-gray-200' };
    }
  };

  const getQuotaPercent = (used: number, total: number) => {
    if (total === 0) return 100;
    return Math.round((used / total) * 100);
  };

  return (
    <Layout currentPage="subscriptions">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent">订阅管理</h1>
            <p className="text-gray-500 mt-1">管理套餐和用户订阅</p>
          </div>
          <Button color="primary" variant="light" className="flex items-center gap-2 bg-gradient-to-r from-indigo-500 to-purple-500 text-white shadow-lg shadow-indigo-500/30" onClick={() => setShowAddPlanModal(true)}>
            <Plus className="w-4 h-4" />
            添加套餐
          </Button>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Plans List */}
          <Card className="bg-white/80 backdrop-blur-sm border border-indigo-100/50">
            <CardBody className="p-6">
              <div className="flex items-center gap-3 mb-5">
                <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-500 flex items-center justify-center shadow-lg">
                  <Package className="w-5 h-5 text-white" />
                </div>
                <div>
                  <h2 className="text-lg font-semibold text-gray-800">套餐列表</h2>
                  <p className="text-sm text-gray-500">{plans.length} 个套餐</p>
                </div>
              </div>
              <div className="space-y-3">
                {plans.map((plan) => {
                  const Icon = getPlanIcon(plan.id);
                  const gradient = getPlanGradient(plan.id);
                  return (
                    <div key={plan.id} className="flex items-center justify-between p-4 bg-gradient-to-r from-indigo-50/50 to-purple-50/50 rounded-xl border border-indigo-100/30 hover:shadow-md transition-all">
                      <div className="flex items-center gap-3">
                        <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${gradient} flex items-center justify-center shadow-lg`}>
                          <Icon className="w-6 h-6 text-white" />
                        </div>
                        <div>
                          <p className="font-semibold text-gray-800">{plan.name}</p>
                          <p className="text-sm text-gray-500">{plan.description}</p>
                          <div className="flex items-center gap-3 mt-1">
                            <span className="text-sm font-medium text-indigo-600">¥{(plan.priceCents / 100).toFixed(0)}/{plan.durationDays}天</span>
                            <span className="text-xs text-gray-400">
                              {plan.quotaType === 'unlimited' ? '无限配额' : `${plan.quotaValue}分钟`}
                            </span>
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className={`px-3 py-1 text-xs rounded-full border ${plan.isActive ? 'bg-green-100 text-green-700 border-green-200' : 'bg-red-100 text-red-700 border-red-200'}`}>
                          {plan.isActive ? '启用' : '禁用'}
                        </span>
                        <Button size="sm" variant="light" color="primary" className="hover:bg-indigo-50">
                          <Edit className="w-4 h-4" />
                        </Button>
                      </div>
                    </div>
                  );
                })}
              </div>
            </CardBody>
          </Card>

          {/* Subscriptions List */}
          <Card className="bg-white/80 backdrop-blur-sm border border-indigo-100/50">
            <CardBody className="p-6">
              <div className="flex items-center gap-3 mb-5">
                <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-purple-500 to-pink-500 flex items-center justify-center shadow-lg">
                  <Clock className="w-5 h-5 text-white" />
                </div>
                <div>
                  <h2 className="text-lg font-semibold text-gray-800">用户订阅</h2>
                  <p className="text-sm text-gray-500">{filteredSubscriptions.length} 个订阅</p>
                </div>
              </div>
              <div className="flex items-center gap-3 mb-4">
                <div className="relative flex-1">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <Input
                    placeholder="搜索订阅ID..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-9"
                    size="sm"
                    classNames={{
                      inputWrapper: 'bg-gray-50/80 border border-gray-200/50 rounded-xl',
                    }}
                  />
                </div>
                <Select
                  label="状态"
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                  size="sm"
                  className="w-32"
                  classNames={{
                    trigger: 'bg-gray-50/80 border border-gray-200/50 rounded-xl',
                  }}
                >
                  <SelectItem key="all" value="all">全部</SelectItem>
                  <SelectItem key="active" value="active">生效中</SelectItem>
                  <SelectItem key="expired" value="expired">已过期</SelectItem>
                </Select>
              </div>
              <div className="space-y-3 max-h-96 overflow-y-auto pr-2">
                {filteredSubscriptions.map((sub) => {
                  const statusConfig = getStatusConfig(sub.status);
                  const Icon = getPlanIcon(sub.planId);
                  const gradient = getPlanGradient(sub.planId);
                  return (
                    <div key={sub.id} className="flex items-start justify-between p-4 bg-gradient-to-r from-purple-50/50 to-pink-50/50 rounded-xl border border-purple-100/30 hover:shadow-md transition-all">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <div className={`w-8 h-8 rounded-lg bg-gradient-to-br ${gradient} flex items-center justify-center`}>
                            <Icon className="w-4 h-4 text-white" />
                          </div>
                          <span className={`px-2.5 py-1 text-xs rounded-full border ${statusConfig.className}`}>
                            {statusConfig.label}
                          </span>
                        </div>
                        <p className="font-medium text-gray-800 text-sm">{sub.id}</p>
                        <div className="flex items-center gap-4 mt-2 text-xs text-gray-500">
                          <span>用户: {sub.userId}</span>
                          <span>套餐: {sub.planName}</span>
                        </div>
                        {sub.totalQuota > 0 && (
                          <div className="mt-3">
                            <div className="flex items-center justify-between text-xs mb-1.5">
                              <span className="text-gray-500">配额使用</span>
                              <span className="text-gray-700 font-medium">{sub.usedQuota}/{sub.totalQuota}分钟</span>
                            </div>
                            <div className="w-full bg-gray-200/80 rounded-full h-2">
                              <div
                                className="bg-gradient-to-r from-green-400 to-emerald-500 h-2 rounded-full transition-all duration-500"
                                style={{ width: `${getQuotaPercent(sub.usedQuota, sub.totalQuota)}%` }}
                              />
                            </div>
                          </div>
                        )}
                        {sub.totalQuota === 0 && (
                          <div className="mt-2 flex items-center gap-1.5">
                            <Zap className="w-4 h-4 text-amber-500" />
                            <span className="text-xs text-amber-600 font-medium">无限配额</span>
                          </div>
                        )}
                      </div>
                      <div className="text-right ml-4">
                        <p className="text-xs text-gray-500">到期日期</p>
                        <p className="text-sm font-medium text-gray-700">{sub.endDate}</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            </CardBody>
          </Card>
        </div>

        {/* Add Plan Modal */}
        <Modal isOpen={showAddPlanModal} onClose={() => setShowAddPlanModal(false)} classNames={{
          base: 'rounded-2xl',
        }}>
          <ModalHeader className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-500 flex items-center justify-center">
              <Plus className="w-5 h-5 text-white" />
            </div>
            <div>
              <p className="text-lg font-bold text-gray-800">添加新套餐</p>
              <p className="text-sm text-gray-500">创建新的订阅套餐</p>
            </div>
          </ModalHeader>
          <ModalBody>
            <div className="space-y-4">
              <Input label="套餐名称" value={newPlan.name} onChange={(e) => setNewPlan({ ...newPlan, name: e.target.value })} classNames={{ inputWrapper: 'rounded-xl' }} />
              <Input label="套餐描述" value={newPlan.description} onChange={(e) => setNewPlan({ ...newPlan, description: e.target.value })} classNames={{ inputWrapper: 'rounded-xl' }} />
              <Input label="价格（分）" type="number" value={String(newPlan.priceCents)} onChange={(e) => setNewPlan({ ...newPlan, priceCents: parseInt(e.target.value) || 0 })} classNames={{ inputWrapper: 'rounded-xl' }} />
              <Input label="有效期（天）" type="number" value={String(newPlan.durationDays)} onChange={(e) => setNewPlan({ ...newPlan, durationDays: parseInt(e.target.value) || 30 })} classNames={{ inputWrapper: 'rounded-xl' }} />
              <Select label="配额类型" value={newPlan.quotaType} onChange={(e) => setNewPlan({ ...newPlan, quotaType: e.target.value })} classNames={{ trigger: 'rounded-xl' }}>
                <SelectItem key="minutes" value="minutes">分钟</SelectItem>
                <SelectItem key="unlimited" value="unlimited">无限</SelectItem>
              </Select>
              {newPlan.quotaType !== 'unlimited' && (
                <Input label="配额值" type="number" value={String(newPlan.quotaValue)} onChange={(e) => setNewPlan({ ...newPlan, quotaValue: parseInt(e.target.value) || 0 })} classNames={{ inputWrapper: 'rounded-xl' }} />
              )}
            </div>
          </ModalBody>
          <ModalFooter>
            <Button variant="light" onClick={() => setShowAddPlanModal(false)} className="hover:bg-gray-100 rounded-xl">取消</Button>
            <Button color="primary" className="bg-gradient-to-r from-indigo-500 to-purple-500 rounded-xl" onClick={handleAddPlan}>创建套餐</Button>
          </ModalFooter>
        </Modal>
      </div>
    </Layout>
  );
}
