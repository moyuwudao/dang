'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import { Card, CardBody, Button, Input, Switch, Select, SelectItem, Textarea, Spinner } from '@nextui-org/react';
import { ArrowLeft, Save } from 'lucide-react';
import Layout from '@/components/Layout';
import { adminAPI } from '@/services/api';

interface FeatureQuota {
  featureType: string;
  quotaValue: number;
  quotaUnit: string;
  multiplier?: number;
}

interface DefaultConfig {
  functionType: string;
  modelPattern: string;
  isActive?: boolean;
}

interface PlanFormData {
  name: string;
  description?: string;
  priceCents: number;
  durationDays: number;
  isActive?: boolean;
  sortOrder?: number;
  featureQuotas?: FeatureQuota[];
  defaultConfigs?: DefaultConfig[];
}

const FEATURE_TYPES = [
  { label: 'AI对话', value: 'ai_chat', unit: 'tokens' },
  { label: '语音转写', value: 'transcription', unit: 'minutes' },
  { label: '实时转写', value: 'realtime_transcription', unit: 'minutes' },
  { label: '文本分析', value: 'text_analysis', unit: 'thousand_chars' },
  { label: '图像识别', value: 'image_recognition', unit: 'images' },
  { label: 'OCR识别', value: 'ocr', unit: 'images' },
  { label: '语音合成', value: 'tts', unit: 'thousand_chars' },
];

const FUNCTION_TYPES = [
  { label: 'AI对话', value: 'ai_chat' },
  { label: '语音转写', value: 'transcription' },
  { label: '实时转写', value: 'realtime_transcription' },
  { label: '文本分析', value: 'text_analysis' },
  { label: '图像识别', value: 'image_recognition' },
  { label: 'OCR识别', value: 'ocr' },
  { label: '语音合成', value: 'tts' },
];

const QUOTA_UNITS = [
  { label: '分钟', value: 'minutes' },
  { label: 'Token', value: 'tokens' },
  { label: '千字符', value: 'thousand_chars' },
  { label: '次', value: 'times' },
  { label: '张', value: 'images' },
];

