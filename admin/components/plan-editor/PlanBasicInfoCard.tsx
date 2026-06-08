'use client';

import { Input, Select, SelectItem, Switch, Textarea, Button } from '@nextui-org/react';
import { Plus, X } from 'lucide-react';
import { PlanFormData } from './types';

interface Props {
  formData: PlanFormData;
  onChange: (patch: Partial<PlanFormData>) => void;
}

const PLAN_TYPES = [
  { label: '月度套餐', value: 'monthly' },
  { label: '充值', value: 'recharge' },
];

/**
 * 套餐基本信息卡片
 * 包含：套餐名称、价格、Token配额、时长、类型、描述、启用开关
 * 特色卖点（features）和推荐套餐（isRecommended）会同步展示在 APK 端 Store 卡片
 */
export default function PlanBasicInfoCard({ formData, onChange }: Props) {
  const features = formData.features || [];

  const setFeatures = (next: string[]) => {
    onChange({ features: next });
  };

  const addFeature = () => {
    setFeatures([...features, '']);
  };

  const updateFeature = (index: number, value: string) => {
    const next = [...features];
    next[index] = value;
    setFeatures(next);
  };

  const removeFeature = (index: number) => {
    setFeatures(features.filter((_, i) => i !== index));
  };

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-lg font-semibold mb-4">基本信息</h2>
        <p className="text-sm text-gray-500 mb-4">
          设置套餐名称、价格、Token配额和有效期等基础信息。
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Input
          label="套餐名称"
          value={formData.name}
          onChange={(e) => onChange({ name: e.target.value })}
          isRequired
          size="sm"
          variant="bordered"
        />

        <Input
          label="价格(分)"
          type="number"
          value={formData.priceCents.toString()}
          onChange={(e) => onChange({ priceCents: parseInt(e.target.value) || 0 })}
          isRequired
          size="sm"
          variant="bordered"
          description="单位：分，1元 = 100分"
        />

        <Input
          label="Token配额"
          type="number"
          value={formData.tokenQuota?.toString() || '0'}
          onChange={(e) => onChange({ tokenQuota: parseInt(e.target.value) || 0 })}
          isRequired
          size="sm"
          variant="bordered"
          description="套餐内可用的Token数量"
        />

        <Input
          label="时长(天)"
          type="number"
          value={formData.durationDays.toString()}
          onChange={(e) => onChange({ durationDays: parseInt(e.target.value) || 0 })}
          isRequired
          size="sm"
          variant="bordered"
          description="套餐有效天数"
        />

        <Select
          label="套餐类型"
          selectedKeys={[formData.type]}
          onChange={(e) => onChange({ type: e.target.value })}
          isRequired
          size="sm"
          variant="bordered"
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
        onChange={(e) => onChange({ description: e.target.value })}
        size="sm"
        variant="bordered"
        minRows={2}
        description="套餐的功能说明，将展示在客户端订阅页"
      />

      {/* 特性卖点列表（APK 端 Store 卡片展示） */}
      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <div>
            <label className="text-sm font-medium">特性卖点</label>
            <p className="text-xs text-gray-500">
              列出该套餐的核心卖点（如：100万 Token、6 个 API 模型、5x 倍数加价模型），APK 端 Store 卡片会逐条展示
            </p>
          </div>
          <Button
            size="sm"
            color="primary"
            variant="flat"
            startContent={<Plus className="w-3 h-3" />}
            onPress={addFeature}
          >
            添加
          </Button>
        </div>
        {features.length === 0 && (
          <div className="text-xs text-gray-400 px-3 py-2 bg-gray-50 rounded border border-dashed">
            暂无特性，点击「添加」开始
          </div>
        )}
        {features.map((f, idx) => (
          <div key={idx} className="flex items-center gap-2">
            <Input
              size="sm"
              variant="bordered"
              value={f}
              onChange={(e) => updateFeature(idx, e.target.value)}
              placeholder={`例如：100W Token 配额`}
              classNames={{ base: 'flex-1' }}
            />
            <Button
              size="sm"
              isIconOnly
              variant="light"
              color="danger"
              onPress={() => removeFeature(idx)}
            >
              <X className="w-4 h-4" />
            </Button>
          </div>
        ))}
      </div>

      <div className="flex flex-col gap-3 pt-2">
        <div className="flex items-center gap-2">
          <Switch
            isSelected={formData.isActive ?? true}
            onValueChange={(isSelected) => onChange({ isActive: isSelected })}
            size="sm"
          />
          <span className="text-sm">启用此套餐</span>
          <span className="text-xs text-gray-400 ml-2">（关闭后用户将无法订阅）</span>
        </div>
        <div className="flex items-center gap-2">
          <Switch
            isSelected={formData.isRecommended ?? false}
            onValueChange={(isSelected) => onChange({ isRecommended: isSelected })}
            size="sm"
          />
          <span className="text-sm">标记为推荐套餐</span>
          <span className="text-xs text-gray-400 ml-2">（APK 端 Store 卡片显示「推荐」徽章）</span>
        </div>
      </div>
    </div>
  );
}
