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
import { Save, Plus, Trash2, AlertCircle } from 'lucide-react';

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

interface ApiKeyModel {
  provider: string;
  model: string;
}

const PROVIDER_OPTIONS = [
  { key: 'qwen', label: '通义千问' },
  { key: 'deepseek', label: 'DeepSeek' },
  { key: 'openai', label: 'OpenAI' },
  { key: 'anthropic', label: 'Anthropic' },
  { key: 'gemini', label: 'Gemini' },
  { key: 'grok', label: 'Grok' },
  { key: 'all', label: '全部' },
];

export default function ApiPoliciesPage() {
  const [plans, setPlans] = useState<PlanItem[]>([]);
  const [selectedPlan, setSelectedPlan] = useState('');
  const [policies, setPolicies] = useState<ApiPolicy[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { isOpen, onOpen, onClose } = useDisclosure();
  const [editingPolicy, setEditingPolicy] = useState<Partial<ApiPolicy>>({});
  const [apiKeyModels, setApiKeyModels] = useState<ApiKeyModel[]>([]);
  const [availableModels, setAvailableModels] = useState<string[]>([]);

  useEffect(() => {
    fetchPlans();
    fetchApiKeyModels();
  }, []);

  useEffect(() => {
    if (selectedPlan) {
      fetchPolicies(selectedPlan);
    }
  }, [selectedPlan]);

  useEffect(() => {
    if (editingPolicy.provider) {
      const models = apiKeyModels
        .filter(m => m.provider === editingPolicy.provider)
        .map(m => m.model);
      setAvailableModels(Array.from(new Set(models)));
    } else {
      setAvailableModels([]);
    }
  }, [editingPolicy.provider, apiKeyModels]);

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

  const fetchApiKeyModels = async () => {
    try {
      const keys = await apiKeyAPI.getApiKeys();
      const models = keys.map((k: any) => ({ provider: k.provider, model: k.model }));
      setApiKeyModels(models);
    } catch (err: any) {
      console.error('获取API Key模型失败:', err);
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
      await subscriptionAPI.updatePlanApiPolicy(selectedPlan, editingPolicy.modelPattern || '*', {
        provider: editingPolicy.provider,
        multiplier: editingPolicy.multiplier,
        modelPattern: editingPolicy.modelPattern || '*',
      });
      onClose();
      fetchPolicies(selectedPlan);
      setEditingPolicy({});
    } catch (err: any) {
      setError(err.response?.data?.message || '保存失败');
    }
  };

  const openAdd = () => {
    setEditingPolicy({
      provider: 'qwen',
      multiplier: 1.0,
      isAllowed: true,
    });
    onOpen();
  };

  return (
    <Layout currentPage="api-policies">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-800">API 系数配置</h1>
            <p className="text-gray-500 mt-1">配置不同套餐的API使用策略和配额消耗倍数</p>
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
                <TableColumn>模型匹配</TableColumn>
                <TableColumn>消耗倍数</TableColumn>
                <TableColumn>状态</TableColumn>
                <TableColumn>操作</TableColumn>
              </TableHeader>
              <TableBody>
                {policies?.map((policy) => (
                  <TableRow key={policy.id}>
                    <TableCell>
                      {PROVIDER_OPTIONS.find(p => p.key === policy.provider)?.label || policy.provider}
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
              <Select
                label="提供商"
                selectedKeys={[editingPolicy.provider || 'qwen']}
                onChange={(e) => setEditingPolicy({ ...editingPolicy, provider: e.target.value, modelPattern: undefined })}
                classNames={{ trigger: 'rounded-xl' }}
              >
                {PROVIDER_OPTIONS.map((p) => (
                  <SelectItem key={p.key} value={p.key}>
                    {p.label}
                  </SelectItem>
                ))}
              </Select>

              <Select
                label="模型（从API Key自动匹配）"
                selectedKeys={[editingPolicy.modelPattern || '']}
                onChange={(e) => setEditingPolicy({ ...editingPolicy, modelPattern: e.target.value })}
                classNames={{ trigger: 'rounded-xl' }}
              >
                {(['', ...availableModels] as string[]).map((model) => (
                  <SelectItem key={model} value={model}>
                    {model || '全部模型'}
                  </SelectItem>
                ))}
              </Select>

              <Input
                label="或手动输入模型匹配规则"
                placeholder="如：qwen-* 或 gpt-4o"
                value={editingPolicy.modelPattern || ''}
                onChange={(e) => setEditingPolicy({ ...editingPolicy, modelPattern: e.target.value })}
                classNames={{ inputWrapper: 'rounded-xl' }}
              />

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
            <Button color="primary" className="bg-blue-600" onClick={handleSave} startContent={<Save className="w-4 h-4" />}>
              保存
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </Layout>
  );
}
