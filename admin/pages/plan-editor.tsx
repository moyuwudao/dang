'use client';

import { useState, useEffect } from 'react';
import { Fragment } from 'react';
import { useRouter } from 'next/router';
import { Card, CardBody, Button, Input, Switch, Select, SelectItem, Textarea, Spinner, CheckboxGroup, Checkbox, Divider } from '@nextui-org/react';
import { ArrowLeft, Save, Brain, FileText, Mic, MicOff, Image as ImageIcon, MessageSquare, ListChecks } from 'lucide-react';
import Layout from '@/components/Layout';
import { adminAPI, apiKeyAPI } from '@/services/api';

interface ApiKeyItem {
  id: string;
  provider: string;
  name: string;
  model: string;
  scopes: string;
  status: string;
  isDefault: boolean;
  // 该 API 支持的功能列表（后端返回的 supportedFeatures 字段）
  // 可选值: textAnalysis | speechTranscribe | speechRealtime | speechOffline | imageRecognition | all
  supportedFeatures?: string[];
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
  apiPolicies?: Array<{
    provider: string;
    model: string;
    modelPattern?: string;
    multiplier: number;
    isAllowed?: boolean;
  }>;
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
      const res: any = await apiKeyAPI.getApiKeys();
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
      // 兼容旧的 plan.apiPolicies 不存在：用 allowedModels 派生
      const apiPolicies = Array.isArray(plan.apiPolicies) && plan.apiPolicies.length > 0
        ? plan.apiPolicies
        : (Array.isArray(plan.allowedModels)
            ? plan.allowedModels.map((m: string) => ({
                provider: 'alibabaQwen',
                model: m,
                modelPattern: m,
                multiplier: 1.0,
                isAllowed: true,
              }))
            : []);
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
        apiPolicies,
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
      // 构造 apiPolicies：只保存 allowedModels 中已勾选 + isAllowed=true 的
      const allowedSet = new Set(formData.allowedModels || []);
      const savedPolicies: any[] = [];
      const seenModels = new Set<string>();

      // 优先使用 formData.apiPolicies，但只保留 allowedModels 中已勾选且 isAllowed=true 的
      const existingPolicies = formData.apiPolicies || [];
      for (const policy of existingPolicies) {
        if (allowedSet.has(policy.model) && policy.isAllowed !== false) {
          savedPolicies.push(policy);
          seenModels.add(policy.model);
        }
      }

      // 补全：已勾选但 apiPolicies 中没有的，从 apiKeys 中查找 provider
      for (const model of formData.allowedModels || []) {
        if (seenModels.has(model)) continue;
        const api = apiKeys.find(k => k.model === model);
        if (api) {
          savedPolicies.push({
            provider: api.provider || 'alibabaQwen',
            model,
            modelPattern: model,
            multiplier: 1.0,
            isAllowed: true,
          });
        } else {
          // 兜底：用默认 provider
          savedPolicies.push({
            provider: 'alibabaQwen',
            model,
            modelPattern: model,
            multiplier: 1.0,
            isAllowed: true,
          });
        }
        seenModels.add(model);
      }

