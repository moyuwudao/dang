'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import { Card, CardBody, Button, Input, Switch, Select, SelectItem, Textarea, Spinner, CheckboxGroup, Checkbox, Divider } from '@nextui-org/react';
import { ArrowLeft, Save, Brain, FileText, Mic, MicOff, Image as ImageIcon, MessageSquare, ListChecks } from 'lucide-react';
import Layout from '@/components/Layout';
import { adminAPI } from '@/services/api';

interface ApiKeyItem {
  id: string;
  provider: string;
  name: string;
  model: string;
  scopes: string;
  status: string;
  isDefault: boolean;
}

interface PlanFormData {
  name: string;
  description?: string;
  priceCents: number;
  tokenQuota?: number;
  durationDays: number;
  type: string;
  isActive?: boolean;
  allowedModels?: string[];
  defaultConfigs?: Record<string, string>;
}

// 5 个功能类型（WEB端问题3修复）
const FUNCTION_TYPES = [
  { key: 'textAnalysis', label: '文本分析', icon: FileText, desc: '摘要、聊天、文本理解' },
  { key: 'speechTranscribe', label: '语言转写', icon: MessageSquare, desc: '文本翻译、转写' },
  { key: 'speechRealtime', label: '语音实时转写', icon: Mic, desc: '实时语音转文字' },
  { key: 'speechOffline', label: '离线语音转写', icon: MicOff, desc: '上传音频文件转文字' },
  { key: 'imageRecognition', label: '图像识别', icon: ImageIcon, desc: '图片理解、OCR' },
];

const PLAN_TYPES = [
  { label: '月度套餐', value: 'monthly' },
  { label: '充值', value: 'recharge' },
];

