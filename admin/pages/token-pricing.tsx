import { useState, useEffect } from 'react';
import Layout from '../components/Layout';
import { adminAPI } from '../services/api';
import {
  Card,
  CardBody,
  Button,
  Input,
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
  Chip,
} from '@nextui-org/react';
import { Save, Plus, Trash2, AlertCircle, Coins } from 'lucide-react';

interface TokenPricing {
  id: string;
  modelName: string;
  modelIdentifier: string;
  provider: string;
  promptPricePer1k: number;
  completionPricePer1k: number;
  currency: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

const PROVIDER_COLORS: Record<string, string> = {
  qwen: 'bg-orange-100 text-orange-700',
  deepseek: 'bg-blue-100 text-blue-700',
  openai: 'bg-green-100 text-green-700',
  anthropic: 'bg-purple-100 text-purple-700',
  gemini: 'bg-indigo-100 text-indigo-700',
  grok: 'bg-gray-100 text-gray-700',
};

const PROVIDER_LABELS: Record<string, string> = {
  qwen: '通义千问',
  deepseek: 'DeepSeek',
  openai: 'OpenAI',
  anthropic: 'Anthropic',
  gemini: 'Gemini',
  grok: 'Grok',
};

export default function TokenPricingPage() {
  const [pricingList, setPricingList] = useState<TokenPricing[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { isOpen, onOpen, onClose } = useDisclosure();
  const [editingPricing, setEditingPricing] = useState<Partial<TokenPricing>>({});
  const [isEditing, setIsEditing] = useState(false);

  useEffect(() => {
    fetchPricingList();
  }, []);

  const fetchPricingList = async () => {
    setLoading(true);
    try {
      const data = await adminAPI.getTokenPricing();
      setPricingList(data);
    } catch (err: any) {
      setError(err.response?.data?.message || '获取Token价格列表失败');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    if (!editingPricing.modelName || !editingPricing.modelIdentifier || !editingPricing.provider) {
      setError('请填写完整信息');
      return;
    }
    if (editingPricing.promptPricePer1k === undefined || editingPricing.completionPricePer1k === undefined) {
      setError('请输入价格');
      return;
    }

    try {
      const data = {
        modelName: editingPricing.modelName,
        modelIdentifier: editingPricing.modelIdentifier,
        provider: editingPricing.provider,
        promptPricePer1k: editingPricing.promptPricePer1k,
        completionPricePer1k: editingPricing.completionPricePer1k,
        currency: editingPricing.currency || 'CNY',
        isActive: editingPricing.isActive !== false,
      };

      if (isEditing && editingPricing.id) {
        await adminAPI.updateTokenPricing(editingPricing.id, data);
      } else {
        await adminAPI.createTokenPricing(data);
      }

      onClose();
      fetchPricingList();
      setEditingPricing({});
      setIsEditing(false);
    } catch (err: any) {
      setError(err.response?.data?.message || '保存失败');
    }
  };

  const openAdd = () => {
    setEditingPricing({
      provider: 'qwen',
      currency: 'CNY',
      promptPricePer1k: 0,
      completionPricePer1k: 0,
      isActive: true,
    });
    setIsEditing(false);
    onOpen();
  };

  const openEdit = (pricing: TokenPricing) => {
    setEditingPricing({ ...pricing });
    setIsEditing(true);
    onOpen();
  };

  const handleDelete = async (id: string) => {
    if (!confirm('确定要删除该价格配置吗？')) return;
    try {
      await adminAPI.deleteTokenPricing(id);
      fetchPricingList();
    } catch (err: any) {
      setError(err.response?.data?.message || '删除失败');
    }
  };

  // 计算价格差异
  const getPriceDiff = (prompt: number, completion: number) => {
    if (prompt === completion) return '相同';
    if (completion > prompt) return `输出贵 ${((completion / prompt - 1) * 100).toFixed(0)}%`;
    return `输入贵 ${((prompt / completion - 1) * 100).toFixed(0)}%`;
  };

  return (
    <Layout currentPage="token-pricing">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-800">Token 价格管理</h1>
            <p className="text-gray-500 mt-1">配置各AI模型的Token单价，用于按量计费的成本核算</p>
          </div>
          <Button
            color="primary"
            className="bg-blue-600 hover:bg-blue-700"
            onClick={openAdd}
            startContent={<Plus className="w-4 h-4" />}
          >
            添加价格配置
          </Button>
        </div>

        {error && (
          <div className="p-4 bg-red-50 border border-red-200 rounded-xl flex items-center gap-2 text-red-700">
            <AlertCircle className="w-5 h-5" />
            <span>{error}</span>
          </div>
        )}

        {/* Pricing Table */}
        <Card className="shadow-sm">
          <CardBody>
            <Table aria-label="Token价格列表">
              <TableHeader>
                <TableColumn>提供商</TableColumn>
                <TableColumn>模型名称</TableColumn>
                <TableColumn>模型标识</TableColumn>
                <TableColumn>输入价格 (1K tokens)</TableColumn>
                <TableColumn>输出价格 (1K tokens)</TableColumn>
                <TableColumn>货币</TableColumn>
                <TableColumn>状态</TableColumn>
                <TableColumn>操作</TableColumn>
              </TableHeader>
              <TableBody>
                {pricingList.map((pricing) => (
                  <TableRow key={pricing.id}>
                    <TableCell>
                      <Chip
                        size="sm"
                        className={PROVIDER_COLORS[pricing.provider] || 'bg-gray-100 text-gray-700'}
                      >
                        {PROVIDER_LABELS[pricing.provider] || pricing.provider}
                      </Chip>
                    </TableCell>
                    <TableCell className="font-medium">{pricing.modelName}</TableCell>
                    <TableCell>
                      <code className="px-2 py-1 bg-gray-100 rounded text-xs text-gray-600">
                        {pricing.modelIdentifier}
                      </code>
                    </TableCell>
                    <TableCell>
                      <span className="font-mono text-sm">
                        ¥{pricing.promptPricePer1k.toFixed(4)}
                      </span>
                    </TableCell>
                    <TableCell>
                      <div className="flex flex-col gap-1">
                        <span className="font-mono text-sm">
                          ¥{pricing.completionPricePer1k.toFixed(4)}
                        </span>
                        <span className="text-xs text-gray-400">
                          {getPriceDiff(pricing.promptPricePer1k, pricing.completionPricePer1k)}
                        </span>
                      </div>
                    </TableCell>
                    <TableCell>{pricing.currency}</TableCell>
                    <TableCell>
                      <Chip
                        size="sm"
                        className={pricing.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}
                      >
                        {pricing.isActive ? '启用' : '停用'}
                      </Chip>
                    </TableCell>
                    <TableCell>
                      <div className="flex gap-2">
                        <Button
                          size="sm"
                          variant="light"
                          color="primary"
                          onClick={() => openEdit(pricing)}
                        >
                          编辑
                        </Button>
                        <Button
                          size="sm"
                          variant="light"
                          color="danger"
                          isIconOnly
                          aria-label="删除"
                          onClick={() => handleDelete(pricing.id)}
                        >
                          <Trash2 className="w-4 h-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {pricingList.length === 0 && !loading && (
              <div className="text-center py-12 text-gray-500">
                <Coins className="w-12 h-12 mx-auto mb-3 text-gray-300" />
                <p>暂无Token价格配置</p>
                <p className="text-sm mt-1">点击右上角添加价格配置</p>
              </div>
            )}
          </CardBody>
        </Card>

        {/* Reference Card */}
        <Card className="shadow-sm">
          <CardBody>
            <h3 className="text-lg font-bold text-gray-800 mb-4">常见模型价格参考</h3>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {[
                { model: 'qwen-turbo', provider: '通义千问', input: 0.0005, output: 0.0015 },
                { model: 'qwen-plus', provider: '通义千问', input: 0.002, output: 0.006 },
                { model: 'deepseek-chat', provider: 'DeepSeek', input: 0.001, output: 0.002 },
                { model: 'gpt-4o-mini', provider: 'OpenAI', input: 0.015, output: 0.06 },
                { model: 'gpt-4o', provider: 'OpenAI', input: 0.05, output: 0.15 },
                { model: 'claude-3-haiku', provider: 'Anthropic', input: 0.0125, output: 0.0625 },
                { model: 'gemini-1.5-flash', provider: 'Gemini', input: 0.00125, output: 0.005 },
                { model: 'grok-2', provider: 'Grok', input: 0.02, output: 0.06 },
              ].map((item) => (
                <div key={item.model} className="p-3 bg-gray-50 rounded-xl">
                  <p className="font-medium text-gray-800 text-sm">{item.model}</p>
                  <p className="text-xs text-gray-500">{item.provider}</p>
                  <div className="mt-2 space-y-1">
                    <p className="text-xs text-gray-600">
                      输入: <span className="font-mono font-medium">¥{item.input.toFixed(4)}</span>/1K
                    </p>
                    <p className="text-xs text-gray-600">
                      输出: <span className="font-mono font-medium">¥{item.output.toFixed(4)}</span>/1K
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </CardBody>
        </Card>
      </div>

      {/* Add/Edit Modal */}
      <Modal isOpen={isOpen} onClose={onClose} classNames={{ base: 'rounded-xl' }} size="lg">
        <ModalContent>
          <ModalHeader>{isEditing ? '编辑价格配置' : '添加价格配置'}</ModalHeader>
          <ModalBody>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <Input
                  label="模型名称"
                  placeholder="例如：通义千问 Turbo"
                  value={editingPricing.modelName || ''}
                  onChange={(e) => setEditingPricing({ ...editingPricing, modelName: e.target.value })}
                  classNames={{ inputWrapper: 'rounded-xl' }}
                  isRequired
                />
                <Input
                  label="模型标识"
                  placeholder="例如：qwen-turbo"
                  value={editingPricing.modelIdentifier || ''}
                  onChange={(e) => setEditingPricing({ ...editingPricing, modelIdentifier: e.target.value })}
                  classNames={{ inputWrapper: 'rounded-xl' }}
                  isRequired
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">
                    提供商 <span className="text-red-500">*</span>
                  </label>
                  <select
                    value={editingPricing.provider || 'qwen'}
                    onChange={(e) => setEditingPricing({ ...editingPricing, provider: e.target.value })}
                    className="w-full px-3 py-2.5 rounded-xl border border-gray-200 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    {Object.entries(PROVIDER_LABELS).map(([key, label]) => (
                      <option key={key} value={key}>{label}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">
                    货币
                  </label>
                  <select
                    value={editingPricing.currency || 'CNY'}
                    onChange={(e) => setEditingPricing({ ...editingPricing, currency: e.target.value })}
                    className="w-full px-3 py-2.5 rounded-xl border border-gray-200 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="CNY">CNY (人民币)</option>
                    <option value="USD">USD (美元)</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <Input
                  label="输入价格 (每1K tokens)"
                  type="number"
                  step="0.0001"
                  placeholder="0.0005"
                  value={String(editingPricing.promptPricePer1k || 0)}
                  onChange={(e) => setEditingPricing({ ...editingPricing, promptPricePer1k: parseFloat(e.target.value) })}
                  classNames={{ inputWrapper: 'rounded-xl' }}
                  isRequired
                  startContent={<span className="text-gray-400 text-sm">¥</span>}
                />
                <Input
                  label="输出价格 (每1K tokens)"
                  type="number"
                  step="0.0001"
                  placeholder="0.0015"
                  value={String(editingPricing.completionPricePer1k || 0)}
                  onChange={(e) => setEditingPricing({ ...editingPricing, completionPricePer1k: parseFloat(e.target.value) })}
                  classNames={{ inputWrapper: 'rounded-xl' }}
                  isRequired
                  startContent={<span className="text-gray-400 text-sm">¥</span>}
                />
              </div>

              <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                <input
                  type="checkbox"
                  id="isActive"
                  checked={editingPricing.isActive !== false}
                  onChange={(e) => setEditingPricing({ ...editingPricing, isActive: e.target.checked })}
                  className="w-4 h-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                />
                <label htmlFor="isActive" className="text-sm text-gray-700">
                  启用该价格配置
                </label>
              </div>

              <div className="p-3 bg-blue-50 rounded-xl">
                <p className="text-sm text-blue-700 font-medium">计费说明</p>
                <p className="text-xs text-blue-500 mt-1">
                  按量计费时，系统会根据实际使用的输入和输出token数量，分别乘以对应的价格进行扣费。
                  例如：输入1000 tokens × ¥0.0005 + 输出500 tokens × ¥0.0015 = ¥0.00125
                </p>
              </div>
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
              startContent={<Save className="w-4 h-4" />}
            >
              {isEditing ? '保存修改' : '添加配置'}
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </Layout>
  );
}
