import { useState, useEffect } from 'react';
import Layout from '../components/Layout';
import { subscriptionAPI, apiKeyAPI } from '../services/api';
import {
  Card,
  CardBody,
  Button,
  Input,
  Select,
  SelectItem,
  Table,
  TableHeader,
  TableColumn,
  TableBody,
  TableRow,
  TableCell,
  Modal,
  ModalContent,
  ModalHeader,
  ModalBody,
  ModalFooter,
  useDisclosure,
} from '@nextui-org/react';
import { Save, Plus, Trash2, AlertCircle, Check } from 'lucide-react';

interface ApiPolicy {
  id: string;
  planId: string;
  provider: string;
  modelPattern?: string;
  multiplier: number;
  isAllowed: boolean;
}

interface PlanItem {
  id: string;
  name: string;
  type?: string;
}

interface HealthyModel {
  id: string;
  provider: string;
  name: string;
  model: string;
}

const PROVIDER_LABELS: Record<string, string> = {
  qwen: '通义千问',
  deepseek: 'DeepSeek',
  openai: 'OpenAI',
  anthropic: 'Anthropic',
  gemini: 'Gemini',
  grok: 'Grok',
};

export default function ApiPoliciesPage() {
  const [plans, setPlans] = useState<PlanItem[]>([]);
  const [selectedPlan, setSelectedPlan] = useState('');
  const [policies, setPolicies] = useState<ApiPolicy[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { isOpen, onOpen, onClose } = useDisclosure();
  const [editingPolicy, setEditingPolicy] = useState<Partial<ApiPolicy>>({});
  const [healthyModels, setHealthyModels] = useState<HealthyModel[]>([]);
  const [selectedModels, setSelectedModels] = useState<string[]>([]);

  useEffect(() => {
    fetchPlans();
    fetchHealthyModels();
  }, []);

  useEffect(() => {
    if (selectedPlan) {
      fetchPolicies(selectedPlan);
    }
  }, [selectedPlan]);

  const fetchPlans = async () => {
    try {
      const data = await subscriptionAPI.getPlans();
      setPlans(data);
      if (data.length > 0) {
        setSelectedPlan(data[0].id);
      }
    } catch (err: any) {
      setError(err.response?.data?.message || '获取套餐列表失败');
    }
  };

  const fetchHealthyModels = async () => {
    try {
      const data = await apiKeyAPI.getHealthyModels();
      setHealthyModels(data);
    } catch (err: any) {
      console.error('获取健康模型失败:', err);
    }
  };

  const fetchPolicies = async (planId: string) => {
    setLoading(true);
    try {
      const data = await subscriptionAPI.getPlanApiPolicies(planId);
      setPolicies(data);
    } catch (err: any) {
      setError(err.response?.data?.message || '获取API策略失败');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    if (!editingPolicy.provider || !editingPolicy.multiplier) {
      setError('请填写完整信息');
      return;
    }
    try {
      // 为每个选中的模型创建策略
      for (const model of selectedModels) {
        await subscriptionAPI.updatePlanApiPolicy(selectedPlan, model, {
          provider: editingPolicy.provider,
          multiplier: editingPolicy.multiplier,
          modelPattern: model,
        });
      }
      onClose();
      fetchPolicies(selectedPlan);
      setEditingPolicy({});
      setSelectedModels([]);
    } catch (err: any) {
      setError(err.response?.data?.message || '保存失败');
    }
  };

  const openAdd = () => {
    setEditingPolicy({
      provider: '',
      multiplier: 1.0,
      isAllowed: true,
    });
    setSelectedModels([]);
    onOpen();
  };

  // 按提供商分组的健康模型
  const modelsByProvider = healthyModels.reduce((acc, model) => {
    if (!acc[model.provider]) {
      acc[model.provider] = [];
    }
    acc[model.provider].push(model);
    return acc;
  }, {} as Record<string, HealthyModel[]>);

  return (
    <Layout currentPage="api-policies">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-800">API 系数配置</h1>
            <p className="text-gray-500 mt-1">配置不同套餐的API使用策略和配额消耗倍数（仅显示已测试通过的模型）</p>
          </div>
          <Button
            color="primary"
            className="bg-blue-600 hover:bg-blue-700"
            onClick={openAdd}
            startContent={<Plus className="w-4 h-4" />}
          >
            添加策略
          </Button>
        </div>

        {error && (
          <div className="p-4 bg-red-50 border border-red-200 rounded-xl flex items-center gap-2 text-red-700">
            <AlertCircle className="w-5 h-5" />
            <span>{error}</span>
          </div>
        )}

        {/* Plan Selector */}
        <Card className="shadow-sm">
          <CardBody>
            <div className="flex items-center gap-4">
              <span className="text-sm font-medium text-gray-700">选择套餐：</span>
              <Select
                selectedKeys={[selectedPlan]}
                onChange={(e) => setSelectedPlan(e.target.value)}
                className="w-64"
                classNames={{ trigger: 'rounded-xl' }}
              >
                {plans.map((plan) => (
                  <SelectItem key={plan.id} value={plan.id}>
                    {plan.name}
                  </SelectItem>
                ))}
              </Select>
            </div>
          </CardBody>
        </Card>

        {/* Policies Table */}
        <Card className="shadow-sm">
          <CardBody>
            <Table aria-label="API策略列表">
              <TableHeader>
                <TableColumn>提供商</TableColumn>
                <TableColumn>模型</TableColumn>
                <TableColumn>消耗倍数</TableColumn>
                <TableColumn>状态</TableColumn>
                <TableColumn>操作</TableColumn>
              </TableHeader>
              <TableBody>
                {policies?.map((policy) => (
                  <TableRow key={policy.id}>
                    <TableCell>
                      {PROVIDER_LABELS[policy.provider] || policy.provider}
                    </TableCell>
                    <TableCell>{policy.modelPattern || '全部'}</TableCell>
                    <TableCell>
                      <span className={`font-bold ${policy.multiplier > 1 ? 'text-orange-600' : 'text-green-600'}`}>
                        {policy.multiplier}x
                      </span>
                    </TableCell>
                    <TableCell>
                      <span className={`px-2 py-1 rounded-full text-xs ${policy.isAllowed ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                        {policy.isAllowed ? '允许' : '禁止'}
                      </span>
                    </TableCell>
                    <TableCell>
                      <Button
                        size="sm"
                        variant="light"
                        color="danger"
                        isIconOnly
                        aria-label="删除"
                        onClick={async () => {
                          if (!confirm('确定要删除该策略吗？')) return;
                          try {
                            await subscriptionAPI.deletePlanApiPolicy(selectedPlan, policy.id);
                            fetchPolicies(selectedPlan);
                          } catch (err: any) {
                            setError(err.response?.data?.message || '删除失败');
                          }
                        }}
                      >
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {policies?.length === 0 && !loading && (
              <div className="text-center py-12 text-gray-500">
                <p>该套餐暂无API策略配置</p>
                <p className="text-sm mt-1">点击右上角添加策略</p>
              </div>
            )}
          </CardBody>
        </Card>

        {/* Reference Card */}
        <Card className="shadow-sm">
          <CardBody>
            <h3 className="text-lg font-bold text-gray-800 mb-4">推荐配置参考</h3>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
              {[
                { provider: '通义千问', multiplier: '1.0x', desc: '国产低成本' },
                { provider: 'DeepSeek', multiplier: '1.0x', desc: '国产低成本' },
                { provider: 'Gemini', multiplier: '2.0x', desc: '中等成本' },
                { provider: 'OpenAI', multiplier: '5.0x', desc: '高成本' },
                { provider: 'Anthropic', multiplier: '4.0x', desc: '高成本' },
                { provider: 'Grok', multiplier: '3.0x', desc: '中高成本' },
              ].map((item) => (
                <div key={item.provider} className="p-3 bg-gray-50 rounded-xl">
                  <p className="font-medium text-gray-800">{item.provider}</p>
                  <p className="text-lg font-bold text-blue-600">{item.multiplier}</p>
                  <p className="text-xs text-gray-500">{item.desc}</p>
                </div>
              ))}
            </div>
          </CardBody>
        </Card>
      </div>

      {/* Add/Edit Modal */}
      <Modal isOpen={isOpen} onClose={onClose} classNames={{ base: 'rounded-xl' }}>
        <ModalContent>
          <ModalHeader>配置API策略</ModalHeader>
          <ModalBody>
            <div className="space-y-4">
              <div className="p-3 bg-blue-50 rounded-xl">
                <p className="text-sm text-blue-700 font-medium">选择模型（仅显示已测试通过的API Key）</p>
                <p className="text-xs text-blue-500 mt-1">未测试通过的模型不会显示在列表中</p>
              </div>

              {/* 按提供商分组显示模型 */}
              <div className="space-y-3 max-h-80 overflow-y-auto">
                {Object.entries(modelsByProvider).map(([provider, models]) => (
                  <div key={provider} className="border border-gray-200 rounded-xl p-3">
                    <p className="text-sm font-semibold text-gray-700 mb-2">
                      {PROVIDER_LABELS[provider] || provider}
                    </p>
                    <div className="flex flex-wrap gap-2">
                      {models.map((model) => (
                        <button
                          key={model.id}
                          type="button"
                          onClick={() => {
                            const modelKey = `${model.provider}:${model.model}`;
                            setSelectedModels((prev) =>
                              prev.includes(modelKey)
                                ? prev.filter((m) => m !== modelKey)
                                : [...prev, modelKey]
                            );
                            // 自动设置提供商
                            if (!editingPolicy.provider) {
                              setEditingPolicy({ ...editingPolicy, provider });
                            }
                          }}
                          className={`flex items-center gap-1.5 px-3 py-1.5 text-xs rounded-lg border transition-colors ${
                            selectedModels.includes(`${model.provider}:${model.model}`)
                              ? 'bg-blue-50 border-blue-300 text-blue-700'
                              : 'bg-gray-50 border-gray-200 text-gray-600 hover:bg-gray-100'
                          }`}
                        >
                          {selectedModels.includes(`${model.provider}:${model.model}`) && (
                            <Check className="w-3 h-3" />
                          )}
                          {model.model}
                        </button>
                      ))}
                    </div>
                  </div>
                ))}

                {healthyModels.length === 0 && (
                  <div className="text-center py-8 text-gray-500">
                    <p>暂无已测试通过的模型</p>
                    <p className="text-sm mt-1">请先在 API Key 管理中测试API连通性</p>
                  </div>
                )}
              </div>

              {selectedModels.length > 0 && (
                <div className="p-3 bg-green-50 rounded-xl">
                  <p className="text-sm text-green-700">
                    已选择 {selectedModels.length} 个模型
                  </p>
                </div>
              )}

              <Input
                label="消耗倍数"
                type="number"
                step="0.1"
                value={String(editingPolicy.multiplier || 1)}
                onChange={(e) => setEditingPolicy({ ...editingPolicy, multiplier: parseFloat(e.target.value) })}
                classNames={{ inputWrapper: 'rounded-xl' }}
              />
            </div>
          </ModalBody>
          <ModalFooter>
            <Button variant="light" onClick={onClose}>
              取消
            </Button>
            <Button
              color="primary"
              className="bg-blue-600"
              onClick={handleSave}
              isDisabled={selectedModels.length === 0}
              startContent={<Save className="w-4 h-4" />}
            >
              保存
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </Layout>
  );
}
