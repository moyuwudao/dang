'use client';

import { useState, useEffect, useCallback } from 'react';
import { Card, CardBody, Button, Input, Select, SelectItem, Modal, ModalContent, ModalHeader, ModalBody, ModalFooter, Table, TableHeader, TableColumn, TableBody, TableRow, TableCell, Pagination, Spinner } from '@nextui-org/react';
import { Plus, Search, Edit, Package, Clock, Zap, Crown, Sparkles, Trash2, AlertCircle, RefreshCw } from 'lucide-react';
import Layout from '@/components/Layout';
import { adminAPI } from '@/services/api';
import type { Plan, Subscription } from '@/types';

const getPlanIcon = (planId: string) => {
  switch (planId) {
    case 'enterprise': return Crown;
    case 'pro': return Sparkles;
    default: return Package;
  }
};

const emptyPlan: Omit<Plan, 'id'> = {
  name: '',
  description: '',
  priceCents: 0,
  durationDays: 30,
  quotaType: 'minutes',
  quotaValue: 100,
  isActive: true,
  type: 'subscription',
};

export default function SubscriptionsPage() {
  const [plans, setPlans] = useState<Plan[]>([]);
  const [subscriptions, setSubscriptions] = useState<Subscription[]>([]);
  const [plansLoading, setPlansLoading] = useState(false);
  const [subsLoading, setSubsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [subPage, setSubPage] = useState(1);
  const [subTotalPages, setSubTotalPages] = useState(1);
  const [subTotal, setSubTotal] = useState(0);
  const subsPerPage = 10;

  const [showPlanModal, setShowPlanModal] = useState(false);
  const [planModalMode, setPlanModalMode] = useState<'create' | 'edit'>('create');
  const [editingPlan, setEditingPlan] = useState<Plan | null>(null);
  const [planForm, setPlanForm] = useState<Omit<Plan, 'id'>>({ ...emptyPlan });

  const [showDeletePlanModal, setShowDeletePlanModal] = useState(false);
  const [planToDelete, setPlanToDelete] = useState<string | null>(null);

  const [showEditSubModal, setShowEditSubModal] = useState(false);
  const [editingSub, setEditingSub] = useState<Subscription | null>(null);
  const [subStatusForm, setSubStatusForm] = useState('');

  const fetchPlans = useCallback(async () => {
    setPlansLoading(true);
    setError(null);
    try {
      const data = await adminAPI.getPlans();
      setPlans(data);
    } catch (err: any) {
      setError(err.response?.data?.message || '获取套餐列表失败');
    } finally {
      setPlansLoading(false);
    }
  }, []);

  const fetchSubscriptions = useCallback(async () => {
    setSubsLoading(true);
    setError(null);
    try {
      const data = await adminAPI.getSubscriptions(subPage, subsPerPage);
      setSubscriptions(data.items);
      setSubTotal(data.total);
      setSubTotalPages(data.totalPages);
    } catch (err: any) {
      setError(err.response?.data?.message || '获取订阅列表失败');
    } finally {
      setSubsLoading(false);
    }
  }, [subPage, statusFilter]);

  useEffect(() => {
    fetchPlans();
  }, [fetchPlans]);

  useEffect(() => {
    fetchSubscriptions();
  }, [fetchSubscriptions]);

  const handleCreatePlan = async () => {
    try {
      await adminAPI.createPlan(planForm);
      setShowPlanModal(false);
      setPlanForm({ ...emptyPlan });
      fetchPlans();
    } catch (err: any) {
      setError(err.response?.data?.message || '创建套餐失败');
    }
  };

  const handleUpdatePlan = async () => {
    if (!editingPlan) return;
    try {
      await adminAPI.updatePlan(editingPlan.id, planForm);
      setShowPlanModal(false);
      setEditingPlan(null);
      setPlanForm({ ...emptyPlan });
      fetchPlans();
    } catch (err: any) {
      setError(err.response?.data?.message || '更新套餐失败');
    }
  };

  const handleDeletePlan = async () => {
    if (!planToDelete) return;
    try {
      await adminAPI.deletePlan(planToDelete);
      setShowDeletePlanModal(false);
      setPlanToDelete(null);
      fetchPlans();
    } catch (err: any) {
      setError(err.response?.data?.message || '删除套餐失败');
    }
  };

  const handleUpdateSubscription = async () => {
    if (!editingSub) return;
    try {
      await adminAPI.updateSubscription(editingSub.id, { status: subStatusForm });
      setShowEditSubModal(false);
      setEditingSub(null);
      fetchSubscriptions();
    } catch (err: any) {
      setError(err.response?.data?.message || '更新订阅失败');
    }
  };

  const openCreatePlan = () => {
    setPlanModalMode('create');
    setEditingPlan(null);
    setPlanForm({ ...emptyPlan });
    setShowPlanModal(true);
  };

  const openEditPlan = (plan: Plan) => {
    setPlanModalMode('edit');
    setEditingPlan(plan);
    setPlanForm({
      name: plan.name,
      description: plan.description || '',
      priceCents: plan.priceCents,
      durationDays: plan.durationDays,
      quotaType: plan.quotaType,
      quotaValue: plan.quotaValue || 0,
      isActive: plan.isActive,
      type: plan.type,
    });
    setShowPlanModal(true);
  };

  const openDeletePlan = (id: string) => {
    setPlanToDelete(id);
    setShowDeletePlanModal(true);
  };

  const openEditSub = (sub: Subscription) => {
    setEditingSub(sub);
    setSubStatusForm(sub.status);
    setShowEditSubModal(true);
  };

  const getStatusConfig = (status: string) => {
    switch (status) {
      case 'active': return { label: '生效中', className: 'bg-green-50 text-green-700 border-green-200' };
      case 'expired': return { label: '已过期', className: 'bg-red-50 text-red-700 border-red-200' };
      case 'cancelled': return { label: '已取消', className: 'bg-yellow-50 text-yellow-700 border-yellow-200' };
      default: return { label: status, className: 'bg-gray-50 text-gray-700 border-gray-200' };
    }
  };

  const getQuotaPercent = (used: number, total: number) => {
    if (total === 0) return 100;
    return Math.round((used / total) * 100);
  };

  const filteredSubscriptions = subscriptions.filter(sub => {
    const matchesSearch = !searchTerm ||
      (sub.userPhone?.includes(searchTerm)) ||
      (sub.planName?.includes(searchTerm));
    return matchesSearch;
  });

  return (
    <Layout currentPage="subscriptions">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-semibold text-gray-900">订阅管理</h1>
            <p className="text-gray-500 mt-1">管理套餐和用户订阅</p>
          </div>
          <Button color="primary" className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white" onClick={openCreatePlan}>
            <Plus className="w-4 h-4" />
            添加套餐
          </Button>
        </div>

        {/* Error Alert */}
        {error && (
          <div className="flex items-center gap-3 p-4 bg-red-50 border border-red-200 rounded-xl text-red-700">
            <AlertCircle className="w-5 h-5 flex-shrink-0" />
            <span className="flex-1">{error}</span>
            <Button size="sm" variant="light" color="danger" onClick={() => { fetchPlans(); fetchSubscriptions(); }}>
              重试
            </Button>
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Plans List */}
          <Card className="bg-white border border-gray-100">
            <CardBody className="p-6">
              <div className="flex items-center gap-3 mb-5">
                <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
                  <Package className="w-5 h-5 text-blue-600" />
                </div>
                <div>
                  <h2 className="text-lg font-semibold text-gray-800">套餐列表</h2>
                  <p className="text-sm text-gray-500">{plans.length} 个套餐</p>
                </div>
                <Button
                  variant="light"
                  className="ml-auto hover:bg-gray-100"
                  onClick={fetchPlans}
                  isIconOnly
                  size="sm"
                >
                  <RefreshCw className="w-4 h-4" />
                </Button>
              </div>
              {plansLoading && plans.length === 0 ? (
                <div className="flex items-center justify-center py-10">
                  <Spinner size="lg" color="primary" />
                </div>
              ) : (
                <div className="space-y-3">
                  {plans?.map((plan) => {
                    const Icon = getPlanIcon(plan.id);
                    return (
                      <div key={plan.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors border border-gray-100">
                        <div className="flex items-center gap-3">
                          <div className="w-12 h-12 rounded-lg bg-blue-50 flex items-center justify-center">
                            <Icon className="w-6 h-6 text-blue-600" />
                          </div>
                          <div>
                            <p className="font-semibold text-gray-800">{plan.name}</p>
                            <p className="text-sm text-gray-500">{plan.description || '-'}</p>
                            <div className="flex items-center gap-3 mt-1">
                              <span className="text-sm font-medium text-blue-600">¥{(plan.priceCents / 100).toFixed(0)}/{plan.durationDays}天</span>
                              <span className="text-xs text-gray-400">
                                {plan.quotaType === 'unlimited' ? '无限配额' : `${plan.quotaValue}分钟`}
                              </span>
                            </div>
                          </div>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className={`px-3 py-1 text-xs rounded-full border ${plan.isActive ? 'bg-green-50 text-green-700 border-green-200' : 'bg-red-50 text-red-700 border-red-200'}`}>
                            {plan.isActive ? '启用' : '禁用'}
                          </span>
                          <Button size="sm" variant="light" color="primary" className="hover:bg-gray-50" isIconOnly aria-label="编辑套餐" onClick={() => openEditPlan(plan)}>
                            <Edit className="w-4 h-4" />
                          </Button>
                          <Button size="sm" variant="light" color="danger" className="hover:bg-red-50" isIconOnly aria-label="删除套餐" onClick={() => openDeletePlan(plan.id)}>
                            <Trash2 className="w-4 h-4" />
                          </Button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </CardBody>
          </Card>

          {/* Subscriptions List */}
          <Card className="bg-white border border-gray-100">
            <CardBody className="p-6">
              <div className="flex items-center gap-3 mb-5">
                <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
                  <Clock className="w-5 h-5 text-blue-600" />
                </div>
                <div>
                  <h2 className="text-lg font-semibold text-gray-800">用户订阅</h2>
                  <p className="text-sm text-gray-500">{subTotal} 个订阅</p>
                </div>
                <Button
                  variant="light"
                  className="ml-auto hover:bg-gray-100"
                  onClick={fetchSubscriptions}
                  isIconOnly
                  size="sm"
                >
                  <RefreshCw className="w-4 h-4" />
                </Button>
              </div>
              <div className="flex items-center gap-3 mb-4">
                <div className="relative flex-1">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <Input
                    placeholder="搜索用户手机号或套餐..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    onKeyDown={(e) => e.key === 'Enter' && setSubPage(1)}
                    className="pl-9"
                    size="sm"
                    classNames={{
                      inputWrapper: 'bg-gray-50/80 border border-gray-200/50 rounded-xl',
                    }}
                  />
                </div>
                <Select
                  label="状态"
                  selectedKeys={[statusFilter]}
                  onChange={(e) => { setStatusFilter(e.target.value); setSubPage(1); }}
                  size="sm"
                  className="w-32"
                  classNames={{
                    trigger: 'bg-gray-50/80 border border-gray-200/50 rounded-xl',
                  }}
                >
                  <SelectItem key="all" value="all">全部</SelectItem>
                  <SelectItem key="active" value="active">生效中</SelectItem>
                  <SelectItem key="expired" value="expired">已过期</SelectItem>
                  <SelectItem key="cancelled" value="cancelled">已取消</SelectItem>
                </Select>
              </div>

              {subsLoading && subscriptions.length === 0 ? (
                <div className="flex items-center justify-center py-10">
                  <Spinner size="lg" color="primary" />
                </div>
              ) : (
                <>
                  <div className="space-y-3 max-h-96 overflow-y-auto pr-2">
                    {filteredSubscriptions?.map((sub) => {
                      const statusConfig = getStatusConfig(sub.status);
                      const Icon = getPlanIcon(sub.planId);
                      return (
                        <div key={sub.id} className="flex items-start justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors border border-gray-100">
                          <div className="flex-1">
                            <div className="flex items-center gap-3 mb-2">
                              <div className="w-8 h-8 rounded-lg bg-blue-50 flex items-center justify-center">
                                <Icon className="w-4 h-4 text-blue-600" />
                              </div>
                              <span className={`px-2.5 py-1 text-xs rounded-full border ${statusConfig.className}`}>
                                {statusConfig.label}
                              </span>
                            </div>
                            <p className="font-medium text-gray-800 text-sm">{sub.userPhone || sub.userId}</p>
                            <div className="flex items-center gap-4 mt-2 text-xs text-gray-500">
                              <span>套餐: {sub.planName || sub.planId}</span>
                            </div>
                            {sub.totalQuota > 0 && (
                              <div className="mt-3">
                                <div className="flex items-center justify-between text-xs mb-1.5">
                                  <span className="text-gray-500">配额使用</span>
                                  <span className="text-gray-700 font-medium">{sub.usedQuota}/{sub.totalQuota}分钟</span>
                                </div>
                                <div className="w-full bg-gray-200/80 rounded-full h-2">
                                  <div
                                    className="bg-blue-500 h-2 rounded-full transition-all duration-500"
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
                            <p className="text-xs text-gray-500">开始</p>
                            <p className="text-sm font-medium text-gray-700">{sub.startedAt?.slice(0, 10) || '-'}</p>
                            <p className="text-xs text-gray-500 mt-1">到期</p>
                            <p className="text-sm font-medium text-gray-700">{sub.expiresAt?.slice(0, 10) || '-'}</p>
                            <Button
                              size="sm"
                              variant="light"
                              color="primary"
                              className="mt-2 hover:bg-gray-50"
                              onClick={() => openEditSub(sub)}
                            >
                              <Edit className="w-3 h-3 mr-1" />
                              编辑
                            </Button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                  {subTotalPages > 1 && (
                    <div className="flex justify-center pt-4 border-t border-gray-100 mt-4">
                      <Pagination
                        total={subTotalPages}
                        page={subPage}
                        onChange={setSubPage}
                        showControls
                        color="primary"
                        classNames={{
                          wrapper: 'gap-2',
                          item: 'bg-gray-100 hover:bg-gray-50',
                          cursor: 'bg-blue-600',
                        }}
                      />
                    </div>
                  )}
                </>
              )}
            </CardBody>
          </Card>
        </div>

        {/* Plan Modal (Create / Edit) */}
        <Modal isOpen={showPlanModal} onClose={() => setShowPlanModal(false)} classNames={{
          base: 'rounded-xl',
          header: 'border-b border-gray-100',
          footer: 'border-t border-gray-100',
        }}>
          <ModalContent>
          <ModalHeader className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
              <Plus className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p className="text-lg font-bold text-gray-800">{planModalMode === 'create' ? '添加新套餐' : '编辑套餐'}</p>
              <p className="text-sm text-gray-500">{planModalMode === 'create' ? '创建新的订阅套餐' : '修改套餐信息'}</p>
            </div>
          </ModalHeader>
          <ModalBody>
            <div className="space-y-4">
              <Input
                label="套餐名称"
                value={planForm.name}
                onChange={(e) => setPlanForm({ ...planForm, name: e.target.value })}
                classNames={{ inputWrapper: 'rounded-xl' }}
              />
              <Input
                label="套餐描述"
                value={planForm.description}
                onChange={(e) => setPlanForm({ ...planForm, description: e.target.value })}
                classNames={{ inputWrapper: 'rounded-xl' }}
              />
              <Input
                label="价格（分）"
                type="number"
                value={String(planForm.priceCents)}
                onChange={(e) => setPlanForm({ ...planForm, priceCents: parseInt(e.target.value) || 0 })}
                classNames={{ inputWrapper: 'rounded-xl' }}
              />
              <Input
                label="有效期（天）"
                type="number"
                value={String(planForm.durationDays)}
                onChange={(e) => setPlanForm({ ...planForm, durationDays: parseInt(e.target.value) || 30 })}
                classNames={{ inputWrapper: 'rounded-xl' }}
              />
              <Select
                label="配额类型"
                selectedKeys={[planForm.quotaType]}
                onChange={(e) => setPlanForm({ ...planForm, quotaType: e.target.value })}
                classNames={{ trigger: 'rounded-xl' }}
              >
                <SelectItem key="minutes" value="minutes">分钟</SelectItem>
                <SelectItem key="unlimited" value="unlimited">无限</SelectItem>
              </Select>
              {planForm.quotaType !== 'unlimited' && (
                <Input
                  label="配额值"
                  type="number"
                  value={String(planForm.quotaValue || 0)}
                  onChange={(e) => setPlanForm({ ...planForm, quotaValue: parseInt(e.target.value) || 0 })}
                  classNames={{ inputWrapper: 'rounded-xl' }}
                />
              )}
              <Select
                label="状态"
                selectedKeys={[planForm.isActive ? 'true' : 'false']}
                onChange={(e) => setPlanForm({ ...planForm, isActive: e.target.value === 'true' })}
                classNames={{ trigger: 'rounded-xl' }}
              >
                <SelectItem key="true" value="true">启用</SelectItem>
                <SelectItem key="false" value="false">禁用</SelectItem>
              </Select>
            </div>
          </ModalBody>
          <ModalFooter>
            <Button variant="light" onClick={() => setShowPlanModal(false)} className="hover:bg-gray-100 rounded-xl">取消</Button>
            <Button color="primary" className="bg-blue-600 hover:bg-blue-700 rounded-xl" onClick={planModalMode === 'create' ? handleCreatePlan : handleUpdatePlan}>
              {planModalMode === 'create' ? '创建套餐' : '保存修改'}
            </Button>
          </ModalFooter>
          </ModalContent>
        </Modal>

        {/* Delete Plan Modal */}
        <Modal isOpen={showDeletePlanModal} onClose={() => setShowDeletePlanModal(false)} classNames={{
          base: 'rounded-xl',
          header: 'border-b border-gray-100',
          footer: 'border-t border-gray-100',
        }}>
          <ModalContent>
          <ModalHeader className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-red-50 flex items-center justify-center">
              <Trash2 className="w-5 h-5 text-red-600" />
            </div>
            <div>
              <p className="text-lg font-bold text-gray-800">确认删除套餐</p>
              <p className="text-sm text-gray-500">此操作不可撤销</p>
            </div>
          </ModalHeader>
          <ModalBody>
            <p className="text-gray-600">确定要删除该套餐吗？删除后已订阅用户可能受到影响。</p>
          </ModalBody>
          <ModalFooter>
            <Button variant="light" onClick={() => setShowDeletePlanModal(false)} className="hover:bg-gray-100">取消</Button>
            <Button color="danger" className="bg-red-600 hover:bg-red-700" onClick={handleDeletePlan}>确认删除</Button>
          </ModalFooter>
          </ModalContent>
        </Modal>

        {/* Edit Subscription Modal */}
        <Modal isOpen={showEditSubModal} onClose={() => setShowEditSubModal(false)} classNames={{
          base: 'rounded-xl',
          header: 'border-b border-gray-100',
          footer: 'border-t border-gray-100',
        }}>
          <ModalContent>
          <ModalHeader className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
              <Edit className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p className="text-lg font-bold text-gray-800">编辑订阅</p>
              <p className="text-sm text-gray-500">{editingSub?.userPhone || editingSub?.userId}</p>
            </div>
          </ModalHeader>
          <ModalBody>
            <div className="space-y-4">
              <div className="p-3 bg-gray-50 rounded-lg">
                <p className="text-sm text-gray-500">套餐</p>
                <p className="font-medium text-gray-800">{editingSub?.planName || editingSub?.planId}</p>
              </div>
              <Select
                label="订阅状态"
                selectedKeys={[subStatusForm]}
                onChange={(e) => setSubStatusForm(e.target.value)}
                classNames={{ trigger: 'rounded-xl' }}
              >
                <SelectItem key="active" value="active">生效中</SelectItem>
                <SelectItem key="expired" value="expired">已过期</SelectItem>
                <SelectItem key="cancelled" value="cancelled">已取消</SelectItem>
              </Select>
            </div>
          </ModalBody>
          <ModalFooter>
            <Button variant="light" onClick={() => setShowEditSubModal(false)} className="hover:bg-gray-100">取消</Button>
            <Button color="primary" className="bg-blue-600 hover:bg-blue-700" onClick={handleUpdateSubscription}>保存</Button>
          </ModalFooter>
          </ModalContent>
        </Modal>
      </div>
    </Layout>
  );
}
