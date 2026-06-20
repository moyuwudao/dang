'use client';

import { useState, useEffect, useCallback } from 'react';
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
  Chip,
  Modal,
  ModalContent,
  ModalHeader,
  ModalBody,
  ModalFooter,
  Select,
  SelectItem,
  Spinner,
  Tabs,
  Tab,
  Textarea,
  CheckboxGroup,
  Checkbox,
  RadioGroup,
  Radio,
} from '@nextui-org/react';
import {
  Plus, Search, Trash2, Key, Eye, Copy, Check, Shield, Sparkles, AlertCircle, FileJson,
  TestTube, Activity, Edit, FileText, MessageSquare, Mic, MicOff, Image as ImageIcon, Brain,
} from 'lucide-react';
import Layout from '@/components/Layout';
import { apiKeyAPI } from '@/services/api';
import type { ApiKey, ApiKeyProvider, ApiKeyStatus, ApiKeyScope, SupportedFeature } from '@/types';

const PROVIDER_OPTIONS = [
  { key: 'qwen', label: '阿里云通义千问' },
  { key: 'openai', label: 'OpenAI' },
  { key: 'anthropic', label: 'Anthropic (Claude)' },
  { key: 'gemini', label: 'Google Gemini' },
  { key: 'deepseek', label: 'DeepSeek' },
  { key: 'grok', label: 'Grok (xAI)' },
  { key: 'custom', label: '自定义' },
];

// 5 个功能类型 + all（与后端 TestableFeature / supportedFeatures 对齐）
const FEATURE_OPTIONS: { key: SupportedFeature; label: string; icon: any; desc: string }[] = [
  { key: 'textAnalysis', label: '文本分析', icon: FileText, desc: '摘要/聊天/理解' },
  { key: 'speechTranscribe', label: '语言转写', icon: MessageSquare, desc: '文本翻译/转写' },
  { key: 'speechRealtime', label: '语音实时转写', icon: Mic, desc: '实时语音转文字' },
  { key: 'speechOffline', label: '离线语音转写', icon: MicOff, desc: '上传音频文件转写' },
  { key: 'imageRecognition', label: '图像识别', icon: ImageIcon, desc: '图片理解/OCR' },
  { key: 'all', label: '全部功能', icon: Brain, desc: '通杀（仅推荐给综合模型）' },
];

const FEATURE_LABEL: Record<string, string> = FEATURE_OPTIONS.reduce(
  (m, f) => ({ ...m, [f.key]: f.label }),
  {} as Record<string, string>,
);

// 判断指定 provider + model 是否支持某功能（与移动端 ai_model_config.dart 对齐）
function isVisionModel(provider: string, model: string): boolean {
  if (!model) return false;
  const lower = model.toLowerCase();
  switch (provider) {
    case 'qwen':
      return lower.includes('-vl-') ||
        lower.startsWith('qwen-vl-') ||
        lower.startsWith('qwen2-vl-') ||
        lower.startsWith('qwen2.5-vl-') ||
        lower.startsWith('qwen3-vl-');
    case 'openai':
      return lower.startsWith('gpt-4o') ||
        lower.startsWith('gpt-4.1') ||
        lower.startsWith('o1') ||
        lower.startsWith('o3');
    case 'gemini':
      return true;
    case 'anthropic':
      return lower.startsWith('claude-');
    case 'grok':
      return lower.startsWith('grok-3') || lower.includes('vision');
    case 'custom':
      return lower.includes('vl') ||
        lower.includes('vision') ||
        lower.startsWith('gpt-4o') ||
        lower.startsWith('gpt-4.1') ||
        lower.startsWith('gemini');
    default:
      return false;
  }
}

function isModelCompatibleWithFeature(
  provider: string,
  model: string,
  feature: SupportedFeature,
): boolean {
  // 'all' 是特殊标记，不在这里判断
  if (feature === 'all') return true;
  // 只有图像识别需要精确到模型；其他功能保持 provider 级判断
  if (feature !== 'imageRecognition') return true;
  return isVisionModel(provider, model);
}

function getFeatureCompatibilityHint(provider: string, model: string): string {
  if (!model) return '请先输入模型名称';
  const supportsImage = isVisionModel(provider, model);
  if (supportsImage) {
    return `当前模型 ${model} 支持图像识别`;
  }
  return `当前模型 ${model} 不支持图像识别。Qwen 视觉模型命名示例：qwen3-vl-plus、qwen-vl-plus、qwen-vl-max`;
}

const FEATURE_COLOR: Record<string, 'primary' | 'secondary' | 'success' | 'warning' | 'danger' | 'default'> = {
  textAnalysis: 'primary',
  speechTranscribe: 'secondary',
  speechRealtime: 'success',
  speechOffline: 'warning',
  imageRecognition: 'danger',
  all: 'default',
};