export default function PlanEditorPage() {
  const router = useRouter();
  const { id } = router.query;
  const isEdit = id && id !== 'new';

  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [apiKeys, setApiKeys] = useState<ApiKeyItem[]>([]);
  const [loadingApiKeys, setLoadingApiKeys] = useState(false);

  const [formData, setFormData] = useState<PlanFormData>({
    name: '',
    description: '',
    priceCents: 0,
    tokenQuota: 0,
    durationDays: 30,
    type: 'monthly',
    isActive: true,
    allowedModels: [],
    defaultConfigs: {},
  });

  useEffect(() => {
    loadApiKeys();
    if (isEdit) {
      loadPlan(id as string);
    }
  }, [id, isEdit]);

  const loadApiKeys = async () => {
    try {
      setLoadingApiKeys(true);
      const res: any = await adminAPI.getApiKeys();
      // 后端返回 { code, data: [...] } 结构
      const list = res?.data || res || [];
      setApiKeys(Array.isArray(list) ? list : []);
    } catch (err) {
      console.error('加载 API 列表失败:', err);
      setApiKeys([]);
    } finally {
      setLoadingApiKeys(false);
    }
  };

  const loadPlan = async (planId: string) => {
    try {
      setLoading(true);
      const res: any = await adminAPI.getPlanById(planId);
      // 兼容 { data: {...} } 与 直接对象 两种格式
      const plan = res?.data || res || {};
      setFormData({
        name: plan.name || '',
        description: plan.description || '',
        priceCents: plan.priceCents || 0,
        tokenQuota: plan.tokenQuota || 0,
        durationDays: plan.durationDays || 30,
        type: plan.type || 'monthly',
        isActive: plan.isActive ?? true,
        allowedModels: Array.isArray(plan.allowedModels) ? plan.allowedModels : [],
        defaultConfigs: plan.defaultConfigs && typeof plan.defaultConfigs === 'object' ? plan.defaultConfigs : {},
      });
    } catch (err: any) {
      setError(err.response?.data?.message || '加载套餐失败');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    try {
      setSaving(true);
      // allowedModels 是 simple-array（数组），defaultConfigs 是对象
      const data: any = {
        ...formData,
        allowedModels: formData.allowedModels || [],
        defaultConfigs: formData.defaultConfigs || {},
      };

      if (isEdit) {
        await adminAPI.updatePlan(id as string, data);
      } else {
        await adminAPI.createPlan(data);
      }

      router.push('/subscriptions');
    } catch (err: any) {
      setError(err.response?.data?.message || '保存失败');
      setSaving(false);
    }
  };

  // 切换 defaultConfigs[field] 的值
  const setDefaultConfig = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      defaultConfigs: { ...(prev.defaultConfigs || {}), [field]: value },
    }));
  };

  if (loading) {
    return (
      <Layout currentPage="subscriptions">
        <div className="flex justify-center items-center h-screen">
          <Spinner size="lg" />
        </div>
      </Layout>
    );
  }

  return (
    <Layout currentPage="subscriptions">
      <div className="space-y-6">
        <div className="flex items-center gap-4">
          <Button
            variant="light"
            startContent={<ArrowLeft className="w-4 h-4" />}
            onClick={() => router.push('/subscriptions')}
          >
            返回
          </Button>
          <div>
            <h1 className="text-2xl font-bold">{isEdit ? '编辑套餐' : '创建套餐'}</h1>
            <p className="text-gray-500">{isEdit ? '修改套餐配置信息' : '创建新的套餐'}</p>
          </div>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
            {error}
          </div>
        )}

        <Card>
          <CardBody>
            <div className="space-y-6">
              {/* 基本信息 */}
              <div>
                <h2 className="text-lg font-semibold mb-4">基本信息</h2>
                <div className="grid grid-cols-2 gap-4">
                  <Input
                    label="套餐名称"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    isRequired
                  />

                  <Input
                    label="价格(分)"
                    type="number"
                    value={formData.priceCents.toString()}
                    onChange={(e) => setFormData({ ...formData, priceCents: parseInt(e.target.value) || 0 })}
                    isRequired
                  />

                  <Input
                    label="Token配额"
                    type="number"
                    value={formData.tokenQuota?.toString() || '0'}
                    onChange={(e) => setFormData({ ...formData, tokenQuota: parseInt(e.target.value) || 0 })}
                    isRequired
                  />

                  <Input
                    label="时长(天)"
                    type="number"
                    value={formData.durationDays.toString()}
                    onChange={(e) => setFormData({ ...formData, durationDays: parseInt(e.target.value) || 0 })}
                    isRequired
                  />

                  <Select
                    label="套餐类型"
                    selectedKeys={[formData.type]}
                    onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                    isRequired
                  >
                    {PLAN_TYPES.map((type) => (
                      <SelectItem key={type.value} value={type.value}>
                        {type.label}
                      </SelectItem>
                    ))}
                  </Select>
                </div>

                <Textarea
                  label="描述"
                  value={formData.description || ''}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  className="mt-4"
                />

                <div className="flex items-center gap-2 mt-4">
                  <Switch
                    isSelected={formData.isActive ?? true}
                    onValueChange={(isSelected) => setFormData({ ...formData, isActive: isSelected })}
                  />
                  <span>启用</span>
                </div>
              </div>

              <Divider />

              {/* 可用 API（多选） */}
              <div>
                <h2 className="text-lg font-semibold mb-2 flex items-center gap-2">
                  <ListChecks className="w-5 h-5" />
                  可用 API（允许使用的 API 列表）
                </h2>
                <p className="text-sm text-gray-500 mb-4">
                  勾选此套餐允许用户调用的 API。未勾选的 API 用户将无法使用。
                </p>
                {loadingApiKeys ? (
                  <div className="flex items-center gap-2 text-gray-500">
                    <Spinner size="sm" /> 加载 API 列表...
                  </div>
                ) : apiKeys.length === 0 ? (
                  <div className="text-amber-600 text-sm bg-amber-50 border border-amber-200 rounded p-3">
                    ⚠️ 暂无可用 API，请先到 <b>API 配置管理</b> 添加 API Key
                  </div>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-2 max-h-64 overflow-y-auto border border-gray-200 rounded-lg p-3">
                    {apiKeys.map((k) => {
                      const isSelected = (formData.allowedModels || []).includes(k.model);
                      return (
                        <div
                          key={k.id}
                          className={`flex items-center gap-2 p-2 rounded cursor-pointer hover:bg-gray-50 ${isSelected ? 'bg-blue-50' : ''}`}
                          onClick={() => {
                            const current = formData.allowedModels || [];
                            const next = isSelected
                              ? current.filter(m => m !== k.model)
                              : [...current, k.model];
                            setFormData({ ...formData, allowedModels: next });
                          }}
                        >
                          <input
                            type="checkbox"
                            checked={isSelected}
                            onChange={() => {}}
                            className="rounded"
                          />
                          <div className="flex-1 min-w-0">
                            <div className="text-sm font-medium truncate">{k.name}</div>
                            <div className="text-xs text-gray-500 truncate">{k.model} · {k.provider}</div>
                          </div>
                          {k.isDefault && <span className="text-xs bg-green-100 text-green-700 px-1.5 py-0.5 rounded">默认</span>}
                        </div>
                      );
                    })}
                  </div>
                )}
                <div className="text-xs text-gray-400 mt-2">
                  已选 {formData.allowedModels?.length || 0} 个 API
                </div>
              </div>

              <Divider />

              {/* 各功能默认 API */}
              <div>
                <h2 className="text-lg font-semibold mb-2 flex items-center gap-2">
                  <Brain className="w-5 h-5" />
                  各功能默认 API
                </h2>
                <p className="text-sm text-gray-500 mb-4">
                  为每种功能设定默认调用的 API。客户端开启此套餐时将自动使用这些 API（用户可在 API 配置管理中覆盖）。
                </p>
                <div className="space-y-3">
                  {FUNCTION_TYPES.map((ft) => {
                    const Icon = ft.icon;
                    const currentValue = formData.defaultConfigs?.[ft.key] || '';
                    return (
                      <div key={ft.key} className="flex items-center gap-4 p-3 border border-gray-200 rounded-lg">
                        <Icon className="w-5 h-5 text-gray-500 shrink-0" />
                        <div className="flex-1 min-w-0">
                          <div className="text-sm font-medium">{ft.label}</div>
                          <div className="text-xs text-gray-500">{ft.desc}</div>
                        </div>
                        <div className="w-72">
                          <Select
                            aria-label={`${ft.label}默认API`}
                            placeholder="请选择默认 API"
                            size="sm"
                            selectedKeys={currentValue ? [currentValue] : []}
                            onChange={(e) => setDefaultConfig(ft.key, e.target.value)}
                            isDisabled={apiKeys.length === 0}
                          >
                            {apiKeys.map((k) => (
                              <SelectItem key={k.model} value={k.model}>
                                {k.name} ({k.model})
                              </SelectItem>
                            ))}
                          </Select>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              <div className="flex justify-end gap-2 pt-4">
                <Button
                  variant="light"
                  onClick={() => router.push('/subscriptions')}
                >
                  取消
                </Button>
                <Button
                  color="primary"
                  startContent={<Save className="w-4 h-4" />}
                  onClick={handleSave}
                  isLoading={saving}
                >
                  保存
                </Button>
              </div>
            </div>
          </CardBody>
        </Card>
      </div>
    </Layout>
  );
}