      const data: any = {
        ...formData,
        allowedModels: formData.allowedModels || [],
        defaultConfigs: formData.defaultConfigs || {},
        apiPolicies: savedPolicies,
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

  // 设置某个 model 的 apiPolicy 字段（multiplier/isAllowed）
  const setApiPolicyField = (model: string, field: 'multiplier' | 'isAllowed', value: number | boolean) => {
    setFormData(prev => {
      const policies = [...(prev.apiPolicies || [])];
      const idx = policies.findIndex(p => p.model === model);
      if (idx >= 0) {
        policies[idx] = { ...policies[idx], [field]: value };
      } else {
        // 兜底：从 apiKeys 找 provider
        const api = apiKeys.find(k => k.model === model);
        policies.push({
          provider: api?.provider || 'alibabaQwen',
          model,
          modelPattern: model,
          multiplier: field === 'multiplier' ? (value as number) : 1.0,
          isAllowed: field === 'isAllowed' ? (value as boolean) : true,
        });
      }
      return { ...prev, apiPolicies: policies };
    });
  };

  // 获取某 model 的 multiplier（默认 1.0）
  const getModelMultiplier = (model: string): number => {
    return formData.apiPolicies?.find(p => p.model === model)?.multiplier ?? 1.0;
  };

  // 获取某 model 的 isAllowed（默认 true）
  const getModelIsAllowed = (model: string): boolean => {
    return formData.apiPolicies?.find(p => p.model === model)?.isAllowed ?? true;
  };

  // 切换 defaultConfigs[field] 的值
  const setDefaultConfig = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      defaultConfigs: { ...(prev.defaultConfigs || {}), [field]: value },
    }));
  };

  // 判断某个 API 是否支持某功能
  // 规则：1) 包含 'all' 表示支持所有功能  2) 包含具体 feature 标识
  // 注意：未配置 supportedFeatures 的 API 严格不放行，必须先到 API Key 管理页面配置
  const apiSupportsFeature = (api: ApiKeyItem, featureKey: string): boolean => {
    const supported = api.supportedFeatures || [];
    if (supported.length === 0) {
      // 严格模式：未配置功能列表的 API 不会出现在任何功能下拉中
      return false;
    }
    if (supported.includes('all')) return true;
    return supported.includes(featureKey);
  };

  // 用于下拉框的"过滤"版本：必须同时满足 1) 在"可用 API"中已勾选  2) 支持该功能
  // 用户反馈：未在「可用 API」中勾选的 API，不得在「各功能默认 API」中选择
  const getAvailableApisForFeature = (featureKey: string): ApiKeyItem[] => {
    const allowed = formData.allowedModels || [];
    return apiKeys.filter(
      (k) => allowed.includes(k.model) && apiSupportsFeature(k, featureKey)
    );
  };

  // 当已选中的 API 不再支持该功能时（如用户后来改过 supportedFeatures），返回 true 提醒
  const isCurrentSelectionStale = (featureKey: string): boolean => {
    const currentValue = formData.defaultConfigs?.[featureKey];
    if (!currentValue) return false;
    const currentApi = apiKeys.find(k => k.model === currentValue);
    if (!currentApi) return false;
    return !apiSupportsFeature(currentApi, featureKey);
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
                  <>
                    {apiKeys.some((k) => !k.supportedFeatures || k.supportedFeatures.length === 0) && (
                      <div className="mb-2 p-2 bg-amber-50 border border-amber-200 rounded text-xs text-amber-800">
                        ⚠️ 有 {apiKeys.filter((k) => !k.supportedFeatures || k.supportedFeatures.length === 0).length}{' '}
                        个 API Key <b>未配置支持的功能</b>，它们将不会出现在下方「各功能默认 API」下拉中。
                        请到 <b>API Key 管理</b> 编辑这些 Key，勾选它们实际能提供的功能。
                      </div>
                    )}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-2 max-h-80 overflow-y-auto border border-gray-200 rounded-lg p-3">
                    {apiKeys.map((k) => {
                      const isSelected = (formData.allowedModels || []).includes(k.model);
                      const features = k.supportedFeatures || [];
                      const hasFeatures = features.length > 0;
                      const multiplier = getModelMultiplier(k.model);
                      const isAllowed = getModelIsAllowed(k.model);
                      return (
                        <div
                          key={k.id}
                          className={`p-2 rounded border ${isSelected ? 'border-blue-300 bg-blue-50/40' : 'border-gray-200'} ${!hasFeatures ? 'ring-1 ring-amber-200' : ''}`}
                        >
                          <div
                            className="flex items-center gap-2 cursor-pointer hover:bg-gray-50 -m-2 p-2 rounded"
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
                              <div className="text-sm font-medium truncate flex items-center gap-1">
                                {k.name}
                                {!hasFeatures && <span className="text-[9px] px-1 py-0.5 bg-amber-100 text-amber-700 rounded">未配置功能</span>}
                              </div>
                              <div className="text-xs text-gray-500 truncate">{k.model} · {k.provider}</div>
                              {hasFeatures ? (
                                <div className="flex flex-wrap gap-0.5 mt-0.5">
                                  {features.slice(0, 3).map((f) => (
                                    <span
                                      key={f}
                                      className="text-[9px] px-1 py-0.5 bg-blue-50 text-blue-700 rounded border border-blue-100"
                                      title={f}
                                    >
                                      {f === 'textAnalysis' ? '文本'
                                        : f === 'speechTranscribe' ? '转写'
                                        : f === 'speechRealtime' ? '实时'
                                        : f === 'speechOffline' ? '离线'
                                        : f === 'imageRecognition' ? '图像'
                                        : f === 'all' ? '全'
                                        : f}
                                    </span>
                                  ))}
                                  {features.length > 3 && (
                                    <span className="text-[9px] text-gray-400">+{features.length - 3}</span>
                                  )}
                                </div>
                              ) : (
                                <div className="text-[9px] text-amber-600 mt-0.5">⚠ 请到 API Key 管理配置</div>
                              )}
                            </div>
                            {k.isDefault && <span className="text-xs bg-green-100 text-green-700 px-1.5 py-0.5 rounded">默认</span>}
                          </div>
                          {/* 选中时显示系数和允许开关 */}
                          {isSelected && (
                            <div
                              className="flex items-center gap-2 mt-2 pt-2 border-t border-blue-100"
                              onClick={(e) => e.stopPropagation()}
                            >
                              <div className="flex items-center gap-1 flex-1">
                                <span className="text-[10px] text-gray-600">系数</span>
                                <Input
                                  type="number"
                                  size="sm"
                                  step="0.1"
                                  min="0"
                                  value={multiplier.toString()}
                                  onValueChange={(v) => {
                                    const num = parseFloat(v);
                                    if (!isNaN(num) && num >= 0) {
                                      setApiPolicyField(k.model, 'multiplier', num);
                                    }
                                  }}
                                  className="w-16"
                                  classNames={{ input: 'text-xs text-center' }}
                                />
                                <span className="text-[10px] text-gray-500">x</span>
                              </div>
                              <div className="flex items-center gap-1">
                                <span className="text-[10px] text-gray-600">允许</span>
                                <Switch
                                  size="sm"
                                  isSelected={isAllowed}
                                  onValueChange={(v) => setApiPolicyField(k.model, 'isAllowed', v)}
                                />
                              </div>
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                  </>
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
                {/* 网格状布局：2列展示各功能默认 API */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  {FUNCTION_TYPES.map((ft) => {
                    const Icon = ft.icon;
                    const currentValue = formData.defaultConfigs?.[ft.key] || '';
                    const currentKey = apiKeys.find((k) => k.model === currentValue);
                    // 按 supportedFeatures 过滤可选 API
                    const availableApis = getAvailableApisForFeature(ft.key);
                    const stale = isCurrentSelectionStale(ft.key);
                    return (
                      <div
                        key={ft.key}
                        className={`p-3 border rounded-lg ${
                          stale
                            ? 'border-amber-300 bg-amber-50/50'
                            : 'border-gray-200 bg-gray-50/30'
                        }`}
                      >
                        {/* 头部：图标+标题+已选 badge */}
                        <div className="flex items-center gap-2 mb-2">
                          <Icon className="w-4 h-4 text-blue-600 shrink-0" />
                          <div className="flex-1 min-w-0">
                            <div className="text-sm font-semibold text-gray-800 leading-tight">{ft.label}</div>
                            <div className="text-[11px] text-gray-500 leading-tight">{ft.desc}</div>
                          </div>
                          {currentKey && !stale && (
                            <div className="text-[10px] px-1.5 py-0.5 bg-blue-50 border border-blue-200 text-blue-700 rounded font-medium">
                              ✓ {currentKey.name}
                            </div>
                          )}
                          {stale && (
                            <div className="text-[10px] px-1.5 py-0.5 bg-amber-100 border border-amber-300 text-amber-800 rounded font-medium">
                              ⚠ 不再支持
                            </div>
                          )}
                        </div>

                        {/* 陈旧选择警告 */}
                        {stale && currentKey && (
                          <div className="mb-2 p-1.5 bg-amber-100/70 border border-amber-200 rounded text-[11px] text-amber-800">
                            ⚠ 已选 <b>{currentKey.name}</b> 不再支持该功能，请重新选择
                          </div>
                        )}

                        {/* API 选择下拉 */}
                        <Select
                          aria-label={`${ft.label}默认API`}
                          placeholder={
                            availableApis.length === 0
                              ? `暂无可支持「${ft.label}」的 API`
                              : '请选择默认 API'
                          }
                          size="sm"
                          variant="bordered"
                          classNames={{
                            trigger: 'bg-white min-h-unit-8 data-[hover=true]:bg-white',
                            value: 'text-xs font-medium text-gray-900',
                            listbox: 'p-0',
                            popoverContent: 'z-50',
                          }}
                          selectedKeys={currentValue ? [currentValue] : []}
                          onChange={(e) => setDefaultConfig(ft.key, e.target.value)}
                          isDisabled={apiKeys.length === 0}
                        >
                          {/* 过滤后的可用 API 列表 */}
                          {availableApis.map((k) => (
                            <SelectItem
                              key={k.model}
                              value={k.model}
                              description={`${k.provider} · ${(k.supportedFeatures || ['未配置']).length} 项功能`}
                              classNames={{
                                base: 'data-[hover=true]:bg-blue-50',
                                title: 'text-xs font-medium',
                                description: 'text-[10px] text-gray-500',
                              }}
                            >
                              {k.name}
                            </SelectItem>
                          ))}
                        </Select>

                        {/* 底部状态行 */}
                        <div className="text-[10px] text-gray-500 mt-1 truncate">
                          {availableApis.length === 0
                            ? '💡 请到「API Key 管理」添加支持该功能的 Key'
                            : !currentValue
                            ? '⚠️ 未设置'
                            : stale
                            ? '⚠️ 已选 API 不兼容'
                            : `✓ ${availableApis.length} 个可用`}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* 注：底部「保存」按钮由下方 sticky 操作栏提供，避免重复 */}
            </div>
          </CardBody>
        </Card>
      </div>

      {/* Sticky 底部操作栏 - 始终可见，方便长页面随时保存 */}
      <div className="sticky bottom-0 left-0 right-0 z-40 bg-white/95 backdrop-blur-sm border-t border-gray-200 shadow-lg -mx-4 px-6 py-3 mt-4">
        <div className="flex items-center justify-between gap-3 max-w-screen-2xl mx-auto">
          <div className="text-xs text-gray-500">
            💡 修改后请点击「保存」按钮持久化到服务器
          </div>
          <div className="flex gap-2">
            <Button
              variant="light"
              onClick={() => router.push('/subscriptions')}
              size="sm"
            >
              取消
            </Button>
            <Button
              color="primary"
              startContent={<Save className="w-4 h-4" />}
              onClick={handleSave}
              isLoading={saving}
              size="sm"
            >
              保存
            </Button>
          </div>
        </div>
      </div>
    </Layout>
  );
}
