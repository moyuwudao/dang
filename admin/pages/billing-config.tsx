import { useState, useEffect, useCallback } from 'react';
import { Card, CardBody, Button, Input, Switch, Table, TableHeader, TableColumn, TableBody, TableRow, TableCell, Modal, ModalContent, ModalHeader, ModalBody, ModalFooter, useDisclosure, Spinner, Dropdown, DropdownTrigger, DropdownMenu, DropdownItem } from '@nextui-org/react';
import { Plus, Search, Edit, Trash2, Settings, Coins, Sliders, MoreVertical, Check, X, RefreshCw } from 'lucide-react';
import Layout from '@/components/Layout';
import { adminAPI } from '@/services/api';

interface BillingStandard {
  id: string;
  planId?: string;
  tier?: string;
  basePriceYuan?: number;
  outputPriceYuan?: number;
  unit?: string;
  provider?: string;
  modelPattern?: string;
  isActive: boolean;
  notes?: string;
  modelPromptPrice?: number;
  modelCompletionPrice?: number;
  createdAt?: string;
  updatedAt?: string;
}

interface TokenPricing {
  id: string;
  provider: string;
  modelPattern: string;
  inputPricePer1M: number;
  outputPricePer1M: number;
  conversionRate: number;
  isActive: boolean;
  notes?: string;
  createdAt?: string;
  updatedAt?: string;
}

interface ApiPolicy {
  id: string;
  planId?: string;
  provider: string;
  modelPattern: string;
  isAllowed: boolean;
  coefficient: number;
  isActive: boolean;
  notes?: string;
  createdAt?: string;
  updatedAt?: string;
}

const TIERS = [
  { key: 'free', label: '免费版' },
  { key: 'basic', label: '基础版' },
  { key: 'standard', label: '标准版' },
  { key: 'premium', label: '高级版' },
  { key: 'enterprise', label: '企业版' },
];

const PROVIDERS = [
  { key: 'qwen', label: '通义千问' },
  { key: 'deepseek', label: 'DeepSeek' },
  { key: 'openai', label: 'OpenAI' },
  { key: 'anthropic', label: 'Anthropic' },
  { key: 'gemini', label: 'Gemini' },
  { key: 'grok', label: 'Grok' },
];

