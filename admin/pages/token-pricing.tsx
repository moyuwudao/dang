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
import { Save, Plus, Trash2, AlertCircle, Coins, ArrowRightLeft } from 'lucide-react';

interface TokenPricing {
  id: string;
  modelName: string;
  modelPattern: string;
  provider: string;
  featureType: string;
  billingUnit: string;
  promptPricePer1k: number;
  completionPricePer1k: number;
  currency: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

// 功能类型：统一转换为Token计算
const FEATURE_TYPES = [
  { key: 'text_analysis', label: '文本分析', unit: 'tokens', unitLabel: '1K tokens', desc: '文本摘要、关键词提取、分类等' },
  { key: 'transcription', label: '语音转文本', unit: 'minutes', unitLabel: '分钟', tokenRatio: 150, desc: '1分钟语音 ≈ 150 tokens' },
  { key: 'realtime_transcription', label: '实时语音转写', unit: 'minutes', unitLabel: '分钟', tokenRatio: 150, desc: '1分钟语音 ≈ 150 tokens' },
  { key: 'image_recognition', label: '图像识别', unit: 'images', unitLabel: '张', tokenRatio: 1000, desc: '1张图片 ≈ 1000 tokens' },
  { key: 'ocr', label: 'OCR识别', unit: 'images', unitLabel: '张', tokenRatio: 800, desc: '1张图片 ≈ 800 tokens' },
];

const PROVIDER_COLORS: Record<string, string> = {
  qwen: 'bg-orange-100 text-orange-700',
  deepseek: 'bg-blue-100 text-blue-700',
  openai: 'bg-green-100 text-green-700',
  anthropic: 'bg-purple-100 text-purple-700',
  gemini: 'bg-indigo-100 text-indigo-700',
  grok: 'bg-gray-100 text-gray-700',
  internal: 'bg-pink-100 text-pink-700',
};

const PROVIDER_LABELS: Record<string, string> = {
  qwen: '通义千问',
  deepseek: 'DeepSeek',
  openai: 'OpenAI',
  anthropic: 'Anthropic',
  gemini: 'Gemini',
  grok: 'Grok',
  internal: '内部服务',
};

// 模型参考价格（统一按Token计费）
const MODEL_REFERENCES = [
  { model: 'qwen-turbo', name: '通义千问 Turbo', provider: 'qwen', input: 0.0005, output: 0.0015 },
  { model: 'qwen-plus', name: '通义千问 Plus', provider: 'qwen', input: 0.002, output: 0.006 },
  { model: 'deepseek-chat', name: 'DeepSeek Chat', provider: 'deepseek', input: 0.001, output: 0.002 },
  { model: 'gpt-4o-mini', name: 'GPT-4o Mini', provider: 'openai', input: 0.015, output: 0.06 },
  { model: 'gpt-4o', name: 'GPT-4o', provider: 'openai', input: 0.05, output: 0.15 },
  { model: 'claude-3-haiku', name: 'Claude 3 Haiku', provider: 'anthropic', input: 0.0125, output: 0.0625 },
];

export default function TokenPricingPage() {
  const [pricingList, setPricingList] = useState<TokenPricing[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { isOpen, onOpen, onClose } = useDisclosure();
  const [editingPricing, setEditingPricing] = useState<Partial<TokenPricing>>({});
  const [isEditing, setIsEditing] = useState(false);
  const [activeFeature, setActiveFeature] = useState('text_analysis');

  useEffect(() => {
    fetchPricingList();
  }, []);

  const fetchPricingList = async () => {
    setLoading(true);
    try {
      const data = await adminAPI.getTokenPricing();
      setPricingList(data || []);
    } catch (err: any) {
      setError(err.response?.data?.message || '获取Token价格列表失败');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    if (!editingPricing.modelName || !editingPricing.modelPattern || !editingPricing.provider) {
      setError('请填写完整信息');
      return;
    }
    if (editingPricing.promptPricePer1k === undefined) {
      setError('请输入价格');
      return;
    }

    try {
      const featureConfig = FEATURE_TYPES.find(f => f.key === editingPricing.featureType) || FEATURE_TYPES[0];
      const data = {
        modelName: editingPricing.modelName,
        modelPattern: editingPricing.modelPattern,
        provider: editingPricing.provider,
        featureType: editingPricing.featureType || 'text_analysis',
        billingUnit: editingPricing.billingUnit || featureConfig.unit,
        promptPricePer1k: editingPricing.promptPricePer1k,
        completionPricePer1k: editingPricing.completionPricePer1k || 0,
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
      setError(null);
    } catch (err: any) {
      setError(err.response?.data?.message || '保存失败');
    }
  };

  const openAdd = () => {
    const featureConfig = FEATURE_TYPES.find(f => f.key === activeFeature) || FEATURE_TYPES[0];
    setEditingPricing({
      provider: 'qwen',
      featureType: activeFeature,
      billingUnit: featureConfig.unit,
      currency: 'CNY',
      promptPricePer1k: 0,
      completionPricePer1k: 0,
      isActive: true,
    });
    setIsEditing(false);
    setError(null);
    onOpen();
  };

  const openEdit = (pricing: TokenPricing) => {
    setEditingPricing({ ...pricing });
    setIsEditing(true);
    setError(null);
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

  // 按功能类型过滤
  const filteredPricingList = pricingList.filter(p => p.featureType === activeFeature);
  const currentFeature = FEATURE_TYPES.find(f => f.key === activeFeature) || FEATURE_TYPES[0];

  // 计算等效Token价格
  const getEquivalentTokenPrice = (price: number, featureKey: string) => {
    const feature = FEATURE_TYPES.find(f => f.key === featureKey);
    if (!feature || !feature.tokenRatio) return null;
    return (price * 1000 / feature.tokenRatio).toFixed(4);
  };

  return (
    <Layout currentPage="token-pricing">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-800">Token 价格管理</h1>
            <p className="text-gray-500 mt-1">统一Token计费方案：所有功能按等效Token数量计费</p>
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

        {/* 功能类型选择 - 使用简单的按钮组替代Tabs */}
        <Card className="shadow-sm">
          <CardBody>
            <div className="flex flex-wrap gap-2">
              {FEATURE_TYPES.map((feature) => (
                <Button
                  key={feature.key}
                  size="sm"
                  variant={activeFeature === feature.key ? 'solid' : 'flat'}
                  color={activeFeature === feature.key ? 'primary' : 'default'}
                  className={activeFeature === feature.key ? 'bg-blue-600' : ''}
                  onClick={() => setActiveFeature(feature.key)}
                >
                  {feature.label}
                </Button>
              ))}
            </div>
            <p className="text-sm text-gray-500 mt-3">
              <ArrowRightLeft className="w-4 h-4 inline mr-1" />
              {currentFeature.desc}
              {currentFeature.tokenRatio && (
                <span className="ml-2 text-blue-600 font-medium">
                  转换比例: 1{currentFeature.unitLabel} = {currentFeature.tokenRatio} tokens
                </span>
              )}
            </p>
          </CardBody>
        </Card>

        {/* Pricing Table */}
        <Card className="shadow-sm">
          <CardBody>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-gray-800">{currentFeature.label} - Token价格配置</h3>
              <span className="text-sm text-gray-500">计费单位: {currentFeature.unitLabel}</span>
            </div>

            <Table aria-label={`${currentFeature.label}价格列表`}>
              <TableHeader>
                <TableColumn>提供商</TableColumn>
                <TableColumn>模型名称</TableColumn>
                <TableColumn>模型标识</TableColumn>
                <TableColumn>基础价格 ({currentFeature.unitLabel})</TableColumn>
                <TableColumn>等效Token价格 (1K tokens)</TableColumn>
                <TableColumn>货币</TableColumn>
                <TableColumn>状态</TableColumn>
                <TableColumn>操作</TableColumn>
              </TableHeader>
              <TableBody>
                {filteredPricingList.map((pricing) => (
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
                        {pricing.modelPattern}
                      </code>
                    </TableCell>
                    <TableCell>
                      <span className="font-mono text-sm">
                        ¥{pricing.promptPricePer1k.toFixed(4)}
                      </span>
                    </TableCell>
                    <TableCell>
                      {getEquivalentTokenPrice(pricing.promptPricePer1k, pricing.featureType) ? (
                        <span className="font-mono text-sm text-blue-600">
                          ¥{getEquivalentTokenPrice(pricing.promptPricePer1k, pricing.featureType)}
                        </span>
                      ) : (
                        <span className="text-gray-400 text-sm">-</span>
                      )}
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

            {filteredPricingList.length === 0 && !loading && (
              <div className="text-center py-12 text-gray-500">
                <Coins className="w-12 h-12 mx-auto mb-3 text-gray-300" />
                <p>暂无{currentFeature.label}价格配置</p>
                <p className="text-sm mt-1">点击右上角添加价格配置</p>
              </div>
            )}
          </CardBody>
        </Card>

        {/* 统一Token计费说明 */}
        <Card className="shadow-sm bg-blue-50">
          <CardBody>
            <h3 className="text-lg font-bold text-blue-800 mb-3">统一Token计费方案说明</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-blue-700">
              <div>
                <p className="font-medium mb-2">转换规则：</p>
                <ul className="space-y-1 list-disc list-inside">
                  <li>文本分析：直接按Token计费</li>
                  <li>语音转文本：1分钟 = 150 tokens</li>
                  <li>实时语音转写：1分钟 = 150 tokens</li>
                  <li>图像识别：1张 = 1000 tokens</li>
                  <li>OCR识别：1张 = 800 tokens</li>
                </ul>
              </div>
              <div>
                <p className="font-medium mb-2">计费公式：</p>
                <div className="bg-white p-3 rounded-lg font-mono text-xs">
                  <p>费用 = 使用量 × 转换比例 × Token单价</p>
                  <p className="mt-1 text-gray-500">例：10分钟语音 = 10 × 150 × ¥0.0005 = ¥0.75</p>
                </div>
              </div>
            </div>
          </CardBody>
        </Card>

        {/* 模型参考价格 */}
        <Card className="shadow-sm">
          <CardBody>
            <h3 className="text-lg font-bold text-gray-800 mb-4">常见模型Token价格参考</h3>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
              {MODEL_REFERENCES.map((item) => (
                <div key={item.model} className="p-3 bg-gray-50 rounded-xl">
                  <p className="font-medium text-gray-800 text-sm">{item.name}</p>
                  <p className="text-xs text-gray-500">{PROVIDER_LABELS[item.provider]}</p>
                  <div className="mt-2 space-y-1">
                    <p className="text-xs text-gray-600">
                      输入: <span className="font-mono font-medium">¥{item.input.toFixed(4)}</span>/1K tokens
                    </p>
                    <p className="text-xs text-gray-600">
                      输出: <span className="font-mono font-medium">¥{item.output.toFixed(4)}</span>/1K tokens
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
          <ModalHeader>{isEditing ? '编辑价格配置' : `添加${currentFeature.label}价格配置`}</ModalHeader>
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
                  value={editingPricing.modelPattern || ''}
                  onChange={(e) => setEditingPricing({ ...editingPricing, modelPattern: e.target.value })}
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
                    功能类型
                  </label>
                  <select
                    value={editingPricing.featureType || activeFeature}
                    onChange={(e) => {
                      const featureType = e.target.value;
                      const featureConfig = FEATURE_TYPES.find(f => f.key === featureType);
                      setEditingPricing({
                        ...editingPricing,
                        featureType,
                        billingUnit: featureConfig?.unit || 'tokens',
                      });
                    }}
                    className="w-full px-3 py-2.5 rounded-xl border border-gray-200 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    {FEATURE_TYPES.map((feature) => (
                      <option key={feature.key} value={feature.key}>{feature.label}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <Input
                  label={`基础价格 (每${currentFeature.unitLabel})`}
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
                  label="输出价格 (每1K tokens，可选)"
                  type="number"
                  step="0.0001"
                  placeholder="0.0015"
                  value={String(editingPricing.completionPricePer1k || 0)}
                  onChange={(e) => setEditingPricing({ ...editingPricing, completionPricePer1k: parseFloat(e.target.value) })}
                  classNames={{ inputWrapper: 'rounded-xl' }}
                  startContent={<span className="text-gray-400 text-sm">¥</span>}
                />
              </div>

              {currentFeature.tokenRatio && (
                <div className="p-3 bg-blue-50 rounded-xl">
                  <p className="text-sm text-blue-700 font-medium">等效Token价格预览</p>
                  <p className="text-xs text-blue-500 mt-1">
                    基础价格 ¥{editingPricing.promptPricePer1k || 0} / {currentFeature.unitLabel} = 
                    {' '}¥{getEquivalentTokenPrice(editingPricing.promptPricePer1k || 0, currentFeature.key) || '0'} / 1K tokens
                    （按 {currentFeature.tokenRatio} tokens/{currentFeature.unitLabel} 转换）
                  </p>
                </div>
              )}

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
