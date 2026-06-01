// 统一TOKEN计费系统类型定义

export interface TokenPricing {
  id: string;
  provider: string;
  modelPattern: string;
  promptPricePer1k: number;
  completionPricePer1k: number;
  conversionRate: number;
  isActive: boolean;
}

export interface ConsumeResult {
  success: boolean;
  consumed: number;
  remaining: number;
  costCents?: number;
  message?: string;
}