// 测试用例 - 每个功能预设的测试数据
interface TestCase {
  name: string;
  desc: string;
  data: { testText?: string; testImageUrl?: string; testAudioUrl?: string };
}
const TEST_CASES: Record<SupportedFeature, TestCase[]> = {
  textAnalysis: [
    { name: 'Ping（最小调用）', desc: '使用 max_tokens=1 验证连通性，零成本', data: { testText: 'ping' } },
    { name: '中文摘要', desc: '让模型总结一段中文文本', data: { testText: '请用一句话总结：人工智能正在改变我们的生活方式，从智能手机到自动驾驶，AI 的应用无处不在。' } },
    { name: '中英翻译', desc: '让模型把英文翻译成中文', data: { testText: '请把以下英文翻译成中文：Hello, how are you today?' } },
    { name: '关键词提取', desc: '让模型从文本中提取关键词', data: { testText: '请从这段文本中提取 3 个关键词：可再生能源包括太阳能、风能、水能和地热能，是未来能源结构转型的关键。' } },
  ],
  speechTranscribe: [
    { name: '短音频转写', desc: '上传一段短音频测试', data: { testAudioUrl: 'https://dashscope.oss-cn-beijing.aliyuncs.com/samples/audio/paraFeeling-happy.mp3' } },
  ],
  speechRealtime: [
    { name: 'WebSocket 鉴权', desc: '仅验证 WebSocket 鉴权和连接建立', data: {} },
  ],
  speechOffline: [
    { name: '本地音频文件', desc: '上传 OSS 公开音频文件', data: { testAudioUrl: 'https://dashscope.oss-cn-beijing.aliyuncs.com/samples/audio/paraFeeling-happy.mp3' } },
  ],
  imageRecognition: [
    { name: '1x1 透明 PNG（最小）', desc: '最小成本测试，验证 API 接收图片', data: { testImageUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=' } },
    { name: '公共测试图', desc: '用阿里云示例图片测试', data: { testImageUrl: 'https://dashscope.oss-cn-beijing.aliyuncs.com/images/256_1.png' } },
  ],
  all: [],
};

const STATUS_COLORS: Record<string, { color: string; bg: string; text: string }> = {
  active: { color: 'success', bg: 'bg-green-100', text: 'text-green-700' },
  inactive: { color: 'warning', bg: 'bg-yellow-100', text: 'text-yellow-700' },
  expired: { color: 'danger', bg: 'bg-red-100', text: 'text-red-700' },
  revoked: { color: 'default', bg: 'bg-gray-100', text: 'text-gray-700' },
};

const STATUS_LABELS: Record<string, string> = {
  active: '活跃',
  inactive: '停用',
  expired: '过期',
  revoked: '吊销',
};

export default function ApiKeysPage() {
  const [apiKeys, setApiKeys] = useState<ApiKey[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showViewModal, setShowViewModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [showJsonModal, setShowJsonModal] = useState(false);
  const [showTestModal, setShowTestModal] = useState(false);
  const [selectedKey, setSelectedKey] = useState<ApiKey | null>(null);
  const [copiedId, setCopiedId] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [deleteLoading, setDeleteLoading] = useState(false);
  const [testing, setTesting] = useState(false);
  const [testResult, setTestResult] = useState<any>(null);
  const [stats, setStats] = useState<any>(null);

  const [newKey, setNewKey] = useState({
    provider: 'qwen',
    name: '',
    description: '',
    model: '',
    apiKey: '',
    apiSecret: '',
    baseUrl: '',
    rateLimitPerMin: 60,
    maxConcurrentRequests: 5,
    dailyQuota: 1000,
    scopes: ['all'],
    expiresAt: '',
    supportedFeatures: [] as SupportedFeature[],
  });

  const [testFeature, setTestFeature] = useState<'connectivity' | SupportedFeature>('connectivity');
  const [testText, setTestText] = useState('ping');
  const [testImageUrl, setTestImageUrl] = useState('');

  const [jsonInput, setJsonInput] = useState('');
  const [jsonError, setJsonError] = useState<string | null>(null);

  const fetchApiKeys = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [keysData, statsData] = await Promise.all([
        apiKeyAPI.getApiKeys(),
        apiKeyAPI.getApiKeyStats(),
      ]);
      setApiKeys(keysData);
      setStats(statsData);
    } catch (err: any) {
      setError(err?.response?.data?.message || '获取 API Key 列表失败，请稍后重试');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchApiKeys();
  }, [fetchApiKeys]);

  const filteredKeys = apiKeys.filter(
    (key) =>
      key.provider.toLowerCase().includes(searchTerm.toLowerCase()) ||
      key.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      key.model.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleAddKey = async () => {
    if (!newKey.name.trim() || !newKey.model.trim() || !newKey.apiKey.trim()) return;
    setSubmitting(true);
    try {
      await apiKeyAPI.createApiKey({
        provider: newKey.provider as ApiKeyProvider,
        name: newKey.name.trim(),
        description: newKey.description.trim() || undefined,
        model: newKey.model.trim(),
        apiKey: newKey.apiKey.trim(),
        apiSecret: newKey.apiSecret.trim() || undefined,
        baseUrl: newKey.baseUrl.trim() || undefined,
        rateLimitPerMin: newKey.rateLimitPerMin,
        maxConcurrentRequests: newKey.maxConcurrentRequests,
        dailyQuota: newKey.dailyQuota,
        scopes: newKey.scopes as ApiKeyScope[],
        expiresAt: newKey.expiresAt || undefined,
        supportedFeatures: newKey.supportedFeatures,
      });
      await fetchApiKeys();
      setShowAddModal(false);
      resetNewKey();
    } catch (err: any) {
      setError(err?.response?.data?.message || '创建 API Key 失败');
    } finally {
      setSubmitting(false);
    }
  };

  const handleJsonImport = async () => {
    setJsonError(null);
    try {
      const data = JSON.parse(jsonInput);
      const keys = Array.isArray(data) ? data : [data];
      
      setSubmitting(true);
      const results = await apiKeyAPI.batchCreateApiKeys(keys);
      
      const successCount = results.filter(r => r.success).length;
      const failCount = results.filter(r => !r.success).length;
      
      if (failCount > 0) {
        const failures = results.filter(r => !r.success).map(r => `${r.name}: ${r.error}`).join('\n');
        setError(`批量导入完成：${successCount} 成功，${failCount} 失败\n${failures}`);
      } else {
        setError(null);
      }
      
      await fetchApiKeys();
      setShowJsonModal(false);
      setJsonInput('');
    } catch (err: any) {
      setJsonError(err?.message || 'JSON 格式错误');
    } finally {
      setSubmitting(false);
    }
  };

  const handleTestKey = async (
    key: ApiKey,
    feature: 'connectivity' | SupportedFeature = 'connectivity',
    testData: { testText?: string; testImageUrl?: string } = {},
  ) => {
    setSelectedKey(key);
    setShowTestModal(true);
    setTesting(true);
    setTestResult(null);
    setTestFeature(feature);
    setTestText(testData.testText ?? 'ping');
    setTestImageUrl(testData.testImageUrl ?? '');

    try {
      const payload: any = { feature };
      if (feature === 'textAnalysis' && testData.testText) payload.testText = testData.testText;
      if (feature === 'imageRecognition' && testData.testImageUrl) payload.testImageUrl = testData.testImageUrl;
      const result = await apiKeyAPI.testApiKey(key.id, payload);
      setTestResult(result?.data ?? result);
    } catch (err: any) {
      setTestResult({ status: 'error', error: err?.response?.data?.message || '测试失败' });
    } finally {
      setTesting(false);
    }
  };

  const openDeleteModal = (key: ApiKey) => {
    setSelectedKey(key);
    setShowDeleteModal(true);
  };

  const openEdit = (key: ApiKey) => {
    setSelectedKey(key);
    setNewKey({
      provider: key.provider,
      name: key.name,
      description: key.description || '',
      model: key.model,
      apiKey: '',
      apiSecret: '',
      baseUrl: key.baseUrl || '',
      rateLimitPerMin: key.rateLimitPerMin,
      maxConcurrentRequests: key.maxConcurrentRequests,
      dailyQuota: key.dailyQuota,
      scopes: key.scopes || ['all'],
      expiresAt: key.expiresAt ? new Date(key.expiresAt).toISOString().split('T')[0] : '',
      supportedFeatures: (key.supportedFeatures || []) as SupportedFeature[],
    });
    setShowEditModal(true);
  };

  const handleEditKey = async () => {
    if (!selectedKey) return;
    setSubmitting(true);
    try {
      await apiKeyAPI.updateApiKey(selectedKey.id, {
        provider: newKey.provider as ApiKeyProvider,
        name: newKey.name,
        description: newKey.description,
        model: newKey.model,
        apiKey: newKey.apiKey || undefined,
        apiSecret: newKey.apiSecret || undefined,
        baseUrl: newKey.baseUrl || undefined,
        rateLimitPerMin: newKey.rateLimitPerMin,
        maxConcurrentRequests: newKey.maxConcurrentRequests,
        dailyQuota: newKey.dailyQuota,
        scopes: newKey.scopes as ApiKeyScope[],
        expiresAt: newKey.expiresAt || undefined,
        supportedFeatures: newKey.supportedFeatures,
      });
      await fetchApiKeys();
      setShowEditModal(false);
      setSelectedKey(null);
      resetNewKey();
    } catch (err: any) {
      setError(err?.response?.data?.message || '更新 API Key 失败');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteKey = async () => {
    if (!selectedKey) return;
    setDeleteLoading(true);
    try {
      await apiKeyAPI.deleteApiKey(selectedKey.id);
      await fetchApiKeys();
      setShowDeleteModal(false);
      setSelectedKey(null);
    } catch (err: any) {
      setError(err?.response?.data?.message || '删除 API Key 失败');
    } finally {
      setDeleteLoading(false);
    }
  };

  const handleCopy = (id: string) => {
    if (typeof navigator !== 'undefined') {
      navigator.clipboard.writeText(id);
      setCopiedId(id);
      setTimeout(() => setCopiedId(null), 2000);
    }
  };

  const handleView = (key: ApiKey) => {
    setSelectedKey(key);
    setShowViewModal(true);
  };

  const resetNewKey = () => {
    setNewKey({
      provider: 'qwen',
      name: '',
      description: '',
      model: '',
      apiKey: '',
      apiSecret: '',
      baseUrl: '',
      rateLimitPerMin: 60,
      maxConcurrentRequests: 5,
      dailyQuota: 1000,
      scopes: ['all'],
      expiresAt: '',
      supportedFeatures: [],
    });
  };

  const formatDate = (dateStr?: string) => {
    if (!dateStr) return '无';
    try {
      return new Date(dateStr).toLocaleDateString('zh-CN');
    } catch {
      return dateStr;
    }
  };

  const getJsonExample = () => {
    return JSON.stringify([
      {
        provider: 'qwen',
        name: '通义千问主Key',
        description: '用于语音识别和摘要',
        apiKey: 'sk-your-api-key-here',
        apiSecret: 'your-secret-here',
        model: 'qwen-max',
        baseUrl: 'https://dashscope.aliyuncs.com/api/v1',
        rateLimitPerMin: 60,
        maxConcurrentRequests: 5,
        dailyQuota: 1000,
        scopes: ['transcription', 'summary'],
        status: 'active',
      },
      {
        provider: 'openai',
        name: 'OpenAI备用Key',
        apiKey: 'sk-your-openai-key-here',
        model: 'gpt-4',
        rateLimitPerMin: 30,
        scopes: ['chat', 'summary'],
      }
    ], null, 2);
  };

  return (
    <Layout currentPage="api-keys">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-semibold text-gray-900">API Key 管理</h1>
            <p className="text-gray-500 mt-1 flex items-center gap-2">
              <Shield className="w-4 h-4" />
              安全地管理第三方服务的 API Key
            </p>
          </div>
          <div className="flex items-center gap-2">
            <Button
              variant="light"
              className="flex items-center gap-2"
              onClick={() => {
                setJsonInput(getJsonExample());
                setShowJsonModal(true);
              }}
            >
              <FileJson className="w-4 h-4" />
              JSON 导入
            </Button>
            <Button
              color="primary"
              className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white"
              onClick={() => setShowAddModal(true)}
            >
              <Plus className="w-4 h-4" />
              添加 Key
            </Button>
          </div>
        </div>

        {/* Stats Cards */}
        {stats && (
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Card className="bg-white border border-gray-100">
              <CardBody className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-500">总 Key 数</p>
                    <p className="text-2xl font-semibold text-gray-900">{stats.total}</p>
                  </div>
                  <Key className="w-8 h-8 text-blue-500" />
                </div>
              </CardBody>
            </Card>
            <Card className="bg-white border border-gray-100">
              <CardBody className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-500">活跃</p>
                    <p className="text-2xl font-semibold text-green-600">{stats.active}</p>
                  </div>
                  <Activity className="w-8 h-8 text-green-500" />
                </div>
              </CardBody>
            </Card>
            <Card className="bg-white border border-gray-100">
              <CardBody className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-500">停用</p>
                    <p className="text-2xl font-semibold text-yellow-600">{stats.inactive}</p>
                  </div>
                  <AlertCircle className="w-8 h-8 text-yellow-500" />
                </div>
              </CardBody>
            </Card>
            <Card className="bg-white border border-gray-100">
              <CardBody className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-500">过期</p>
                    <p className="text-2xl font-semibold text-red-600">{stats.expired}</p>
                  </div>
                  <AlertCircle className="w-8 h-8 text-red-500" />
                </div>
              </CardBody>
            </Card>
          </div>
        )}

        {/* Error Alert */}
        {error && (
          <Card className="bg-red-50 border border-red-200">
            <CardBody className="p-4 flex items-center gap-3">
              <AlertCircle className="w-5 h-5 text-red-500 shrink-0" />
              <p className="text-red-700 text-sm whitespace-pre-line">{error}</p>
              <Button size="sm" variant="light" className="ml-auto text-red-600" onClick={() => setError(null)}>
                关闭
              </Button>
            </CardBody>
          </Card>
        )}

        {/* Search Card */}
        <Card className="bg-white border border-gray-100">
          <CardBody className="p-4">
            <div className="flex items-center gap-4">
              <div className="relative flex-1">
                <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <Input
                  placeholder="搜索提供商、名称或模型..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-12"
                  classNames={{
                    inputWrapper: 'bg-gray-50 border border-gray-200 rounded-xl',
                  }}
                />
              </div>
            </div>
          </CardBody>
        </Card>

        {/* Table Card */}
        <Card className="bg-white border border-gray-100">
          <CardBody className="p-0">
            {loading ? (
              <div className="flex items-center justify-center py-20">
                <Spinner size="lg" color="primary" />
                <span className="ml-3 text-gray-500">加载中...</span>
              </div>
            ) : (
              <Table aria-label="API Key 列表">
                <TableHeader>
                  <TableColumn className="bg-gray-50/80">名称</TableColumn>
                  <TableColumn className="bg-gray-50/80">提供商</TableColumn>
                  <TableColumn className="bg-gray-50/80">模型</TableColumn>
                  <TableColumn className="bg-gray-50/80">支持功能</TableColumn>
                  <TableColumn className="bg-gray-50/80">速率限制</TableColumn>
                  <TableColumn className="bg-gray-50/80">并发</TableColumn>
                  <TableColumn className="bg-gray-50/80">日配额</TableColumn>
                  <TableColumn className="bg-gray-50/80">状态</TableColumn>
                  <TableColumn className="bg-gray-50/80">健康</TableColumn>
                  <TableColumn className="bg-gray-50/80">操作</TableColumn>
                </TableHeader>
                <TableBody emptyContent="暂无 API Key">
                  {filteredKeys.map((key) => (
                    <TableRow key={key.id} className="hover:bg-gray-50 transition-colors">
                      <TableCell>
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
                            <Key className="w-5 h-5 text-blue-600" />
                          </div>
                          <div>
                            <span className="font-semibold text-gray-800">{key.name}</span>
                            {key.description && (
                              <p className="text-xs text-gray-500">{key.description}</p>
                            )}
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <span className="font-medium text-gray-700 capitalize">{key.provider}</span>
                      </TableCell>
                      <TableCell>
                        <span className="text-gray-600">{key.model}</span>
                      </TableCell>
                      <TableCell>
                        <div className="flex flex-wrap gap-1 max-w-[200px]">
                          {(key.supportedFeatures && key.supportedFeatures.length > 0) ? (
                            key.supportedFeatures.map((f) => (
                              <Chip
                                key={f}
                                size="sm"
                                variant="flat"
                                color={FEATURE_COLOR[f] || 'default'}
                                className="text-xs"
                              >
                                {FEATURE_LABEL[f] || f}
                              </Chip>
                            ))
                          ) : (
                            <span className="text-gray-400 text-xs italic">未配置</span>
                          )}
                        </div>
                      </TableCell>
                      <TableCell>
                        <span className="text-gray-600">{key.rateLimitPerMin}/分钟</span>
                      </TableCell>
                      <TableCell>
                        <span className="text-gray-600">{key.maxConcurrentRequests}</span>
                      </TableCell>
                      <TableCell>
                        <span className="text-gray-600">{key.dailyUsage}/{key.dailyQuota}</span>
                      </TableCell>
                      <TableCell>
                        <Chip
                          color={STATUS_COLORS[key.status]?.color as any || 'default'}
                          size="sm"
                          className={`${STATUS_COLORS[key.status]?.bg} ${STATUS_COLORS[key.status]?.text} border`}
                        >
                          {STATUS_LABELS[key.status] || key.status}
                        </Chip>
                      </TableCell>
                      <TableCell>
                        {key.lastHealthCheckStatus ? (
                          <Chip
                            color={key.lastHealthCheckStatus === 'healthy' ? 'success' : 'danger'}
                            size="sm"
                            className={
                              key.lastHealthCheckStatus === 'healthy'
                                ? 'bg-green-100 text-green-700'
                                : 'bg-red-100 text-red-700'
                            }
                          >
                            {key.lastHealthCheckStatus === 'healthy' ? '正常' : '异常'}
                          </Chip>
                        ) : (
                          <span className="text-gray-400 text-sm">未测试</span>
                        )}
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-1">
                          <Button
                            size="sm"
                            variant="light"
                            color="primary"
                            onClick={() => handleView(key)}
                            className="hover:bg-gray-50"
                            isIconOnly
                            aria-label="查看详情"
                          >
                            <Eye className="w-4 h-4" />
                          </Button>
                          <Button
                            size="sm"
                            variant="light"
                            color="warning"
                            onClick={() => openEdit(key)}
                            className="hover:bg-yellow-50"
                            isIconOnly
                            aria-label="编辑"
                          >
                            <Edit className="w-4 h-4" />
                          </Button>
                          <Button
                            size="sm"
                            variant="light"
                            color="success"
                            onClick={() => handleTestKey(key)}
                            className="hover:bg-green-50"
                            isIconOnly
                            aria-label="测试连通性"
                          >
                            <TestTube className="w-4 h-4" />
                          </Button>
                          <Button
                            size="sm"
                            variant="light"
                            color="danger"
                            onClick={() => openDeleteModal(key)}
                            className="hover:bg-red-50"
                            isIconOnly
                            aria-label="删除"
                          >
                            <Trash2 className="w-4 h-4" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardBody>
        </Card>

        {/* Add Modal */}
        <Modal
          isOpen={showAddModal}
          onClose={() => {
            setShowAddModal(false);
            resetNewKey();
          }}
          classNames={{ base: 'rounded-xl' }}
          size="2xl"
        >
          <ModalContent>
            <ModalHeader className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
                <Plus className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <p className="text-lg font-bold text-gray-800">添加新 API Key</p>
                <p className="text-sm text-gray-500">配置第三方服务访问</p>
              </div>
            </ModalHeader>
            <ModalBody>
              <Tabs aria-label="添加方式">
                <Tab key="form" title="表单填写">
                  <div className="space-y-4 mt-4">
                    <div className="grid grid-cols-2 gap-4">
                      <Select
                        label="提供商"
                        selectedKeys={[newKey.provider]}
                        onChange={(e) => {
                          const provider = e.target.value;
                          setNewKey((prev) => {
                            const next = { ...prev, provider };
                            // provider 切换时自动移除不兼容的功能勾选
                            const filtered = next.supportedFeatures.filter(
                              (f) => f === 'all' || isModelCompatibleWithFeature(provider, next.model, f)
                            );
                            return { ...next, supportedFeatures: filtered };
                          });
                        }}
                        classNames={{ trigger: 'rounded-xl' }}
                      >
                        {PROVIDER_OPTIONS.map((p) => (
                          <SelectItem key={p.key} value={p.key}>
                            {p.label}
                          </SelectItem>
                        ))}
                      </Select>
                      <Input
                        label="名称"
                        placeholder="如：通义千问主Key"
                        value={newKey.name}
                        onChange={(e) => setNewKey({ ...newKey, name: e.target.value })}
                        classNames={{ inputWrapper: 'rounded-xl' }}
                        isRequired
                      />
                    </div>
                    <Input
                      label="描述"
                      placeholder="用途说明（可选）"
                      value={newKey.description}
                      onChange={(e) => setNewKey({ ...newKey, description: e.target.value })}
                      classNames={{ inputWrapper: 'rounded-xl' }}
                    />
                    <Input
                      label="模型名称"
                      placeholder="如: qwen-max / qwen3-vl-plus"
                      value={newKey.model}
                      onChange={(e) => {
                        const model = e.target.value;
                        setNewKey((prev) => {
                          const next = { ...prev, model };
                          // 模型变化时自动移除不兼容的功能勾选
                          const filtered = next.supportedFeatures.filter(
                            (f) => f === 'all' || isModelCompatibleWithFeature(next.provider, model, f)
                          );
                          return { ...next, supportedFeatures: filtered };
                        });
                      }}
                      classNames={{ inputWrapper: 'rounded-xl' }}
                      isRequired
                    />
                    <Input
                      label="API Key"
                      type="password"
                      placeholder="输入 API Key"
                      value={newKey.apiKey}
                      onChange={(e) => setNewKey({ ...newKey, apiKey: e.target.value })}
                      classNames={{ inputWrapper: 'rounded-xl' }}
                      isRequired
                    />
                    <Input
                      label="API Secret（可选）"
                      type="password"
                      placeholder="部分平台需要"
                      value={newKey.apiSecret}
                      onChange={(e) => setNewKey({ ...newKey, apiSecret: e.target.value })}
                      classNames={{ inputWrapper: 'rounded-xl' }}
                    />
                    <Input
                      label="Base URL（可选）"
                      placeholder="自定义 API 地址"
                      value={newKey.baseUrl}
                      onChange={(e) => setNewKey({ ...newKey, baseUrl: e.target.value })}
                      classNames={{ inputWrapper: 'rounded-xl' }}
                    />
                    <div className="grid grid-cols-3 gap-4">
                      <Input
                        label="速率限制（/分钟）"
                        type="number"
                        value={String(newKey.rateLimitPerMin)}
                        onChange={(e) =>
                          setNewKey({ ...newKey, rateLimitPerMin: parseInt(e.target.value) || 60 })
                        }
                        classNames={{ inputWrapper: 'rounded-xl' }}
                      />
                      <Input
                        label="最大并发"
                        type="number"
                        value={String(newKey.maxConcurrentRequests)}
                        onChange={(e) =>
                          setNewKey({ ...newKey, maxConcurrentRequests: parseInt(e.target.value) || 5 })
                        }
                        classNames={{ inputWrapper: 'rounded-xl' }}
                      />
                      <Input
                        label="日配额"
                        type="number"
                        value={String(newKey.dailyQuota)}
                        onChange={(e) =>
                          setNewKey({ ...newKey, dailyQuota: parseInt(e.target.value) || 1000 })
                        }
                        classNames={{ inputWrapper: 'rounded-xl' }}
                      />
                    </div>
                    <Input
                      label="过期时间（可选）"
                      type="date"
                      value={newKey.expiresAt}
                      onChange={(e) => setNewKey({ ...newKey, expiresAt: e.target.value })}
                      classNames={{ inputWrapper: 'rounded-xl' }}
                    />

                    {/* 功能支持（多选） */}
                    <div className="p-4 bg-gradient-to-br from-blue-50/60 to-indigo-50/40 border border-blue-100 rounded-xl">
                      <div className="flex items-center gap-2 mb-2">
                        <Brain className="w-4 h-4 text-blue-600" />
                        <span className="text-sm font-semibold text-gray-800">支持的功能（多选）</span>
                        <span className="text-xs text-gray-500">· 用于套餐编辑时按功能过滤</span>
                      </div>
                      <p className="text-xs text-gray-500 mb-3">
                        勾选此 API Key 实际能调用的能力。套餐编辑页面将只展示能匹配所选功能的 API。
                      </p>
                      <p className={`text-xs mb-3 ${isVisionModel(newKey.provider, newKey.model) ? 'text-green-600' : 'text-orange-500'}`}>
                        {getFeatureCompatibilityHint(newKey.provider, newKey.model)}
                      </p>
                      <CheckboxGroup
                        value={newKey.supportedFeatures}
                        onValueChange={(v) => setNewKey({ ...newKey, supportedFeatures: v as SupportedFeature[] })}
                        orientation="horizontal"
                        classNames={{ wrapper: 'gap-2' }}
                      >
                        {FEATURE_OPTIONS.map((f) => {
                          const Icon = f.icon;
                          const compatible = isModelCompatibleWithFeature(newKey.provider, newKey.model, f.key);
                          return (
                            <Checkbox
                              key={f.key}
                              value={f.key}
                              isDisabled={!compatible}
                              classNames={{
                                base: `max-w-full m-0 border border-gray-200 rounded-lg p-2 hover:bg-white data-[selected=true]:bg-blue-50 data-[selected=true]:border-blue-300 ${!compatible ? 'opacity-50' : ''}`,
                                label: 'text-xs',
                              }}
                            >
                              <div className="flex items-center gap-1.5">
                                <Icon className="w-3.5 h-3.5 text-blue-600" />
                                <span className="font-medium">{f.label}</span>
                                {!compatible && <span className="text-[10px] text-orange-500">(模型不支持)</span>}
                              </div>
                            </Checkbox>
                          );
                        })}
                      </CheckboxGroup>
                    </div>
                  </div>
                </Tab>
                <Tab key="json" title="JSON 导入">
                  <div className="space-y-4 mt-4">
                    <p className="text-sm text-gray-500">
                      粘贴 JSON 格式数据，支持单条或数组格式
                    </p>
                    <Textarea
                      placeholder={getJsonExample()}
                      value={jsonInput}
                      onChange={(e) => setJsonInput(e.target.value)}
                      classNames={{ inputWrapper: 'rounded-xl min-h-[300px]' }}
                    />
                  </div>
                </Tab>
              </Tabs>
            </ModalBody>
            <ModalFooter>
              <Button
                variant="light"
                onClick={() => {
                  setShowAddModal(false);
                  resetNewKey();
                }}
                className="hover:bg-gray-100 rounded-xl"
              >
                取消
              </Button>
              <Button
                color="primary"
                className="bg-blue-600 hover:bg-blue-700 rounded-xl"
                onClick={handleAddKey}
                isLoading={submitting}
                isDisabled={!newKey.name.trim() || !newKey.model.trim() || !newKey.apiKey.trim()}
              >
                创建
              </Button>
            </ModalFooter>
          </ModalContent>
        </Modal>

        {/* JSON Import Modal */}
        <Modal
          isOpen={showJsonModal}
          onClose={() => {
            setShowJsonModal(false);
            setJsonInput('');
            setJsonError(null);
          }}
          classNames={{ base: 'rounded-xl' }}
          size="2xl"
        >
          <ModalContent>
            <ModalHeader className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
                <FileJson className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <p className="text-lg font-bold text-gray-800">JSON 批量导入</p>
                <p className="text-sm text-gray-500">支持单条或数组格式</p>
              </div>
            </ModalHeader>
            <ModalBody>
              <div className="space-y-4">
                <p className="text-sm text-gray-500">
                  粘贴 JSON 数据，格式示例：
                </p>
                <pre className="bg-gray-50 p-4 rounded-xl text-xs text-gray-600 overflow-auto max-h-40">
                  {getJsonExample()}
                </pre>
                <Textarea
                  placeholder="粘贴 JSON 数据..."
                  value={jsonInput}
                  onChange={(e) => {
                    setJsonInput(e.target.value);
                    setJsonError(null);
                  }}
                  classNames={{ inputWrapper: 'rounded-xl min-h-[200px]' }}
                />
                {jsonError && (
                  <p className="text-red-500 text-sm">{jsonError}</p>
                )}
              </div>
            </ModalBody>
            <ModalFooter>
              <Button
                variant="light"
                onClick={() => {
                  setShowJsonModal(false);
                  setJsonInput('');
                  setJsonError(null);
                }}
                className="hover:bg-gray-100 rounded-xl"
              >
                取消
              </Button>
              <Button
                color="primary"
                className="bg-blue-600 hover:bg-blue-700 rounded-xl"
                onClick={handleJsonImport}
                isLoading={submitting}
                isDisabled={!jsonInput.trim()}
              >
                导入
              </Button>
            </ModalFooter>
          </ModalContent>
        </Modal>

        {/* Test Modal */}
        <Modal
          isOpen={showTestModal}
          onClose={() => {
            setShowTestModal(false);
            setTestResult(null);
            setTestFeature('connectivity');
            setTestText('ping');
            setTestImageUrl('');
          }}
          classNames={{ base: 'rounded-xl' }}
          size="2xl"
          scrollBehavior="inside"
        >
          <ModalContent>
            <ModalHeader className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
                <TestTube className="w-5 h-5 text-blue-600" />
              </div>
              <div className="flex-1">
                <p className="text-lg font-bold text-gray-800">功能连通性测试</p>
                <p className="text-sm text-gray-500">
                  {selectedKey?.name} · {selectedKey?.provider} · {selectedKey?.model}
                </p>
              </div>
            </ModalHeader>
            <ModalBody>
              {/* 功能选择 */}
              <div>
                <p className="text-sm font-semibold text-gray-700 mb-2">选择测试功能</p>
                <RadioGroup
                  value={testFeature}
                  onValueChange={(v) => setTestFeature(v as any)}
                  orientation="horizontal"
                  classNames={{ wrapper: 'gap-2' }}
                  isDisabled={testing}
                >
                  <Radio value="connectivity" size="sm">
                    <span className="text-sm">仅连通性</span>
                  </Radio>
                  {FEATURE_OPTIONS.filter((f) => f.key !== 'all').map((f) => {
                    const Icon = f.icon;
                    const supported = (selectedKey?.supportedFeatures || []).includes(f.key as SupportedFeature)
                      || (selectedKey?.supportedFeatures || []).includes('all');
                    return (
                      <Radio
                        key={f.key}
                        value={f.key}
                        size="sm"
                        isDisabled={!supported}
                        description={!supported ? '该 API 未声明支持' : undefined}
                      >
                        <div className="flex items-center gap-1.5">
                          <Icon className="w-3.5 h-3.5 text-blue-600" />
                          <span className="text-sm">{f.label}</span>
                        </div>
                      </Radio>
                    );
                  })}
                </RadioGroup>
                {selectedKey?.supportedFeatures && selectedKey.supportedFeatures.length > 0 && (
                  <p className="text-xs text-gray-500 mt-2">
                    💡 提示：此 API 已声明支持{' '}
                    <span className="font-semibold text-blue-700">
                      {selectedKey.supportedFeatures.map((f) => FEATURE_LABEL[f] || f).join('、')}
                    </span>
                    ，未声明的功能测试结果可能不准确。
                  </p>
                )}
              </div>

              {/* 测试用例（预设数据） */}
              {testFeature !== 'connectivity' && (
                <div className="p-3 bg-gradient-to-br from-indigo-50/60 to-purple-50/40 border border-indigo-100 rounded-lg">
                  <div className="flex items-center gap-2 mb-2">
                    <FileText className="w-4 h-4 text-indigo-600" />
                    <span className="text-sm font-semibold text-gray-800">测试用例</span>
                    <span className="text-xs text-gray-500">· 一键填入预设测试数据</span>
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-1.5">
                    {(TEST_CASES[testFeature as SupportedFeature] || []).map((tc, i) => (
                      <button
                        key={i}
                        type="button"
                        disabled={testing}
                        onClick={() => {
                          setTestText(tc.data.testText || '');
                          setTestImageUrl(tc.data.testImageUrl || '');
                        }}
                        className="text-left p-2 bg-white border border-gray-200 rounded hover:border-indigo-400 hover:bg-indigo-50 transition-colors disabled:opacity-50"
                      >
                        <div className="text-xs font-semibold text-gray-800">{tc.name}</div>
                        <div className="text-[10px] text-gray-500 mt-0.5 line-clamp-1">{tc.desc}</div>
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* 测试数据输入（仅特定功能） */}
              {testFeature === 'textAnalysis' && (
                <Input
                  label="测试文本"
                  placeholder="请输入要测试的文本（默认 ping）"
                  value={testText}
                  onChange={(e) => setTestText(e.target.value)}
                  size="sm"
                  classNames={{ inputWrapper: 'rounded-xl' }}
                  description="将以 max_tokens=1 调用一次 chat/completions 验证连通性"
                />
              )}
              {testFeature === 'imageRecognition' && (
                <Input
                  label="测试图片 URL（可选）"
                  placeholder="留空将使用 1x1 透明 PNG"
                  value={testImageUrl}
                  onChange={(e) => setTestImageUrl(e.target.value)}
                  size="sm"
                  classNames={{ inputWrapper: 'rounded-xl' }}
                  description="支持 http(s) URL 或 data:image/png;base64,..."
                />
              )}

              {testing ? (
                <div className="flex items-center justify-center py-10">
                  <Spinner size="lg" color="primary" />
                  <span className="ml-3 text-gray-500">测试中...</span>
                </div>
              ) : testResult ? (
                <div className="space-y-3 mt-2">
                  {/* 总体状态 */}
                  <div
                    className={`p-4 rounded-xl ${
                      testResult.status === 'healthy'
                        ? 'bg-green-50 border border-green-200'
                        : testResult.status === 'degraded'
                        ? 'bg-yellow-50 border border-yellow-200'
                        : 'bg-red-50 border border-red-200'
                    }`}
                  >
                    <div className="flex items-center gap-2">
                      {testResult.status === 'healthy' ? (
                        <Check className="w-5 h-5 text-green-600" />
                      ) : testResult.status === 'degraded' ? (
                        <AlertCircle className="w-5 h-5 text-yellow-600" />
                      ) : (
                        <AlertCircle className="w-5 h-5 text-red-600" />
                      )}
                      <span
                        className={`font-semibold ${
                          testResult.status === 'healthy'
                            ? 'text-green-800'
                            : testResult.status === 'degraded'
                            ? 'text-yellow-800'
                            : 'text-red-800'
                        }`}
                      >
                        {testResult.status === 'healthy'
                          ? '✓ 测试通过'
                          : testResult.status === 'degraded'
                          ? '⚠ 通过但有警告'
                          : '✗ 测试失败'}
                      </span>
                    </div>
                    {testResult.warnings && testResult.warnings.length > 0 && (
                      <ul className="mt-2 text-xs text-yellow-700 space-y-1">
                        {testResult.warnings.map((w: string, i: number) => (
                          <li key={i}>• {w}</li>
                        ))}
                      </ul>
                    )}
                  </div>

                  {/* 各项检查 */}
                  {testResult.checks && (
                    <div className="space-y-2">
                      {testResult.checks.connectivity && (
                        <div className="p-3 bg-gray-50 rounded-lg">
                          <div className="flex items-center justify-between">
                            <span className="text-sm font-semibold text-gray-700">🔌 鉴权 / 连通性</span>
                            <Chip
                              size="sm"
                              color={testResult.checks.connectivity.ok ? 'success' : 'danger'}
                              variant="flat"
                            >
                              {testResult.checks.connectivity.ok ? 'OK' : 'FAIL'}
                            </Chip>
                          </div>
                          {testResult.checks.connectivity.responseTime && (
                            <p className="text-xs text-gray-500 mt-1">
                              响应时间：{testResult.checks.connectivity.responseTime}ms
                            </p>
                          )}
                          {testResult.checks.connectivity.details && (
                            <pre className="text-xs text-gray-600 mt-1 overflow-auto">
                              {JSON.stringify(testResult.checks.connectivity.details, null, 2)}
                            </pre>
                          )}
                        </div>
                      )}
                      {testResult.checks.feature && (
                        <div className="p-3 bg-blue-50 rounded-lg">
                          <div className="flex items-center justify-between">
                            <span className="text-sm font-semibold text-gray-700">
                              🎯 功能测试（{FEATURE_LABEL[testResult.feature] || testResult.feature}）
                            </span>
                            <Chip
                              size="sm"
                              color={testResult.checks.feature.ok ? 'success' : 'danger'}
                              variant="flat"
                            >
                              {testResult.checks.feature.ok ? 'OK' : 'FAIL'}
                            </Chip>
                          </div>
                          {testResult.checks.feature.responseTime && (
                            <p className="text-xs text-gray-500 mt-1">
                              响应时间：{testResult.checks.feature.responseTime}ms
                            </p>
                          )}
                          {testResult.checks.feature.details && (
                            <pre className="text-xs text-gray-600 mt-1 overflow-auto">
                              {JSON.stringify(testResult.checks.feature.details, null, 2)}
                            </pre>
                          )}
                        </div>
                      )}
                      {testResult.checks.balance && (
                        <div className="p-3 bg-purple-50 rounded-lg">
                          <div className="flex items-center justify-between">
                            <span className="text-sm font-semibold text-gray-700">💰 账户余额</span>
                            <Chip size="sm" color="secondary" variant="flat">
                              {testResult.checks.balance.exhausted ? '已耗尽' : '正常'}
                            </Chip>
                          </div>
                          <p className="text-xs text-gray-600 mt-1">
                            {testResult.checks.balance.total} {testResult.checks.balance.currency || ''}
                          </p>
                        </div>
                      )}
                    </div>
                  )}

                  {testResult.error && (
                    <div className="p-3 bg-red-50 rounded-lg">
                      <p className="text-sm text-red-500 font-semibold">错误信息</p>
                      <p className="text-red-700 text-sm mt-1">{testResult.error}</p>
                    </div>
                  )}
                </div>
              ) : null}
            </ModalBody>
            <ModalFooter>
              <Button
                variant="light"
                onClick={() => {
                  setShowTestModal(false);
                  setTestResult(null);
                  setTestFeature('connectivity');
                  setTestText('ping');
                  setTestImageUrl('');
                }}
                className="hover:bg-gray-100 rounded-xl"
              >
                关闭
              </Button>
              {selectedKey && !testing && (
                <Button
                  color="primary"
                  className="bg-blue-600 hover:bg-blue-700 rounded-xl"
                  onClick={() =>
                    handleTestKey(
                      selectedKey,
                      testFeature,
                      { testText, testImageUrl },
                    )
                  }
                >
                  {testResult ? '重新测试' : '开始测试'}
                </Button>
              )}
            </ModalFooter>
          </ModalContent>
        </Modal>

        {/* View Modal */}
        <Modal
          isOpen={showViewModal}
          onClose={() => setShowViewModal(false)}
          classNames={{ base: 'rounded-xl' }}
          size="2xl"
        >
          <ModalContent>
            <ModalHeader className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
                <Sparkles className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <p className="text-lg font-bold text-gray-800">API Key 详情</p>
                <p className="text-sm text-gray-500">{selectedKey?.name}</p>
              </div>
            </ModalHeader>
            <ModalBody>
              {selectedKey && (
                <div className="space-y-5">
                  <div className="p-3 bg-yellow-50/80 border border-yellow-200/50 rounded-xl flex items-center gap-2">
                    <Shield className="w-5 h-5 text-yellow-600 shrink-0" />
                    <span className="text-sm text-yellow-800">API Key 已加密存储，无法查看原始值</span>
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="p-4 bg-gray-50/80 rounded-xl">
                      <p className="text-sm text-gray-500 mb-1">提供商</p>
                      <p className="font-semibold text-gray-800 capitalize">{selectedKey.provider}</p>
                    </div>
                    <div className="p-4 bg-gray-50/80 rounded-xl">
                      <p className="text-sm text-gray-500 mb-1">模型</p>
                      <p className="font-semibold text-gray-800">{selectedKey.model}</p>
                    </div>
                    <div className="p-4 bg-gray-50/80 rounded-xl">
                      <p className="text-sm text-gray-500 mb-1">速率限制</p>
                      <p className="font-semibold text-gray-800">{selectedKey.rateLimitPerMin}/分钟</p>
                    </div>
                    <div className="p-4 bg-gray-50/80 rounded-xl">
                      <p className="text-sm text-gray-500 mb-1">最大并发</p>
                      <p className="font-semibold text-gray-800">{selectedKey.maxConcurrentRequests}</p>
                    </div>
                    <div className="p-4 bg-gray-50/80 rounded-xl">
                      <p className="text-sm text-gray-500 mb-1">日配额</p>
                      <p className="font-semibold text-gray-800">{selectedKey.dailyUsage}/{selectedKey.dailyQuota}</p>
                    </div>
                    <div className="p-4 bg-gray-50/80 rounded-xl">
                      <p className="text-sm text-gray-500 mb-1">状态</p>
                      <Chip
                        color={STATUS_COLORS[selectedKey.status]?.color as any || 'default'}
                        size="sm"
                        className={`${STATUS_COLORS[selectedKey.status]?.bg} ${STATUS_COLORS[selectedKey.status]?.text}`}
                      >
                        {STATUS_LABELS[selectedKey.status] || selectedKey.status}
                      </Chip>
                    </div>
                    <div className="p-4 bg-gray-50/80 rounded-xl">
                      <p className="text-sm text-gray-500 mb-1">创建时间</p>
                      <p className="font-semibold text-gray-800">{formatDate(selectedKey.createdAt)}</p>
                    </div>
                    <div className="p-4 bg-gray-50/80 rounded-xl">
                      <p className="text-sm text-gray-500 mb-1">过期时间</p>
                      <p className="font-semibold text-gray-800">{formatDate(selectedKey.expiresAt)}</p>
                    </div>
                    <div className="p-4 bg-gray-50/80 rounded-xl">
                      <p className="text-sm text-gray-500 mb-1">最后使用</p>
                      <p className="font-semibold text-gray-800">{formatDate(selectedKey.lastUsedAt)}</p>
                    </div>
                    <div className="p-4 bg-gray-50/80 rounded-xl">
                      <p className="text-sm text-gray-500 mb-1">健康检查</p>
                      <p className="font-semibold text-gray-800">
                        {selectedKey.lastHealthCheckStatus === 'healthy' ? '正常' : 
                         selectedKey.lastHealthCheckStatus === 'unhealthy' ? '异常' : '未测试'}
                      </p>
                    </div>
                    <div className="p-4 bg-gray-50/80 rounded-xl col-span-2">
                      <p className="text-sm text-gray-500 mb-2">支持的功能</p>
                      {(selectedKey.supportedFeatures && selectedKey.supportedFeatures.length > 0) ? (
                        <div className="flex flex-wrap gap-1.5">
                          {selectedKey.supportedFeatures.map((f) => (
                            <Chip
                              key={f}
                              size="sm"
                              variant="flat"
                              color={FEATURE_COLOR[f] || 'default'}
                            >
                              {FEATURE_LABEL[f] || f}
                            </Chip>
                          ))}
                        </div>
                      ) : (
                        <p className="text-sm text-gray-400 italic">
                          ⚠️ 未配置。套餐编辑时此 API 将出现在所有功能的下拉中，可能导致不匹配
                        </p>
                      )}
                    </div>
                    <div className="p-4 bg-gray-50/80 rounded-xl col-span-2">
                      <p className="text-sm text-gray-500 mb-1">Key ID</p>
                      <div className="flex items-center gap-2">
                        <p className="font-mono text-sm bg-gray-200/50 px-2 py-1 rounded truncate max-w-[300px]">
                          {selectedKey.id}
                        </p>
                        <Button
                          size="sm"
                          variant="light"
                          onClick={() => handleCopy(selectedKey.id)}
                          className="hover:bg-gray-100 shrink-0"
                        >
                          {copiedId === selectedKey.id ? (
                            <Check className="w-4 h-4 text-green-500" />
                          ) : (
                            <Copy className="w-4 h-4" />
                          )}
                        </Button>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </ModalBody>
            <ModalFooter>
              <Button
                variant="light"
                onClick={() => setShowViewModal(false)}
                className="hover:bg-gray-100 rounded-xl"
              >
                关闭
              </Button>
            </ModalFooter>
          </ModalContent>
        </Modal>

        {/* Edit Modal */}
        <Modal
          isOpen={showEditModal}
          onClose={() => {
            setShowEditModal(false);
            setSelectedKey(null);
            resetNewKey();
          }}
          classNames={{ base: 'rounded-xl' }}
          size="2xl"
        >
          <ModalContent>
            <ModalHeader className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-yellow-50 flex items-center justify-center">
                <Edit className="w-5 h-5 text-yellow-600" />
              </div>
              <div>
                <p className="text-lg font-bold text-gray-800">编辑 API Key</p>
                <p className="text-sm text-gray-500">{selectedKey?.name}</p>
              </div>
            </ModalHeader>
            <ModalBody>
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <Select
                    label="提供商"
                    selectedKeys={[newKey.provider]}
                    onChange={(e) => {
                      const provider = e.target.value;
                      setNewKey((prev) => {
                        const next = { ...prev, provider };
                        // provider 切换时自动移除不兼容的功能勾选
                        const filtered = next.supportedFeatures.filter(
                          (f) => f === 'all' || isModelCompatibleWithFeature(provider, next.model, f)
                        );
                        return { ...next, supportedFeatures: filtered };
                      });
                    }}
                    classNames={{ trigger: 'rounded-xl' }}
                  >
                    {PROVIDER_OPTIONS.map((p) => (
                      <SelectItem key={p.key} value={p.key}>
                        {p.label}
                      </SelectItem>
                    ))}
                  </Select>
                  <Input
                    label="名称"
                    placeholder="如：通义千问主Key"
                    value={newKey.name}
                    onChange={(e) => setNewKey({ ...newKey, name: e.target.value })}
                    classNames={{ inputWrapper: 'rounded-xl' }}
                    isRequired
                  />
                </div>
                <Input
                  label="描述"
                  placeholder="用途说明（可选）"
                  value={newKey.description}
                  onChange={(e) => setNewKey({ ...newKey, description: e.target.value })}
                  classNames={{ inputWrapper: 'rounded-xl' }}
                />
                <div className="grid grid-cols-2 gap-4">
                  <Input
                    label="模型"
                    placeholder="如：qwen-turbo / qwen3-vl-plus"
                    value={newKey.model}
                    onChange={(e) => {
                      const model = e.target.value;
                      setNewKey((prev) => {
                        const next = { ...prev, model };
                        // 模型变化时自动移除不兼容的功能勾选
                        const filtered = next.supportedFeatures.filter(
                          (f) => f === 'all' || isModelCompatibleWithFeature(next.provider, model, f)
                        );
                        return { ...next, supportedFeatures: filtered };
                      });
                    }}
                    classNames={{ inputWrapper: 'rounded-xl' }}
                    isRequired
                  />
                  <Input
                    label="Base URL（可选）"
                    placeholder="自定义 API 地址"
                    value={newKey.baseUrl}
                    onChange={(e) => setNewKey({ ...newKey, baseUrl: e.target.value })}
                    classNames={{ inputWrapper: 'rounded-xl' }}
                  />
                </div>
                <div className="p-3 bg-yellow-50/80 border border-yellow-200/50 rounded-xl flex items-center gap-2">
                  <Shield className="w-5 h-5 text-yellow-600 shrink-0" />
                  <span className="text-sm text-yellow-800">如需更新 API Key，请填写下方字段；留空则保持原值不变</span>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <Input
                    label="API Key（留空保持不变）"
                    placeholder="输入新的 API Key"
                    value={newKey.apiKey}
                    onChange={(e) => setNewKey({ ...newKey, apiKey: e.target.value })}
                    classNames={{ inputWrapper: 'rounded-xl' }}
                    type="password"
                  />
                  <Input
                    label="API Secret（留空保持不变）"
                    placeholder="输入新的 API Secret"
                    value={newKey.apiSecret}
                    onChange={(e) => setNewKey({ ...newKey, apiSecret: e.target.value })}
                    classNames={{ inputWrapper: 'rounded-xl' }}
                    type="password"
                  />
                </div>
                <div className="grid grid-cols-3 gap-4">
                  <Input
                    label="速率限制（次/分钟）"
                    type="number"
                    value={String(newKey.rateLimitPerMin)}
                    onChange={(e) => setNewKey({ ...newKey, rateLimitPerMin: parseInt(e.target.value) || 60 })}
                    classNames={{ inputWrapper: 'rounded-xl' }}
                  />
                  <Input
                    label="最大并发"
                    type="number"
                    value={String(newKey.maxConcurrentRequests)}
                    onChange={(e) => setNewKey({ ...newKey, maxConcurrentRequests: parseInt(e.target.value) || 5 })}
                    classNames={{ inputWrapper: 'rounded-xl' }}
                  />
                  <Input
                    label="日配额"
                    type="number"
                    value={String(newKey.dailyQuota)}
                    onChange={(e) => setNewKey({ ...newKey, dailyQuota: parseInt(e.target.value) || 1000 })}
                    classNames={{ inputWrapper: 'rounded-xl' }}
                  />
                </div>
                <Input
                  label="过期时间"
                  type="date"
                  value={newKey.expiresAt}
                  onChange={(e) => setNewKey({ ...newKey, expiresAt: e.target.value })}
                  classNames={{ inputWrapper: 'rounded-xl' }}
                />

                {/* 功能支持（多选） */}
                <div className="p-4 bg-gradient-to-br from-blue-50/60 to-indigo-50/40 border border-blue-100 rounded-xl">
                  <div className="flex items-center gap-2 mb-2">
                    <Brain className="w-4 h-4 text-blue-600" />
                    <span className="text-sm font-semibold text-gray-800">支持的功能（多选）</span>
                    <span className="text-xs text-gray-500">· 用于套餐编辑时按功能过滤</span>
                  </div>
                  <p className="text-xs text-gray-500 mb-3">
                    勾选此 API Key 实际能调用的能力。
                  </p>
                  <p className={`text-xs mb-3 ${isVisionModel(newKey.provider, newKey.model) ? 'text-green-600' : 'text-orange-500'}`}>
                    {getFeatureCompatibilityHint(newKey.provider, newKey.model)}
                  </p>
                  <CheckboxGroup
                    value={newKey.supportedFeatures}
                    onValueChange={(v) => setNewKey({ ...newKey, supportedFeatures: v as SupportedFeature[] })}
                    orientation="horizontal"
                    classNames={{ wrapper: 'gap-2' }}
                  >
                    {FEATURE_OPTIONS.map((f) => {
                      const Icon = f.icon;
                      const compatible = isModelCompatibleWithFeature(newKey.provider, newKey.model, f.key);
                      return (
                        <Checkbox
                          key={f.key}
                          value={f.key}
                          isDisabled={!compatible}
                          classNames={{
                            base: `max-w-full m-0 border border-gray-200 rounded-lg p-2 hover:bg-white data-[selected=true]:bg-blue-50 data-[selected=true]:border-blue-300 ${!compatible ? 'opacity-50' : ''}`,
                            label: 'text-xs',
                          }}
                        >
                          <div className="flex items-center gap-1.5">
                            <Icon className="w-3.5 h-3.5 text-blue-600" />
                            <span className="font-medium">{f.label}</span>
                            {!compatible && <span className="text-[10px] text-orange-500">(模型不支持)</span>}
                          </div>
                        </Checkbox>
                      );
                    })}
                  </CheckboxGroup>
                </div>
              </div>
            </ModalBody>
            <ModalFooter>
              <Button
                variant="light"
                onClick={() => {
                  setShowEditModal(false);
                  setSelectedKey(null);
                  resetNewKey();
                }}
                className="hover:bg-gray-100 rounded-xl"
              >
                取消
              </Button>
              <Button
                color="primary"
                className="bg-blue-600 hover:bg-blue-700 rounded-xl"
                onClick={handleEditKey}
                isLoading={submitting}
                isDisabled={!newKey.name.trim() || !newKey.model.trim()}
              >
                保存
              </Button>
            </ModalFooter>
          </ModalContent>
        </Modal>

        {/* Delete Confirm Modal */}
        <Modal
          isOpen={showDeleteModal}
          onClose={() => {
            setShowDeleteModal(false);
            setSelectedKey(null);
          }}
          classNames={{ base: 'rounded-xl' }}
        >
          <ModalContent>
            <ModalHeader className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-red-50 flex items-center justify-center">
                <Trash2 className="w-5 h-5 text-red-600" />
              </div>
              <div>
                <p className="text-lg font-bold text-gray-800">确认删除</p>
                <p className="text-sm text-gray-500">此操作不可撤销</p>
              </div>
            </ModalHeader>
            <ModalBody>
              <p className="text-gray-600">
                确定要删除 <span className="font-semibold text-gray-800">{selectedKey?.name}</span> 吗？
              </p>
            </ModalBody>
            <ModalFooter>
              <Button
                variant="light"
                onClick={() => {
                  setShowDeleteModal(false);
                  setSelectedKey(null);
                }}
                className="hover:bg-gray-100 rounded-xl"
              >
                取消
              </Button>
              <Button
                color="danger"
                className="bg-red-600 hover:bg-red-700 rounded-xl"
                onClick={handleDeleteKey}
                isLoading={deleteLoading}
              >
                删除
              </Button>
            </ModalFooter>
          </ModalContent>
        </Modal>
      </div>
    </Layout>
  );
}
