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
  Tabs,
  Tab,
} from '@nextui-org/react';
import { Save, Plus, Trash2, AlertCircle, Coins } from 'lucide-react';

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

// 功能类型配置
const FEATURE_TYPES = [
  { key: 'ai_chat', label: 'AI对话', unit: 'tokens', unitLabel: '1K tokens', hasCompletionPrice: true },
  { key: 'transcription', label: '语音转写', unit: 'minutes', unitLabel: '分钟', hasCompletionPrice: false },
  { key: 'realtime_transcription', label: '实时转写', unit: 'minutes', unitLabel: '分钟', hasCompletionPrice: false },
  { key: 'text_analysis', label: '文本分析', unit: 'thousand_chars', unitLabel: '千字符', hasCompletionPrice: false },
  { key: 'image_recognition', label: '图像识别', unit: 'images', unitLabel: '张', hasCompletionPrice: false },
  { key: 'ocr', label: 'OCR识别', unit: 'images', unitLabel: '张', hasCompletionPrice: false },
  { key: 'tts', label: '语音合成', unit: 'thousand_chars', unitLabel: '千字符', hasCompletionPrice: false },
];

// 各功能类型的模型参考
const FEATURE_MODELS: Record<string, Array<{ model: string; name: string; provider: string; input: number; output?: number }>> = {
  ai_chat: [
    { model: 'qwen-turbo', name: '通义千问 Turbo', provider: 'qwen', input: 0.0005, output: 0.0015 },
    { model: 'qwen-plus', name: '通义千问 Plus', provider: 'qwen', input: 0.002, output: 0.006 },
    { model: 'deepseek-chat', name: 'DeepSeek Chat', provider: 'deepseek', input: 0.001, output: 0.002 },
    { model: 'gpt-4o-mini', name: 'GPT-4o Mini', provider: 'openai', input: 0.015, output: 0.06 },
    { model: 'gpt-4o', name: 'GPT-4o', provider: 'openai', input: 0.05, output: 0.15 },
    { model: 'claude-3-haiku', name: 'Claude 3 Haiku', provider: 'anthropic', input: 0.0125, output: 0.0625 },
    { model: 'gemini-1.5-flash', name: 'Gemini 1.5 Flash', provider: 'gemini', input: 0.00125, output: 0.005 },
  ],
  transcription: [
    { model: 'whisper-1', name: 'Whisper', provider: 'openai', input: 0.006 },
    { model: 'paraformer-realtime', name: ' Paraformer 实时', provider: 'internal', input: 0.003 },
    { model: 'qwen-audio', name: '通义语音', provider: 'qwen', input: 0.002 },
  ],
  realtime_transcription: [
    { model: 'tingwu-realtime', name: '听悟实时', provider: 'internal', input: 0.005 },
    { model: 'qwen-realtime', name: '通义实时', provider: 'qwen', input: 0.004 },
  ],
  text_analysis: [
    { model: 'qwen-turbo', name: '通义千问 Turbo', provider: 'qwen', input: 0.0005 },
    { model: 'deepseek-chat', name: 'DeepSeek Chat', provider: 'deepseek', input: 0.001 },
    { model: 'gpt-4o-mini', name: 'GPT-4o Mini', provider: 'openai', input: 0.015 },
  ],
  image_recognition: [
    { model: 'gpt-4o-vision', name: 'GPT-4o Vision', provider: 'openai', input: 0.005 },
    { model: 'qwen-vl', name: '通义千问 VL', provider: 'qwen', input: 0.003 },
  ],
  ocr: [
    { model: 'qwen-vl-ocr', name: '通义OCR', provider: 'qwen', input: 0.002 },
    { model: 'paddleocr', name: 'PaddleOCR', provider: 'internal', input: 0.001 },
  ],
  tts: [
    { model: 'qwen-tts', name: '通义语音合成', provider: 'qwen', input: 0.002 },
    { model: 'edge-tts', name: 'Edge TTS', provider: 'internal', input: 0.0005 },
  ],
};