export default function BillingConfigPage() {
  const [activeTab, setActiveTab] = useState('billing-standards');
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Data states
  const [billingStandards, setBillingStandards] = useState<BillingStandard[]>([]);
  const [tokenPricing, setTokenPricing] = useState<TokenPricing[]>([]);
  const [apiPolicies, setApiPolicies] = useState<ApiPolicy[]>([]);

  // Modal states
  const { isOpen: isStandardOpen, onOpen: onStandardOpen, onClose: onStandardClose } = useDisclosure();
  const { isOpen: isPricingOpen, onOpen: onPricingOpen, onClose: onPricingClose } = useDisclosure();
  const { isOpen: isPolicyOpen, onOpen: onPolicyOpen, onClose: onPolicyClose } = useDisclosure();

  const [editingStandard, setEditingStandard] = useState<BillingStandard | null>(null);
  const [editingPricing, setEditingPricing] = useState<TokenPricing | null>(null);
  const [editingPolicy, setEditingPolicy] = useState<ApiPolicy | null>(null);

  // Form states
  const [standardForm, setStandardForm] = useState<Partial<BillingStandard>>({});
  const [pricingForm, setPricingForm] = useState<Partial<TokenPricing>>({});
  const [policyForm, setPolicyForm] = useState<Partial<ApiPolicy>>({});

  const fetchBillingStandards = useCallback(async () => {
    try {
      setLoading(true);
      const data = await adminAPI.getBillingStandards();
      setBillingStandards(data);
    } catch (err: any) {
      setError(err.response?.data?.message || '获取计费标准失败');
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchTokenPricing = useCallback(async () => {
    try {
      setLoading(true);
      const data = await adminAPI.getTokenPricing();
      setTokenPricing(data);
    } catch (err: any) {
      setError(err.response?.data?.message || '获取Token价格失败');
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchApiPolicies = useCallback(async () => {
    try {
      setLoading(true);
      const data = await adminAPI.getApiPolicies();
      setApiPolicies(data);
    } catch (err: any) {
      setError(err.response?.data?.message || '获取API系数失败');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (activeTab === 'billing-standards') {
      fetchBillingStandards();
    } else if (activeTab === 'token-pricing') {
      fetchTokenPricing();
    } else if (activeTab === 'api-policies') {
      fetchApiPolicies();
    }
  }, [activeTab, fetchBillingStandards, fetchTokenPricing, fetchApiPolicies]);

  // Billing Standards handlers
  const handleStandardSubmit = async () => {
    try {
      setSaving(true);
      if (editingStandard?.id) {
        await adminAPI.updateBillingStandard(editingStandard.id, standardForm);
      } else {
        await adminAPI.createBillingStandard(standardForm);
      }
      onStandardClose();
      fetchBillingStandards();
    } catch (err: any) {
      setError(err.response?.data?.message || '保存失败');
    } finally {
      setSaving(false);
    }
  };

  const handleDeleteStandard = async (id: string) => {
    try {
      await adminAPI.deleteBillingStandard(id);
      fetchBillingStandards();
    } catch (err: any) {
      setError(err.response?.data?.message || '删除失败');
    }
  };

  // Token Pricing handlers
  const handlePricingSubmit = async () => {
    try {
      setSaving(true);
      if (editingPricing?.id) {
        await adminAPI.updateTokenPricing(editingPricing.id, pricingForm);
      } else {
        await adminAPI.createTokenPricing(pricingForm);
      }
      onPricingClose();
      fetchTokenPricing();
    } catch (err: any) {
      setError(err.response?.data?.message || '保存失败');
    } finally {
      setSaving(false);
    }
  };

  const handleDeletePricing = async (id: string) => {
    try {
      await adminAPI.deleteTokenPricing(id);
      fetchTokenPricing();
    } catch (err: any) {
      setError(err.response?.data?.message || '删除失败');
    }
  };

  // API Policy handlers
  const handlePolicySubmit = async () => {
    try {
      setSaving(true);
      if (editingPolicy?.id) {
        await adminAPI.updateApiPolicy(editingPolicy.id, policyForm);
      } else {
        await adminAPI.createApiPolicy(policyForm);
      }
      onPolicyClose();
      fetchApiPolicies();
    } catch (err: any) {
      setError(err.response?.data?.message || '保存失败');
    } finally {
      setSaving(false);
    }
  };

  const handleDeletePolicy = async (id: string) => {
    try {
      await adminAPI.deleteApiPolicy(id);
      fetchApiPolicies();
    } catch (err: any) {
      setError(err.response?.data?.message || '删除失败');
    }
  };

  return (
    <Layout currentPage="billing-config">
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-800">计费配置</h1>
          <p className="text-gray-500 mt-1">统一管理计费标准、模型价格和API系数</p>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
            {error}
          </div>
        )}

        <div className="flex gap-2 border-b border-gray-200">
          <button
            className={`px-4 py-2 font-medium border-b-2 transition-colors ${
              activeTab === 'billing-standards'
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-gray-600 hover:text-gray-800'
            }`}
            onClick={() => setActiveTab('billing-standards')}
          >
            <div className="flex items-center gap-2">
              <Settings className="w-4 h-4" />
              <span>计费标准</span>
            </div>
          </button>
          <button
            className={`px-4 py-2 font-medium border-b-2 transition-colors ${
              activeTab === 'token-pricing'
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-gray-600 hover:text-gray-800'
            }`}
            onClick={() => setActiveTab('token-pricing')}
          >
            <div className="flex items-center gap-2">
              <Coins className="w-4 h-4" />
              <span>模型价格</span>
            </div>
          </button>
          <button
            className={`px-4 py-2 font-medium border-b-2 transition-colors ${
              activeTab === 'api-policies'
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-gray-600 hover:text-gray-800'
            }`}
            onClick={() => setActiveTab('api-policies')}
          >
            <div className="flex items-center gap-2">
              <Sliders className="w-4 h-4" />
              <span>API系数</span>
            </div>
          </button>
        </div>

        {loading ? (
          <div className="flex justify-center py-12">
            <Spinner size="lg" />
          </div>
        ) : (
          <>
            {activeTab === 'billing-standards' && (
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <h2 className="text-lg font-semibold">计费标准列表</h2>
                  <Button
                    color="primary"
                    startContent={<Plus className="w-4 h-4" />}
                    onClick={() => {
                      setEditingStandard(null);
                      setStandardForm({ isActive: true });
                      onStandardOpen();
                    }}
                  >
                    添加计费标准
                  </Button>
                </div>

                <Card>
                  <CardBody>
                    <Table aria-label="计费标准列表">
                      <TableHeader>
                        <TableColumn>套餐</TableColumn>
                        <TableColumn>供应商</TableColumn>
                        <TableColumn>模型</TableColumn>
                        <TableColumn>用户输入价(元)</TableColumn>
                        <TableColumn>用户输出价(元)</TableColumn>
                        <TableColumn>模型输入成本(元)</TableColumn>
                        <TableColumn>模型输出成本(元)</TableColumn>
                        <TableColumn>倍率</TableColumn>
                        <TableColumn>状态</TableColumn>
                        <TableColumn>操作</TableColumn>
                      </TableHeader>
                      <TableBody emptyContent="暂无计费标准">
                        {billingStandards.map((standard) => {
                          const multiplier = standard.modelPromptPrice && standard.basePriceYuan
                            ? (standard.basePriceYuan / standard.modelPromptPrice).toFixed(2)
                            : '-';
                          return (
                            <TableRow key={standard.id}>
                              <TableCell>
                                {TIERS.find(t => t.key === standard.planId)?.label || standard.planId || '-'}
                              </TableCell>
                              <TableCell>
                                {PROVIDERS.find(p => p.key === standard.provider)?.label || standard.provider || '-'}
                              </TableCell>
                              <TableCell>{standard.modelPattern || '-'}</TableCell>
                              <TableCell className="font-medium text-blue-600">
                                ¥{standard.basePriceYuan ? standard.basePriceYuan.toFixed(4) : '-'}
                              </TableCell>
                              <TableCell className="font-medium text-blue-600">
                                ¥{standard.outputPriceYuan ? standard.outputPriceYuan.toFixed(4) : '-'}
                              </TableCell>
                              <TableCell className="text-gray-500">
                                ¥{standard.modelPromptPrice ? standard.modelPromptPrice.toFixed(4) : '-'}
                              </TableCell>
                              <TableCell className="text-gray-500">
                                ¥{standard.modelCompletionPrice ? standard.modelCompletionPrice.toFixed(4) : '-'}
                              </TableCell>
                              <TableCell>
                                <span className="px-2 py-1 rounded text-xs bg-purple-100 text-purple-700">
                                  {multiplier}x
                                </span>
                              </TableCell>
                              <TableCell>
                                <span className={`px-2 py-1 rounded text-xs ${
                                  standard.isActive
                                    ? 'bg-green-100 text-green-700'
                                    : 'bg-gray-100 text-gray-600'
                                }`}>
                                  {standard.isActive ? '启用' : '禁用'}
                                </span>
                              </TableCell>
                              <TableCell>
                                <div className="flex gap-2">
                                  <Button
                                    size="sm"
                                    variant="light"
                                    isIconOnly
                                    onClick={() => {
                                      setEditingStandard(standard);
                                      setStandardForm(standard);
                                      onStandardOpen();
                                    }}
                                  >
                                    <Edit className="w-4 h-4" />
                                  </Button>
                                  <Button
                                    size="sm"
                                    variant="light"
                                    color="danger"
                                    isIconOnly
                                    onClick={() => handleDeleteStandard(standard.id)}
                                  >
                                    <Trash2 className="w-4 h-4" />
                                  </Button>
                                </div>
                              </TableCell>
                            </TableRow>
                          );
                        })}
                      </TableBody>
                    </Table>
                  </CardBody>
                </Card>
              </div>
            )}

            {activeTab === 'token-pricing' && (
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <h2 className="text-lg font-semibold">模型价格列表</h2>
                  <Button
                    color="primary"
                    startContent={<Plus className="w-4 h-4" />}
                    onClick={() => {
                      setEditingPricing(null);
                      setPricingForm({ isActive: true });
                      onPricingOpen();
                    }}
                  >
                    添加模型价格
                  </Button>
                </div>

                <Card>
                  <CardBody>
                    <Table aria-label="模型价格列表">
                      <TableHeader>
                        <TableColumn>供应商</TableColumn>
                        <TableColumn>模型</TableColumn>
                        <TableColumn>输入价格(元/百万Token)</TableColumn>
                        <TableColumn>输出价格(元/百万Token)</TableColumn>
                        <TableColumn>TOKEN换算比例</TableColumn>
                        <TableColumn>状态</TableColumn>
                        <TableColumn>备注</TableColumn>
                        <TableColumn>操作</TableColumn>
                      </TableHeader>
                      <TableBody emptyContent="暂无模型价格">
                        {tokenPricing.map((pricing) => (
                          <TableRow key={pricing.id}>
                            <TableCell>
                              {PROVIDERS.find(p => p.key === pricing.provider)?.label || pricing.provider}
                            </TableCell>
                            <TableCell>{pricing.modelPattern}</TableCell>
                            <TableCell>¥{(pricing.inputPricePer1M ?? 0).toFixed(4)}</TableCell>
                            <TableCell>¥{(pricing.outputPricePer1M ?? 0).toFixed(4)}</TableCell>
                            <TableCell>
                              <span className="px-2 py-1 rounded text-xs bg-blue-100 text-blue-700">
                                1:{pricing.conversionRate ?? 1}
                              </span>
                            </TableCell>
                            <TableCell>
                              <span className={`px-2 py-1 rounded text-xs ${
                                pricing.isActive
                                  ? 'bg-green-100 text-green-700'
                                  : 'bg-gray-100 text-gray-600'
                              }`}>
                                {pricing.isActive ? '启用' : '禁用'}
                              </span>
                            </TableCell>
                            <TableCell>{pricing.notes || '-'}</TableCell>
                            <TableCell>
                              <div className="flex gap-2">
                                <Button
                                  size="sm"
                                  variant="light"
                                  isIconOnly
                                  onClick={() => {
                                    setEditingPricing(pricing);
                                    setPricingForm(pricing);
                                    onPricingOpen();
                                  }}
                                >
                                  <Edit className="w-4 h-4" />
                                </Button>
                                <Button
                                  size="sm"
                                  variant="light"
                                  color="danger"
                                  isIconOnly
                                  onClick={() => handleDeletePricing(pricing.id)}
                                >
                                  <Trash2 className="w-4 h-4" />
                                </Button>
                              </div>
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </CardBody>
                </Card>
              </div>
            )}

            {activeTab === 'api-policies' && (
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <h2 className="text-lg font-semibold">API系数配置列表</h2>
                  <Button
                    color="primary"
                    startContent={<Plus className="w-4 h-4" />}
                    onClick={() => {
                      setEditingPolicy(null);
                      setPolicyForm({ isAllowed: true, isActive: true, coefficient: 1.0 });
                      onPolicyOpen();
                    }}
                  >
                    添加API系数
                  </Button>
                </div>

                <Card>
                  <CardBody>
                    <Table aria-label="API系数列表">
                      <TableHeader>
                        <TableColumn>供应商</TableColumn>
                        <TableColumn>模型</TableColumn>
                        <TableColumn>是否允许</TableColumn>
                        <TableColumn>系数</TableColumn>
                        <TableColumn>状态</TableColumn>
                        <TableColumn>备注</TableColumn>
                        <TableColumn>操作</TableColumn>
                      </TableHeader>
                      <TableBody emptyContent="暂无API系数配置">
                        {apiPolicies.map((policy) => (
                          <TableRow key={policy.id}>
                            <TableCell>
                              {PROVIDERS.find(p => p.key === policy.provider)?.label || policy.provider}
                            </TableCell>
                            <TableCell>{policy.modelPattern}</TableCell>
                            <TableCell>
                              <span className={`px-2 py-1 rounded text-xs ${
                                policy.isAllowed
                                  ? 'bg-green-100 text-green-700'
                                  : 'bg-red-100 text-red-700'
                              }`}>
                                {policy.isAllowed ? '允许' : '禁止'}
                              </span>
                            </TableCell>
                            <TableCell>{(policy.coefficient ?? 1.0).toFixed(2)}x</TableCell>
                            <TableCell>
                              <span className={`px-2 py-1 rounded text-xs ${
                                policy.isActive
                                  ? 'bg-green-100 text-green-700'
                                  : 'bg-gray-100 text-gray-600'
                              }`}>
                                {policy.isActive ? '启用' : '禁用'}
                              </span>
                            </TableCell>
                            <TableCell>{policy.notes || '-'}</TableCell>
                            <TableCell>
                              <div className="flex gap-2">
                                <Button
                                  size="sm"
                                  variant="light"
                                  isIconOnly
                                  onClick={() => {
                                    setEditingPolicy(policy);
                                    setPolicyForm(policy);
                                    onPolicyOpen();
                                  }}
                                >
                                  <Edit className="w-4 h-4" />
                                </Button>
                                <Button
                                  size="sm"
                                  variant="light"
                                  color="danger"
                                  isIconOnly
                                  onClick={() => handleDeletePolicy(policy.id)}
                                >
                                  <Trash2 className="w-4 h-4" />
                                </Button>
                              </div>
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </CardBody>
                </Card>
              </div>
            )}
          </>
        )}

        {/* Billing Standard Modal */}
        <Modal isOpen={isStandardOpen} onClose={onStandardClose} size="lg">
          <ModalContent>
            <ModalHeader>{editingStandard ? '编辑计费标准' : '添加计费标准'}</ModalHeader>
            <ModalBody>
              <div className="space-y-4 py-4">
                <div>
                  <label className="block text-sm font-medium mb-1">层级</label>
                  <select
                    className="w-full border rounded px-3 py-2"
                    value={standardForm.tier || ''}
                    onChange={(e) => setStandardForm({ ...standardForm, tier: e.target.value })}
                  >
                    <option value="">请选择层级</option>
                    {TIERS.map((tier) => (
                      <option key={tier.key} value={tier.key}>{tier.label}</option>
                    ))}
                  </select>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium mb-1">输入价格(元)</label>
                    <input
                      type="number"
                      step="0.0001"
                      className="w-full border rounded px-3 py-2"
                      value={standardForm.basePriceYuan || ''}
                      onChange={(e) => setStandardForm({ ...standardForm, basePriceYuan: parseFloat(e.target.value) })}
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-1">输出价格(元)</label>
                    <input
                      type="number"
                      step="0.0001"
                      className="w-full border rounded px-3 py-2"
                      value={standardForm.outputPriceYuan || ''}
                      onChange={(e) => setStandardForm({ ...standardForm, outputPriceYuan: parseFloat(e.target.value) })}
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">单位</label>
                  <input
                    type="text"
                    className="w-full border rounded px-3 py-2"
                    value={standardForm.unit || ''}
                    onChange={(e) => setStandardForm({ ...standardForm, unit: e.target.value })}
                    placeholder="如: 百万Token"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium mb-1">供应商</label>
                    <select
                      className="w-full border rounded px-3 py-2"
                      value={standardForm.provider || ''}
                      onChange={(e) => setStandardForm({ ...standardForm, provider: e.target.value })}
                    >
                      <option value="">请选择供应商</option>
                      {PROVIDERS.map((provider) => (
                        <option key={provider.key} value={provider.key}>{provider.label}</option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-1">模型</label>
                    <input
                      type="text"
                      className="w-full border rounded px-3 py-2"
                      value={standardForm.modelPattern || ''}
                      onChange={(e) => setStandardForm({ ...standardForm, modelPattern: e.target.value })}
                      placeholder="如: gpt-4"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">备注</label>
                  <textarea
                    className="w-full border rounded px-3 py-2"
                    rows={3}
                    value={standardForm.notes || ''}
                    onChange={(e) => setStandardForm({ ...standardForm, notes: e.target.value })}
                  />
                </div>

                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="standardActive"
                    checked={standardForm.isActive ?? true}
                    onChange={(e) => setStandardForm({ ...standardForm, isActive: e.target.checked })}
                  />
                  <label htmlFor="standardActive">启用</label>
                </div>
              </div>
            </ModalBody>
            <ModalFooter>
              <Button variant="light" onPress={onStandardClose}>
                取消
              </Button>
              <Button color="primary" onClick={handleStandardSubmit} isLoading={saving}>
                保存
              </Button>
            </ModalFooter>
          </ModalContent>
        </Modal>

        {/* Token Pricing Modal */}
        <Modal isOpen={isPricingOpen} onClose={onPricingClose} size="lg">
          <ModalContent>
            <ModalHeader>{editingPricing ? '编辑模型价格' : '添加模型价格'}</ModalHeader>
            <ModalBody>
              <div className="space-y-4 py-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium mb-1">供应商 *</label>
                    <select
                      className="w-full border rounded px-3 py-2"
                      value={pricingForm.provider || ''}
                      onChange={(e) => setPricingForm({ ...pricingForm, provider: e.target.value })}
                    >
                      <option value="">请选择供应商</option>
                      {PROVIDERS.map((provider) => (
                        <option key={provider.key} value={provider.key}>{provider.label}</option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-1">模型 *</label>
                    <input
                      type="text"
                      className="w-full border rounded px-3 py-2"
                      value={pricingForm.modelPattern || ''}
                      onChange={(e) => setPricingForm({ ...pricingForm, modelPattern: e.target.value })}
                      placeholder="如: gpt-4, gpt-4-turbo"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium mb-1">输入价格(元/百万Token)</label>
                    <input
                      type="number"
                      step="0.0001"
                      className="w-full border rounded px-3 py-2"
                      value={pricingForm.inputPricePer1M || ''}
                      onChange={(e) => setPricingForm({ ...pricingForm, inputPricePer1M: parseFloat(e.target.value) })}
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-1">输出价格(元/百万Token)</label>
                    <input
                      type="number"
                      step="0.0001"
                      className="w-full border rounded px-3 py-2"
                      value={pricingForm.outputPricePer1M || ''}
                      onChange={(e) => setPricingForm({ ...pricingForm, outputPricePer1M: parseFloat(e.target.value) })}
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">TOKEN换算比例</label>
                  <input
                    type="number"
                    step="0.1"
                    className="w-full border rounded px-3 py-2"
                    value={pricingForm.conversionRate || ''}
                    onChange={(e) => setPricingForm({ ...pricingForm, conversionRate: parseFloat(e.target.value) })}
                    placeholder="如: 1个功能单位兑换多少Token，默认1"
                  />
                  <p className="text-xs text-gray-500 mt-1">1个功能单位可兑换的Token数量（如：1分钟语音=100Token则填100）</p>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">备注</label>
                  <textarea
                    className="w-full border rounded px-3 py-2"
                    rows={3}
                    value={pricingForm.notes || ''}
                    onChange={(e) => setPricingForm({ ...pricingForm, notes: e.target.value })}
                  />
                </div>

                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="pricingActive"
                    checked={pricingForm.isActive ?? true}
                    onChange={(e) => setPricingForm({ ...pricingForm, isActive: e.target.checked })}
                  />
                  <label htmlFor="pricingActive">启用</label>
                </div>
              </div>
            </ModalBody>
            <ModalFooter>
              <Button variant="light" onPress={onPricingClose}>
                取消
              </Button>
              <Button color="primary" onClick={handlePricingSubmit} isLoading={saving}>
                保存
              </Button>
            </ModalFooter>
          </ModalContent>
        </Modal>

        {/* API Policy Modal */}
        <Modal isOpen={isPolicyOpen} onClose={onPolicyClose} size="lg">
          <ModalContent>
            <ModalHeader>{editingPolicy ? '编辑API系数' : '添加API系数'}</ModalHeader>
            <ModalBody>
              <div className="space-y-4 py-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium mb-1">供应商 *</label>
                    <select
                      className="w-full border rounded px-3 py-2"
                      value={policyForm.provider || ''}
                      onChange={(e) => setPolicyForm({ ...policyForm, provider: e.target.value })}
                    >
                      <option value="">请选择供应商</option>
                      {PROVIDERS.map((provider) => (
                        <option key={provider.key} value={provider.key}>{provider.label}</option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-1">模型 *</label>
                    <input
                      type="text"
                      className="w-full border rounded px-3 py-2"
                      value={policyForm.modelPattern || ''}
                      onChange={(e) => setPolicyForm({ ...policyForm, modelPattern: e.target.value })}
                      placeholder="如: gpt-4, gpt-4-turbo"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium mb-1">系数</label>
                    <input
                      type="number"
                      step="0.1"
                      className="w-full border rounded px-3 py-2"
                      value={policyForm.coefficient ?? 1.0}
                      onChange={(e) => setPolicyForm({ ...policyForm, coefficient: parseFloat(e.target.value) })}
                    />
                    <p className="text-xs text-gray-500 mt-1">用于调整该模型的实际成本系数</p>
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-1">是否允许调用</label>
                    <div className="flex items-center gap-2 mt-2">
                      <input
                        type="checkbox"
                        id="policyAllowed"
                        checked={policyForm.isAllowed ?? true}
                        onChange={(e) => setPolicyForm({ ...policyForm, isAllowed: e.target.checked })}
                      />
                      <label htmlFor="policyAllowed">允许调用</label>
                    </div>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">备注</label>
                  <textarea
                    className="w-full border rounded px-3 py-2"
                    rows={3}
                    value={policyForm.notes || ''}
                    onChange={(e) => setPolicyForm({ ...policyForm, notes: e.target.value })}
                  />
                </div>

                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="policyActive"
                    checked={policyForm.isActive ?? true}
                    onChange={(e) => setPolicyForm({ ...policyForm, isActive: e.target.checked })}
                  />
                  <label htmlFor="policyActive">启用</label>
                </div>
              </div>
            </ModalBody>
            <ModalFooter>
              <Button variant="light" onPress={onPolicyClose}>
                取消
              </Button>
              <Button color="primary" onClick={handlePolicySubmit} isLoading={saving}>
                保存
              </Button>
            </ModalFooter>
          </ModalContent>
        </Modal>
      </div>
    </Layout>
  );
}
