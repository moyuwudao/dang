// 套餐编辑子组件共享的类型定义

export interface PlanFormData {
  name: string;
  description?: string;
  priceCents: number;
  tokenQuota?: number;
  durationDays: number;
  type: string;
  isActive?: boolean;
  // 是否推荐（APK 端 Store 卡片显示"推荐"徽章）
  isRecommended?: boolean;
  // 套餐特性列表（云端录入，APK 端 Store 卡片展示为卖点）
  features?: string[];
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

export interface ApiKeyItem {
  id: string;
  provider: string;
  name: string;
  model: string;
  scopes: string;
  status: string;
  isDefault: boolean;
  supportedFeatures?: string[];
  // 来自计费配置（api_configs）的权威系数，套餐编辑中只读
  baseCoefficient?: number;
}

export interface ApiConfigItem {
  id: string;
  provider: string;
  modelPattern: string;
  modelName?: string;
  baseCoefficient: number; // 计费配置中的权威系数
  isActive: boolean;
}

export interface FunctionType {
  key: string;
  label: string;
  icon: any;
  desc: string;
}
