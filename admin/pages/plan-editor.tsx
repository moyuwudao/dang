'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import { Card, CardBody, Button, Input, Switch, Select, SelectItem, Textarea, Spinner } from '@nextui-org/react';
import { ArrowLeft, Save } from 'lucide-react';
import Layout from '@/components/Layout';
import { adminAPI } from '@/services/api';

interface PlanFormData {
  name: string;
  description?: string;
  priceCents: number;
  tokenQuota?: number;
  durationDays: number;
  type: string;
  isActive?: boolean;
}

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

  const [formData, setFormData] = useState<PlanFormData>({
    name: '',
    description: '',
    priceCents: 0,
    tokenQuota: 0,
    durationDays: 30,
    type: 'monthly',
    isActive: true,
  });

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
        tokenQuota: plan.tokenQuota || 0,
        durationDays: plan.durationDays,
        type: plan.type || 'monthly',
        isActive: plan.isActive,
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
      const data = {
        ...formData,
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
