'use client';

import { useState, useEffect } from 'react';
import { Card, CardBody, Button, Input, Select, SelectItem, Modal, ModalHeader, ModalBody, ModalFooter } from '@nextui-org/react';
import { Plus, Search, Edit, Trash2, Package, Clock, Zap } from 'lucide-react';
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

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'success';
      case 'expired': return 'danger';
      case 'cancelled': return 'warning';
      default: return 'default';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'active': return '生效中';
      case 'expired': return '已过期';
      case 'cancelled': return '已取消';
      default: return status;
    }
  };

  const getQuotaPercent = (used: number, total: number) => {
    if (total === 0) return 100;
    return Math.round((used / total) * 100);
  };

  return (
    <Layout currentPage="subscriptions">
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-800">订阅管理</h1>
            <p className="text-gray-500 mt-1">管理套餐和用户订阅</p>
          </div>
          <Button color="primary" variant="light" className="flex items-center gap-2" onClick={() => setShowAddPlanModal(true)}>
            <Plus className="w-4 h-4" />
            添加套餐
          </Button>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card className="bg-white border border-gray-200">
            <CardBody className="p-6">
              <div className="flex items-center gap-3 mb-4">
                <Package className="w-5 h-5 text-purple-500" />
                <h2 className="text-lg font-semibold text-gray-800">套餐列表</h2>
              </div>
              <div className="space-y-3">
                {plans.map((plan) => (
                  <div key={plan.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                    <div>
                      <p className="font-medium text-gray-800">{plan.name}</p>
                      <p className="text-sm text-gray-500">{plan.description}</p>
                      <div className="flex items-center gap-4 mt-2">
                        <span className="text-sm text-gray-600">¥{(plan.priceCents / 100).toFixed(0)}/{plan.durationDays}天</span>
                        <span className="text-sm text-gray-600">
                          {plan.quotaType === 'unlimited' ? '无限配额' : `${plan.quotaValue}分钟`}
                        </span>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className={`px-2 py-1 text-xs rounded-full ${plan.isActive ? 'bg-green-100 text-green-600' : 'bg-red-100 text-red-600'}`}>
                        {plan.isActive ? '启用' : '禁用'}
                      </span>
                      <Button size="sm" variant="light" color="primary">
                        <Edit className="w-4 h-4" />
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            </CardBody>
          </Card>

          <Card className="bg-white border border-gray-200">
            <CardBody className="p-6">
              <div className="flex items-center gap-3 mb-4">
                <Clock className="w-5 h-5 text-blue-500" />
                <h2 className="text-lg font-semibold text-gray-800">用户订阅</h2>
              </div>
              <div className="flex items-center gap-4 mb-4">
                <div className="relative flex-1">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <Input
                    placeholder="搜索订阅ID..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-10"
                    size="sm"
                  />
                </div>
                <Select
                  label="状态"
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                  size="sm"
                  className="w-32"
                >
                  <SelectItem key="all" value="all">全部</SelectItem>
                  <SelectItem key="active" value="active">生效中</SelectItem>
                  <SelectItem key="expired" value="expired">已过期</SelectItem>
                </Select>
              </div>
              <div className="space-y-3">
                {filteredSubscriptions.map((sub) => (
                  <div key={sub.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                    <div className="flex-1">
                      <div className="flex items-center gap-3">
                        <p className="font-medium text-gray-800">{sub.id}</p>
                        <span className={`px-2 py-1 text-xs rounded-full ${
                          sub.status === 'active' ? 'bg-green-100 text-green-600' : 'bg-red-100 text-red-600'
                        }`}>
                          {getStatusText(sub.status)}
                        </span>
                      </div>
                      <div className="flex items-center gap-4 mt-2 text-sm text-gray-500">
                        <span>用户ID: {sub.userId}</span>
                        <span>套餐: {sub.planName}</span>
                      </div>
                      {sub.totalQuota > 0 && (
                        <div className="mt-2">
                          <div className="flex items-center justify-between text-sm mb-1">
                            <span className="text-gray-500">配额使用</span>
                            <span className="text-gray-700">{sub.usedQuota}/{sub.totalQuota}分钟</span>
                          </div>
                          <div className="w-full bg-gray-200 rounded-full h-2">
                            <div
                              className="bg-gradient-to-r from-green-400 to-green-600 h-2 rounded-full"
                              style={{ width: `${getQuotaPercent(sub.usedQuota, sub.totalQuota)}%` }}
                            />
                          </div>
                        </div>
                      )}
                      {sub.totalQuota === 0 && (
                        <div className="mt-2 flex items-center gap-2">
                          <Zap className="w-4 h-4 text-yellow-500" />
                          <span className="text-sm text-yellow-600">无限配额</span>
                        </div>
                      )}
                    </div>
                    <div className="text-right">
                      <p className="text-sm text-gray-500">到期: {sub.endDate}</p>
                    </div>
                  </div>
                ))}
              </div>
            </CardBody>
          </Card>
        </div>

        <Modal isOpen={showAddPlanModal} onClose={() => setShowAddPlanModal(false)}>
          <ModalHeader>添加新套餐</ModalHeader>
          <ModalBody>
            <div className="space-y-4">
              <Input label="套餐名称" value={newPlan.name} onChange={(e) => setNewPlan({ ...newPlan, name: e.target.value })} />
              <Input label="套餐描述" value={newPlan.description} onChange={(e) => setNewPlan({ ...newPlan, description: e.target.value })} />
              <Input label="价格（分）" type="number" value={String(newPlan.priceCents)} onChange={(e) => setNewPlan({ ...newPlan, priceCents: parseInt(e.target.value) || 0 })} />
              <Input label="有效期（天）" type="number" value={String(newPlan.durationDays)} onChange={(e) => setNewPlan({ ...newPlan, durationDays: parseInt(e.target.value) || 30 })} />
              <Select label="配额类型" value={newPlan.quotaType} onChange={(e) => setNewPlan({ ...newPlan, quotaType: e.target.value })}>
                <SelectItem key="minutes" value="minutes">分钟</SelectItem>
                <SelectItem key="unlimited" value="unlimited">无限</SelectItem>
              </Select>
              {newPlan.quotaType !== 'unlimited' && (
                <Input label="配额值" type="number" value={String(newPlan.quotaValue)} onChange={(e) => setNewPlan({ ...newPlan, quotaValue: parseInt(e.target.value) || 0 })} />
              )}
            </div>
          </ModalBody>
          <ModalFooter>
            <Button variant="light" onClick={() => setShowAddPlanModal(false)}>取消</Button>
            <Button color="primary" onClick={handleAddPlan}>创建套餐</Button>
          </ModalFooter>
        </Modal>
      </div>
    </Layout>
  );
}
