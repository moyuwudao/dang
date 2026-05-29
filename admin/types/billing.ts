// 多模式计费系统类型定义

export interface PlanFeatureQuota {
  id: string;
  planId: string;
  featureType: FeatureType;
  quotaValue: number;
  quotaUnit: string;
  multiplier: number;
}

export type FeatureType = 
  | 'transcription'
  | 'realtime_transcription'
  | 'text_analysis'
  | 'image_recognition'
  | 'ocr'
  | 'ai_chat'
  | 'tts';

export interface FeatureTypeConfig {
  key: FeatureType;
  label: string;
  description: string;
  unit: string;
  unitLabel: string;
}

export const FEATURE_TYPES: FeatureTypeConfig[] = [
  { key: 'transcription', label: '语音转写', description: '音频文件转文字', unit: 'minutes', unitLabel: '分钟' },
  { key: 'realtime_transcription', label: '实时转写', description: '实时语音转文字', unit: 'minutes', unitLabel: '分钟' },
  { key: 'text_analysis', label: '文本分析', description: 'AI文本分析、摘要、翻译等', unit: 'thousand_chars', unitLabel: '千字符' },
  { key: 'image_recognition', label: '图像识别', description: '图片文字识别、物体识别等', unit: 'images', unitLabel: '张' },
  { key: 'ocr', label: 'OCR识别', description: '图片文字提取', unit: 'images', unitLabel: '张' },
  { key: 'ai_chat', label: 'AI对话', description: 'AI聊天对话', unit: 'tokens', unitLabel: 'tokens' },
  { key: 'tts', label: '语音合成', description: '文字转语音', unit: 'thousand_chars', unitLabel: '千字符' },
];

export interface UserFeatureUsage {
  id: string;
  userId: string;
  subscriptionId: string;
  featureType: FeatureType;
  usedAmount: number;
  totalAmount: number;
  unit: string;
}

export interface TokenPricing {
  id: string;
  provider: string;
  modelPattern: string;
  promptPricePer1k: number;
  completionPricePer1k: number;
  isActive: boolean;
}

export interface ConsumeResult {
  success: boolean;
  consumed: number;
  remaining: number;
  costCents?: number;
  message?: string;
}

export interface FeatureUsageSummary {
  featureType: FeatureType;
  remaining: number;
  unit: string;
}
