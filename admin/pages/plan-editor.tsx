'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import { Card, CardBody, Button, Spinner, Tabs, Tab, Chip } from '@nextui-org/react';
import { ArrowLeft, Settings2, ListChecks, Brain, ChevronRight } from 'lucide-react';
import Layout from '@/components/Layout';
import { adminAPI, apiKeyAPI } from '@/services/api';
import { ApiKeyItem, ApiConfigItem, PlanFormData } from '@/components/plan-editor/types';
import PlanBasicInfoCard from '@/components/plan-editor/PlanBasicInfoCard';
import ApiPoliciesEditor from '@/components/plan-editor/ApiPoliciesEditor';
import FunctionDefaultsEditor from '@/components/plan-editor/FunctionDefaultsEditor';
import PlanEditorActions from '@/components/plan-editor/PlanEditorActions';

export default function PlanEditorPage() {
  const router = useRouter();
  const { id } = router.query;
  const isEdit = id && id !== 'new';

  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<string>('basic');

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
      // 并行加载：API Keys（5个active）+ API Configs（系数权威源）
      const [keysRes, configsRes] = await Promise.all([
        apiKeyAPI.getApiKeys().catch(() => null),
        adminAPI.getApiConfigs().catch(() => null),
      ]);

      const keysList: any[] =
        (keysRes as any)?.data || (Array.isArray(keysRes) ? keysRes : []) || [];
      const configsList: ApiConfigItem[] =
        ((configsRes as any)?.data ||
          (Array.isArray(configsRes) ? configsRes : []) ||
          []) as ApiConfigItem[];

      // 用 (provider, modelPattern) 索引 api_configs 中的系数
      const coeffMap = new Map<string, number>();
      for (const c of configsList) {
        if (!c.isActive) continue;
        const key = `${c.provider}|${c.modelPattern}`;
        coeffMap.set(key, Number(c.baseCoefficient));
      }

      // 只保留 status='active' 的 API Key，并按 model 去重
      const activeKeys = keysList.filter((k) => k.status === 'active');
      const seenModels = new Set<string>();
      const merged: ApiKeyItem[] = [];
      for (const k of activeKeys) {
        if (seenModels.has(k.model)) continue; // 去重
        seenModels.add(k.model);
        // 关联计费系数
        const coeffKey = `${k.provider}|${k.model}`;
        const baseCoefficient = coeffMap.get(coeffKey);
        merged.push({
          ...k,
          baseCoefficient,
        });
      }
      console.log(
        `[plan-editor] API Keys: total=${keysList.length}, active=${activeKeys.length}, withCoeff=${merged.filter((k) => k.baseCoefficient !== undefined).length}`
      );
      setApiKeys(merged);
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
      const plan = res?.data || res || {};
      const apiPolicies =
        Array.isArray(plan.apiPolicies) && plan.apiPolicies.length > 0
          ? plan.apiPolicies
          : Array.isArray(plan.allowedModels)
          ? plan.allowedModels.map((m: string) => ({
              provider: 'alibabaQwen',
              model: m,
              modelPattern: m,
              multiplier: 1.0,
              isAllowed: true,
            }))
          : [];
      setFormData({
        name: plan.name || '',
        description: plan.description || '',
        priceCents: plan.priceCents || 0,
        tokenQuota: plan.tokenQuota || 0,
        durationDays: plan.durationDays || 30,
        type: plan.type || 'monthly',
        isActive: plan.isActive ?? true,
        isRecommended: plan.isRecommended ?? false,
        // 后端 normalizePlan 已将 features 解析为数组；老数据为空时为 []
        features: Array.isArray(plan.features) ? plan.features : [],
        allowedModels: Array.isArray(plan.allowedModels) ? plan.allowedModels : [],
        defaultConfigs:
          plan.defaultConfigs && typeof plan.defaultConfigs === 'object' ? plan.defaultConfigs : {},
        apiPolicies,
      });
    } catch (err: any) {
      setError(err.response?.data?.message || '加载套餐失败');
    } finally {
      setLoading(false);
    }
  };

  // ========== 通用变更处理 ==========
  const handleBasicInfoChange = (patch: Partial<PlanFormData>) => {
    setFormData((prev) => ({ ...prev, ...patch }));
  };

  // ========== API 多选处理 ==========
  const handleToggleModel = (model: string) => {
    setFormData((prev) => {
      const current = prev.allowedModels || [];
      const next = current.includes(model)
        ? current.filter((m) => m !== model)
        : [...current, model];
      return { ...prev, allowedModels: next };
    });
  };

  // 设置某个 model 的 apiPolicy 字段（仅 isAllowed，multiplier 由计费配置统一管理）
  const handleSetApiPolicyField = (model: string, field: 'isAllowed', value: boolean) => {
    if (field !== 'isAllowed') return; // 防御：禁止设置 multiplier
    setFormData((prev) => {
      const policies = [...(prev.apiPolicies || [])];
      const idx = policies.findIndex((p) => p.model === model);
      if (idx >= 0) {
        policies[idx] = { ...policies[idx], isAllowed: value };
      } else {
        const api = apiKeys.find((k) => k.model === model);
        policies.push({
          provider: api?.provider || 'alibabaQwen',
          model,
          modelPattern: model,
          multiplier: api?.baseCoefficient ?? 1.0, // 来自计费配置
          isAllowed: value,
        });
      }
      return { ...prev, apiPolicies: policies };
    });
  };

  // ========== defaultConfigs 处理 ==========
  const handleSetDefaultConfig = (field: string, value: string) => {
    setFormData((prev) => ({
      ...prev,
      defaultConfigs: { ...(prev.defaultConfigs || {}), [field]: value },
    }));
  };

  // ========== 保存 ==========
  const handleSave = async () => {
    try {
      setSaving(true);
      // 构造 apiPolicies：
      // 1) 只保存 allowedModels 中已勾选的
      // 2) multiplier 强制取自 api_configs（计费配置），不允许在套餐中自定义
      // 3) isAllowed 取自用户在套餐中的设置
      const isAllowedMap = new Map<string, boolean>();
      for (const p of formData.apiPolicies || []) {
        isAllowedMap.set(p.model, p.isAllowed !== false);
      }
      const savedPolicies: any[] = [];

      for (const model of formData.allowedModels || []) {
        const api = apiKeys.find((k) => k.model === model);
        const baseCoefficient = api?.baseCoefficient;
        if (baseCoefficient === undefined) {
          // 缺系数的 API 不允许保存为可用
          console.warn(
            `[plan-editor] 跳过保存 ${model}：计费配置中缺少 baseCoefficient`
          );
          continue;
        }
        savedPolicies.push({
          provider: api?.provider || 'alibabaQwen',
          model,
          modelPattern: model,
          multiplier: baseCoefficient, // 强制取自计费配置
          isAllowed: isAllowedMap.get(model) ?? true,
        });
      }

      const data: any = {
        ...formData,
        // 过滤空字符串，保存时不写入空特性
        features: (formData.features || []).map((f) => f.trim()).filter(Boolean),
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

  // ========== 步骤完成度统计 ==========
  const basicInfoComplete = !!(formData.name && formData.priceCents > 0);
  const apisSelectedCount = formData.allowedModels?.length || 0;
  const functionDefaultsCount = Object.keys(formData.defaultConfigs || {}).filter(
    (k) => formData.defaultConfigs?.[k]
  ).length;

  // 完成度映射，用于 Tab 的角标
  const stepStatus = {
    basic: basicInfoComplete ? 'done' : 'pending',
    apis: apisSelectedCount > 0 ? 'done' : 'pending',
    functions: functionDefaultsCount > 0 ? 'done' : 'pending',
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
      <div className="space-y-6 pb-20">
        {/* 顶部 Header */}
        <div className="flex items-center gap-4">
          <Button
            variant="light"
            startContent={<ArrowLeft className="w-4 h-4" />}
            onClick={() => router.push('/subscriptions')}
            size="sm"
          >
            返回
          </Button>
          <div className="flex-1">
            <h1 className="text-2xl font-bold">{isEdit ? '编辑套餐' : '创建套餐'}</h1>
            <p className="text-gray-500 text-sm">
              {isEdit ? '修改套餐配置信息' : '创建新的套餐，按步骤填写'}
            </p>
          </div>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded text-sm">
            {error}
          </div>
        )}

        {/* 步骤进度条 */}
        <div className="flex items-center gap-2 text-xs text-gray-500 px-1">
          <Chip
            size="sm"
            variant={activeTab === 'basic' ? 'solid' : 'flat'}
            color={stepStatus.basic === 'done' ? 'success' : 'default'}
            startContent={<Settings2 className="w-3 h-3" />}
          >
            1. 基本信息
          </Chip>
          <ChevronRight className="w-3 h-3" />
          <Chip
            size="sm"
            variant={activeTab === 'apis' ? 'solid' : 'flat'}
            color={stepStatus.apis === 'done' ? 'success' : 'default'}
            startContent={<ListChecks className="w-3 h-3" />}
          >
            2. 可用 API（{apisSelectedCount}）
          </Chip>
          <ChevronRight className="w-3 h-3" />
          <Chip
            size="sm"
            variant={activeTab === 'functions' ? 'solid' : 'flat'}
            color={stepStatus.functions === 'done' ? 'success' : 'default'}
            startContent={<Brain className="w-3 h-3" />}
          >
            3. 功能默认 API（{functionDefaultsCount}/5）
          </Chip>
        </div>

        {/* Tabs 分步表单 */}
        <Card>
          <CardBody className="p-0">
            <Tabs
              selectedKey={activeTab}
              onSelectionChange={(key) => setActiveTab(key as string)}
              aria-label="套餐编辑步骤"
              color="primary"
              variant="underlined"
              classNames={{
                tabList: 'gap-6 px-6 pt-2',
                cursor: 'bg-primary',
                tab: 'px-2 h-12',
                tabContent: 'text-sm font-medium',
              }}
            >
              <Tab
                key="basic"
                title={
                  <div className="flex items-center gap-2">
                    <Settings2 className="w-4 h-4" />
                    <span>基本信息</span>
                    {stepStatus.basic === 'done' && (
                      <span className="text-green-500 text-xs">✓</span>
                    )}
                  </div>
                }
              >
                <div className="p-6">
                  <PlanBasicInfoCard formData={formData} onChange={handleBasicInfoChange} />

                  <div className="flex justify-end mt-6">
                    <Button
                      color="primary"
                      endContent={<ChevronRight className="w-4 h-4" />}
                      onClick={() => setActiveTab('apis')}
                      size="sm"
                    >
                      下一步：选择可用 API
                    </Button>
                  </div>
                </div>
              </Tab>

              <Tab
                key="apis"
                title={
                  <div className="flex items-center gap-2">
                    <ListChecks className="w-4 h-4" />
                    <span>可用 API</span>
                    {apisSelectedCount > 0 && (
                      <Chip size="sm" variant="flat" color="primary" className="h-4 min-w-4 px-1 text-[10px]">
                        {apisSelectedCount}
                      </Chip>
                    )}
                  </div>
                }
              >
                <div className="p-6">
                  <ApiPoliciesEditor
                    apiKeys={apiKeys}
                    loadingApiKeys={loadingApiKeys}
                    allowedModels={formData.allowedModels || []}
                    apiPolicies={formData.apiPolicies}
                    onToggleModel={handleToggleModel}
                    onSetApiPolicyField={handleSetApiPolicyField}
                  />

                  <div className="flex justify-between mt-6">
                    <Button
                      variant="light"
                      onClick={() => setActiveTab('basic')}
                      startContent={<ArrowLeft className="w-4 h-4" />}
                      size="sm"
                    >
                      上一步
                    </Button>
                    <Button
                      color="primary"
                      endContent={<ChevronRight className="w-4 h-4" />}
                      onClick={() => setActiveTab('functions')}
                      size="sm"
                    >
                      下一步：配置功能默认 API
                    </Button>
                  </div>
                </div>
              </Tab>

              <Tab
                key="functions"
                title={
                  <div className="flex items-center gap-2">
                    <Brain className="w-4 h-4" />
                    <span>功能默认 API</span>
                    {functionDefaultsCount > 0 && (
                      <Chip
                        size="sm"
                        variant="flat"
                        color="primary"
                        className="h-4 min-w-4 px-1 text-[10px]"
                      >
                        {functionDefaultsCount}/5
                      </Chip>
                    )}
                  </div>
                }
              >
                <div className="p-6">
                  <FunctionDefaultsEditor
                    apiKeys={apiKeys}
                    allowedModels={formData.allowedModels || []}
                    defaultConfigs={formData.defaultConfigs || {}}
                    onSetDefaultConfig={handleSetDefaultConfig}
                  />

                  <div className="flex justify-start mt-6">
                    <Button
                      variant="light"
                      onClick={() => setActiveTab('apis')}
                      startContent={<ArrowLeft className="w-4 h-4" />}
                      size="sm"
                    >
                      上一步
                    </Button>
                  </div>
                </div>
              </Tab>
            </Tabs>
          </CardBody>
        </Card>
      </div>

      {/* 底部操作栏（始终可见） */}
      <PlanEditorActions
        saving={saving}
        isEdit={!!isEdit}
        onCancel={() => router.push('/subscriptions')}
        onSave={handleSave}
      />
    </Layout>
  );
}