export default function PlanEditorPage() {
  const router = useRouter();
  const { id } = router.query;
  const isEdit = id && id !== 'new';

  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [formData, setFormData] = useState<PlanFormData>({
    name: '',
    description: '',
    priceCents: 0,
    durationDays: 30,
    isActive: true,
    sortOrder: 0,
    featureQuotas: [],
    defaultConfigs: [],
  });

  const [featureQuotas, setFeatureQuotas] = useState<FeatureQuota[]>([]);
  const [defaultConfigs, setDefaultConfigs] = useState<DefaultConfig[]>([]);

  useEffect(() => {
    if (isEdit) {
      loadPlan(id as string);
    }
  }, [id, isEdit]);

  const loadPlan = async (planId: string) => {
    try {
      setLoading(true);
      const plan = await adminAPI.getPlanById(planId);
      setFormData({
        name: plan.name,
        description: plan.description || '',
        priceCents: plan.priceCents,
        durationDays: plan.durationDays,
        isActive: plan.isActive,
        sortOrder: plan.sortOrder || 0,
      });

      if (plan.featureQuotas) {
        setFeatureQuotas(plan.featureQuotas);
      }

      if (plan.defaultConfigs) {
        setDefaultConfigs(plan.defaultConfigs);
      }
    } catch (err: any) {
      setError(err.response?.data?.message || '加载套餐失败');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    try {
      setSaving(true);
      const data = {
        ...formData,
        featureQuotas,
        defaultConfigs,
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

  const handleAddFeatureQuota = () => {
    setFeatureQuotas([...featureQuotas, {
      featureType: 'ai_chat',
      quotaValue: 10000,
      quotaUnit: 'tokens',
      multiplier: 1.0,
    }]);
  };

  const handleRemoveFeatureQuota = (index: number) => {
    setFeatureQuotas(featureQuotas.filter((_, i) => i !== index));
  };

  const handleFeatureQuotaChange = (index: number, field: keyof FeatureQuota, value: any) => {
    const updated = [...featureQuotas];
    updated[index] = { ...updated[index], [field]: value };
    setFeatureQuotas(updated);
  };

  const handleAddDefaultConfig = () => {
    setDefaultConfigs([...defaultConfigs, {
      functionType: 'ai_chat',
      modelPattern: '',
      isActive: true,
    }]);
  };

  const handleRemoveDefaultConfig = (index: number) => {
    setDefaultConfigs(defaultConfigs.filter((_, i) => i !== index));
  };

  const handleDefaultConfigChange = (index: number, field: keyof DefaultConfig, value: any) => {
    const updated = [...defaultConfigs];
    updated[index] = { ...updated[index], [field]: value };
    setDefaultConfigs(updated);
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
                    label="时长(天)"
                    type="number"
                    value={formData.durationDays.toString()}
                    onChange={(e) => setFormData({ ...formData, durationDays: parseInt(e.target.value) || 0 })}
                    isRequired
                  />

                  <Input
                    label="排序"
                    type="number"
                    value={formData.sortOrder?.toString() || '0'}
                    onChange={(e) => setFormData({ ...formData, sortOrder: parseInt(e.target.value) || 0 })}
                  />
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

              <div className="border-t border-gray-200 pt-6">
                <div className="flex justify-between items-center mb-4">
                  <h2 className="text-lg font-semibold">功能配额</h2>
                  <Button
                    size="sm"
                    color="primary"
                    onClick={handleAddFeatureQuota}
                  >
                    添加配额
                  </Button>
                </div>

                {featureQuotas.length === 0 ? (
                  <p className="text-gray-500 text-sm">暂无功能配额配置</p>
                ) : (
                  <div className="space-y-4">
                    {featureQuotas.map((quota, index) => (
                      <Card key={index} className="p-4">
                        <div className="grid grid-cols-4 gap-4 items-end">
                          <Select
                            label="功能类型"
                            selectedKeys={[quota.featureType]}
                            onChange={(e) => handleFeatureQuotaChange(index, 'featureType', e.target.value)}
                          >
                            {FEATURE_TYPES.map((type) => (
                              <SelectItem key={type.value} value={type.value}>
                                {type.label}
                              </SelectItem>
                            ))}
                          </Select>

                          <Input
                            label="配额值"
                            type="number"
                            value={quota.quotaValue.toString()}
                            onChange={(e) => handleFeatureQuotaChange(index, 'quotaValue', parseInt(e.target.value) || 0)}
                          />

                          <Select
                            label="单位"
                            selectedKeys={[quota.quotaUnit]}
                            onChange={(e) => handleFeatureQuotaChange(index, 'quotaUnit', e.target.value)}
                          >
                            {QUOTA_UNITS.map((unit) => (
                              <SelectItem key={unit.value} value={unit.value}>
                                {unit.label}
                              </SelectItem>
                            ))}
                          </Select>

                          <Button
                            color="danger"
                            variant="light"
                            size="sm"
                            onClick={() => handleRemoveFeatureQuota(index)}
                          >
                            删除
                          </Button>
                        </div>
                      </Card>
                    ))}
                  </div>
                )}
              </div>

              <div className="border-t border-gray-200 pt-6">
                <div className="flex justify-between items-center mb-4">
                  <h2 className="text-lg font-semibold">场景默认模型</h2>
                  <Button
                    size="sm"
                    color="primary"
                    onClick={handleAddDefaultConfig}
                  >
                    添加配置
                  </Button>
                </div>

                {defaultConfigs.length === 0 ? (
                  <p className="text-gray-500 text-sm">暂无场景默认模型配置</p>
                ) : (
                  <div className="space-y-4">
                    {defaultConfigs.map((config, index) => (
                      <Card key={index} className="p-4">
                        <div className="grid grid-cols-3 gap-4 items-end">
                          <Select
                            label="功能类型"
                            selectedKeys={[config.functionType]}
                            onChange={(e) => handleDefaultConfigChange(index, 'functionType', e.target.value)}
                          >
                            {FUNCTION_TYPES.map((type) => (
                              <SelectItem key={type.value} value={type.value}>
                                {type.label}
                              </SelectItem>
                            ))}
                          </Select>

                          <Input
                            label="模型"
                            value={config.modelPattern}
                            onChange={(e) => handleDefaultConfigChange(index, 'modelPattern', e.target.value)}
                            placeholder="如: gpt-4"
                          />

                          <Button
                            color="danger"
                            variant="light"
                            size="sm"
                            onClick={() => handleRemoveDefaultConfig(index)}
                          >
                            删除
                          </Button>
                        </div>
                      </Card>
                    ))}
                  </div>
                )}
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
