import { useState, useEffect, useCallback } from 'react';
import { Card, CardBody, Button, Table, TableHeader, TableColumn, TableBody, TableRow, TableCell, Modal, ModalContent, ModalHeader, ModalBody, ModalFooter, useDisclosure, Spinner } from '@nextui-org/react';
import { Plus, Edit, Trash2, Coins, Sliders } from 'lucide-react';
import Layout from '@/components/Layout';
import { adminAPI, apiKeyAPI } from '@/services/api';

// 单一TOKEN价格配置
interface TokenPricing {
  id: string;
  pricePerToken: number;
  isActive: boolean;
  updatedAt?: string;
}

// API系数配置 - 关联API Key中的模型
interface ApiConfig {
  id: string;
  apiKeyId: string;
  provider: string;
  modelPattern: string;
  modelName: string;
  baseCoefficient: number;
  isActive: boolean;
  createdAt?: string;
  updatedAt?: string;
}

// API Key模型选项
interface ApiKeyOption {
  id: string;
  provider: string;
  modelPattern: string;
  name: string;
}

export default function BillingConfigPage() {
  const [activeTab, setActiveTab] = useState('token-pricing');
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Data states
  const [tokenPricing, setTokenPricing] = useState<TokenPricing | null>(null);
  const [apiConfigs, setApiConfigs] = useState<ApiConfig[]>([]);
  const [apiKeyOptions, setApiKeyOptions] = useState<ApiKeyOption[]>([]);

  // Modal states
  const { isOpen: isPricingOpen, onOpen: onPricingOpen, onClose: onPricingClose } = useDisclosure();
  const { isOpen: isConfigOpen, onOpen: onConfigOpen, onClose: onConfigClose } = useDisclosure();

  const [editingConfig, setEditingConfig] = useState<ApiConfig | null>(null);

  // Form states
  const [pricingForm, setPricingForm] = useState<Partial<TokenPricing>>({});
  const [configForm, setConfigForm] = useState<Partial<ApiConfig>>({});

  // 获取API Key列表作为模型选项
  const fetchApiKeyOptions = useCallback(async () => {
    try {
      const keys = await apiKeyAPI.getApiKeys();
      const options = keys
        .filter((key: any) => key.isActive !== false)
        .map((key: any) => ({
          id: key.id,
          provider: key.provider,
          modelPattern: key.model || key.modelPattern,
          name: key.name || key.model || key.modelPattern,
        }));
      setApiKeyOptions(options);
    } catch (err: any) {
      console.error('获取API Key列表失败:', err);
    }
  }, []);

  const fetchTokenPricing = useCallback(async () => {
    try {
      setLoading(true);
      const data = await adminAPI.getTokenPricing();
      // 如果返回数组，取第一个作为全局配置
      if (Array.isArray(data) && data.length > 0) {
        setTokenPricing(data[0]);
      } else if (data && !Array.isArray(data)) {
        setTokenPricing(data);
      } else {
        setTokenPricing(null);
      }
    } catch (err: any) {
      setError(err.response?.data?.message || '获取Token价格失败');
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchApiConfigs = useCallback(async () => {
    try {
      setLoading(true);
      const data = await adminAPI.getApiConfigs();
      setApiConfigs(data);
    } catch (err: any) {
      setError(err.response?.data?.message || '获取API系数失败');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchApiKeyOptions();
  }, [fetchApiKeyOptions]);

  useEffect(() => {
    if (activeTab === 'token-pricing') {
      fetchTokenPricing();
    } else if (activeTab === 'api-configs') {
      fetchApiConfigs();
    }
  }, [activeTab, fetchTokenPricing, fetchApiConfigs]);

  // Token Pricing handlers
  const handlePricingSubmit = async () => {
    try {
      setSaving(true);
      if (tokenPricing?.id) {
        await adminAPI.updateTokenPricing(tokenPricing.id, pricingForm);
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

  // API Config handlers
  const handleConfigSubmit = async () => {
    try {
      setSaving(true);
      if (editingConfig?.id) {
        await adminAPI.updateApiConfig(editingConfig.id, configForm);
      } else {
        await adminAPI.createApiConfig(configForm);
      }
      onConfigClose();
      fetchApiConfigs();
    } catch (err: any) {
      setError(err.response?.data?.message || '保存失败');
    } finally {
      setSaving(false);
    }
  };

  const handleDeleteConfig = async (id: string) => {
    try {
      await adminAPI.deleteApiConfig(id);
      fetchApiConfigs();
    } catch (err: any) {
      setError(err.response?.data?.message || '删除失败');
    }
  };

  // 选择API Key时自动填充provider和model
  const handleApiKeySelect = (apiKeyId: string) => {
    const selected = apiKeyOptions.find(opt => opt.id === apiKeyId);
    if (selected) {
      setConfigForm({
        ...configForm,
        apiKeyId: selected.id,
        provider: selected.provider,
        modelPattern: selected.modelPattern,
        modelName: selected.name,
      });
    }
  };

  return (
    <Layout currentPage="billing-config">
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-800">计费配置</h1>
          <p className="text-gray-500 mt-1">统一管理TOKEN价格和API系数</p>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
            {error}
          </div>
        )}

        <div className="flex gap-2 border-b border-gray-200">
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
              <span>TOKEN价格</span>
            </div>
          </button>
          <button
            className={`px-4 py-2 font-medium border-b-2 transition-colors ${
              activeTab === 'api-configs'
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-gray-600 hover:text-gray-800'
            }`}
            onClick={() => setActiveTab('api-configs')}
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
            {activeTab === 'token-pricing' && (
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <h2 className="text-lg font-semibold">TOKEN价格配置</h2>
                  <Button
                    color="primary"
                    startContent={<Edit className="w-4 h-4" />}
                    onClick={() => {
                      setPricingForm(tokenPricing || { isActive: true, pricePerToken: 0.002 });
                      onPricingOpen();
                    }}
                  >
                    {tokenPricing ? '编辑价格' : '设置价格'}
                  </Button>
                </div>

                <Card>
                  <CardBody>
                    {tokenPricing ? (
                      <div className="grid grid-cols-3 gap-6">
                        <div className="text-center p-4 bg-blue-50 rounded-lg">
                          <div className="text-sm text-gray-600 mb-1">TOKEN单价</div>
                          <div className="text-2xl font-bold text-blue-600">
                            ¥{Number(tokenPricing.pricePerToken ?? 0).toFixed(6)}
                          </div>
                          <div className="text-xs text-gray-500 mt-1">元/Token</div>
                        </div>
                        <div className="text-center p-4 bg-green-50 rounded-lg">
                          <div className="text-sm text-gray-600 mb-1">状态</div>
                          <div className={`text-lg font-semibold ${tokenPricing.isActive ? 'text-green-600' : 'text-gray-600'}`}>
                            {tokenPricing.isActive ? '启用' : '禁用'}
                          </div>
                        </div>
                        <div className="text-center p-4 bg-gray-50 rounded-lg">
                          <div className="text-sm text-gray-600 mb-1">最后更新</div>
                          <div className="text-lg font-semibold text-gray-800">
                            {tokenPricing.updatedAt ? new Date(tokenPricing.updatedAt).toLocaleDateString('zh-CN') : '-'}
                          </div>
                        </div>
                      </div>
                    ) : (
                      <div className="text-center py-8 text-gray-500">
                        <Coins className="w-12 h-12 mx-auto mb-3 text-gray-300" />
                        <p>尚未设置TOKEN价格</p>
                        <p className="text-sm mt-1">点击"设置价格"按钮配置全局TOKEN单价</p>
                      </div>
                    )}

                    <div className="mt-6 p-4 bg-yellow-50 rounded-lg border border-yellow-200">
                      <h3 className="font-semibold text-yellow-800 mb-2">计费说明</h3>
                      <p className="text-sm text-yellow-700">
                        实际费用 = TOKEN消耗 × TOKEN单价 × API系数
                      </p>
                      <p className="text-sm text-yellow-600 mt-1">
                        例如：消耗1000 Token，单价0.002元，API系数1.5，则费用 = 1000 × 0.002 × 1.5 = 3元
                      </p>
                    </div>
                  </CardBody>
                </Card>
              </div>
            )}

            {activeTab === 'api-configs' && (
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <h2 className="text-lg font-semibold">API系数配置列表</h2>
                  <Button
                    color="primary"
                    startContent={<Plus className="w-4 h-4" />}
                    onClick={() => {
                      setEditingConfig(null);
                      setConfigForm({ isActive: true, baseCoefficient: 1.0 });
                      onConfigOpen();
                    }}
                  >
                    添加API系数
                  </Button>
                </div>

                <Card>
                  <CardBody>
                    <Table aria-label="API系数列表">
                      <TableHeader>
                        <TableColumn>模型</TableColumn>
                        <TableColumn>提供商</TableColumn>
                        <TableColumn>基础系数</TableColumn>
                        <TableColumn>状态</TableColumn>
                        <TableColumn>操作</TableColumn>
                      </TableHeader>
                      <TableBody emptyContent="暂无API系数配置">
                        {apiConfigs.map((config) => (
                          <TableRow key={config.id}>
                            <TableCell>
                              <div className="font-medium">{config.modelName || config.modelPattern}</div>
                              <div className="text-xs text-gray-500">{config.modelPattern}</div>
                            </TableCell>
                            <TableCell>{config.provider}</TableCell>
                            <TableCell>{Number(config.baseCoefficient ?? 1.0).toFixed(4)}x</TableCell>
                            <TableCell>
                              <span className={`px-2 py-1 rounded text-xs ${
                                config.isActive
                                  ? 'bg-green-100 text-green-700'
                                  : 'bg-gray-100 text-gray-600'
                              }`}>
                                {config.isActive ? '启用' : '禁用'}
                              </span>
                            </TableCell>
                            <TableCell>
                              <div className="flex gap-2">
                                <Button
                                  size="sm"
                                  variant="light"
                                  isIconOnly
                                  onClick={() => {
                                    setEditingConfig(config);
                                    setConfigForm(config);
                                    onConfigOpen();
                                  }}
                                >
                                  <Edit className="w-4 h-4" />
                                </Button>
                                <Button
                                  size="sm"
                                  variant="light"
                                  color="danger"
                                  isIconOnly
                                  onClick={() => handleDeleteConfig(config.id)}
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

        {/* Token Pricing Modal */}
        <Modal isOpen={isPricingOpen} onClose={onPricingClose} size="lg">
          <ModalContent>
            <ModalHeader>{tokenPricing ? '编辑TOKEN价格' : '设置TOKEN价格'}</ModalHeader>
            <ModalBody>
              <div className="space-y-4 py-4">
                <div>
                  <label className="block text-sm font-medium mb-1">TOKEN单价(元/Token) *</label>
                  <input
                    type="number"
                    step="0.000001"
                    className="w-full border rounded px-3 py-2"
                    value={pricingForm.pricePerToken || ''}
                    onChange={(e) => setPricingForm({ ...pricingForm, pricePerToken: parseFloat(e.target.value) })}
                    placeholder="如: 0.002"
                  />
                  <p className="text-xs text-gray-500 mt-1">每个Token的价格（元），如0.002表示0.002元/Token</p>
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

        {/* API Config Modal */}
        <Modal isOpen={isConfigOpen} onClose={onConfigClose} size="lg">
          <ModalContent>
            <ModalHeader>{editingConfig ? '编辑API系数' : '添加API系数'}</ModalHeader>
            <ModalBody>
              <div className="space-y-4 py-4">
                <div>
                  <label className="block text-sm font-medium mb-1">选择模型 *</label>
                  <select
                    className="w-full border rounded px-3 py-2"
                    value={configForm.apiKeyId || ''}
                    onChange={(e) => handleApiKeySelect(e.target.value)}
                    disabled={!!editingConfig}
                  >
                    <option value="">请选择模型</option>
                    {apiKeyOptions.map((opt) => (
                      <option key={opt.id} value={opt.id}>
                        {opt.name} ({opt.provider} - {opt.modelPattern})
                      </option>
                    ))}
                  </select>
                  {apiKeyOptions.length === 0 && (
                    <p className="text-xs text-orange-500 mt-1">暂无可用模型，请先前往 API Key管理 添加模型</p>
                  )}
                </div>

                {configForm.provider && (
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium mb-1">提供商</label>
                      <input
                        type="text"
                        className="w-full border rounded px-3 py-2 bg-gray-100"
                        value={configForm.provider}
                        readOnly
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium mb-1">模型</label>
                      <input
                        type="text"
                        className="w-full border rounded px-3 py-2 bg-gray-100"
                        value={configForm.modelPattern}
                        readOnly
                      />
                    </div>
                  </div>
                )}

                <div>
                  <label className="block text-sm font-medium mb-1">基础系数 *</label>
                  <input
                    type="number"
                    step="0.0001"
                    className="w-full border rounded px-3 py-2"
                    value={configForm.baseCoefficient ?? 1.0}
                    onChange={(e) => setConfigForm({ ...configForm, baseCoefficient: parseFloat(e.target.value) })}
                  />
                  <p className="text-xs text-gray-500 mt-1">用于调整该模型的实际Token消耗系数，默认1.0</p>
                </div>

                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="configActive"
                    checked={configForm.isActive ?? true}
                    onChange={(e) => setConfigForm({ ...configForm, isActive: e.target.checked })}
                  />
                  <label htmlFor="configActive">启用</label>
                </div>
              </div>
            </ModalBody>
            <ModalFooter>
              <Button variant="light" onPress={onConfigClose}>
                取消
              </Button>
              <Button color="primary" onClick={handleConfigSubmit} isLoading={saving}>
                保存
              </Button>
            </ModalFooter>
          </ModalContent>
        </Modal>
      </div>
    </Layout>
  );
}