export default function TokenPricingPage() {
  const [pricingList, setPricingList] = useState<TokenPricing[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { isOpen, onOpen, onClose } = useDisclosure();
  const [editingPricing, setEditingPricing] = useState<Partial<TokenPricing>>({});
  const [isEditing, setIsEditing] = useState(false);
  const [activeTab, setActiveTab] = useState('ai_chat');

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
        featureType: editingPricing.featureType || 'ai_chat',
        billingUnit: editingPricing.billingUnit || featureConfig.unit,
        promptPricePer1k: editingPricing.promptPricePer1k,
        completionPricePer1k: featureConfig.hasCompletionPrice ? (editingPricing.completionPricePer1k || 0) : 0,
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

  const openAdd = (featureType: string = 'ai_chat') => {
    const featureConfig = FEATURE_TYPES.find(f => f.key === featureType) || FEATURE_TYPES[0];
    setEditingPricing({
      provider: 'qwen',
      featureType: featureType,
      billingUnit: featureConfig.unit,
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

  // 按功能类型过滤价格列表
  const filteredPricingList = pricingList.filter(p => p.featureType === activeTab);

  // 获取当前功能类型的配置
  const currentFeature = FEATURE_TYPES.find(f => f.key === activeTab) || FEATURE_TYPES[0];

  return (
    <Layout currentPage="token-pricing">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-800">Token 价格管理</h1>
            <p className="text-gray-500 mt-1">配置各AI功能的价格，用于按量计费的成本核算</p>
          </div>
          <Button
            color="primary"
            className="bg-blue-600 hover:bg-blue-700"
            onClick={() => openAdd(activeTab)}
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

        {/* 功能类型标签页 */}
        <Tabs
          selectedKey={activeTab}
          onSelectionChange={(key) => setActiveTab(key as string)}
          classNames={{
            tabList: 'gap-2',
            cursor: 'bg-blue-600',
            tab: 'px-4 py-2',
          }}
        >
          {FEATURE_TYPES.map((feature) => (
            <Tab key={feature.key} title={feature.label} />
          ))}
        </Tabs>

        {/* Pricing Table */}
        <Card className="shadow-sm">
          <CardBody>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-gray-800">{currentFeature.label}价格配置</h3>
              <span className="text-sm text-gray-500">计费单位: {currentFeature.unitLabel}</span>
            </div>

            <Table aria-label={`${currentFeature.label}价格列表`}>
              <TableHeader>
                <TableColumn>提供商</TableColumn>
                <TableColumn>模型名称</TableColumn>
                <TableColumn>模型标识</TableColumn>
                <TableColumn>基础价格 ({currentFeature.unitLabel})</TableColumn>
                {currentFeature.hasCompletionPrice && <TableColumn>输出价格</TableColumn>}
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
                    {currentFeature.hasCompletionPrice && (
                      <TableCell>
                        <span className="font-mono text-sm">
                          ¥{(pricing.completionPricePer1k || 0).toFixed(4)}
                        </span>
                      </TableCell>
                    )}
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

        {/* Reference Card */}
        <Card className="shadow-sm">
          <CardBody>
            <h3 className="text-lg font-bold text-gray-800 mb-4">{currentFeature.label} - 常见模型价格参考</h3>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {(FEATURE_MODELS[activeTab] || []).map((item) => (
                <div key={item.model} className="p-3 bg-gray-50 rounded-xl">
                  <p className="font-medium text-gray-800 text-sm">{item.name}</p>
                  <p className="text-xs text-gray-500">{PROVIDER_LABELS[item.provider] || item.provider}</p>
                  <div className="mt-2 space-y-1">
                    <p className="text-xs text-gray-600">
                      基础: <span className="font-mono font-medium">¥{item.input.toFixed(4)}</span>/{currentFeature.unitLabel}
                    </p>
                    {item.output && (
                      <p className="text-xs text-gray-600">
                        输出: <span className="font-mono font-medium">¥{item.output.toFixed(4)}</span>/{currentFeature.unitLabel}
                      </p>
                    )}
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
                    value={editingPricing.featureType || activeTab}
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
                {currentFeature.hasCompletionPrice ? (
                  <Input
                    label={`输出价格 (每${currentFeature.unitLabel})`}
                    type="number"
                    step="0.0001"
                    placeholder="0.0015"
                    value={String(editingPricing.completionPricePer1k || 0)}
                    onChange={(e) => setEditingPricing({ ...editingPricing, completionPricePer1k: parseFloat(e.target.value) })}
                    classNames={{ inputWrapper: 'rounded-xl' }}
                    isRequired
                    startContent={<span className="text-gray-400 text-sm">¥</span>}
                  />
                ) : (
                  <div className="p-3 bg-gray-50 rounded-xl">
                    <p className="text-sm text-gray-600">{currentFeature.label}仅需要基础价格</p>
                    <p className="text-xs text-gray-400 mt-1">不区分输入/输出价格</p>
                  </div>
                )}
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
                  {currentFeature.hasCompletionPrice
                    ? `按量计费时，系统会根据实际使用的输入和输出${currentFeature.unitLabel}数量，分别乘以对应的价格进行扣费。`
                    : `按量计费时，系统会根据实际使用的${currentFeature.unitLabel}数量乘以基础价格进行扣费。`
                  }
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
