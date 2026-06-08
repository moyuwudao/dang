'use client';

import { Select, SelectItem } from '@nextui-org/react';
import { Brain, Info, FileText, MessageSquare, Mic, MicOff, Image as ImageIcon } from 'lucide-react';
import { ApiKeyItem } from './types';

interface Props {
  apiKeys: ApiKeyItem[];
  allowedModels: string[];
  defaultConfigs: Record<string, string>;
  onSetDefaultConfig: (field: string, value: string) => void;
}

const FUNCTION_TYPES = [
  { key: 'textAnalysis', label: '文本分析', icon: FileText, desc: '摘要、聊天、文本理解' },
  { key: 'speechTranscribe', label: '语言转写', icon: MessageSquare, desc: '文本翻译、转写' },
  { key: 'speechRealtime', label: '语音实时转写', icon: Mic, desc: '实时语音转文字' },
  { key: 'speechOffline', label: '离线语音转写', icon: MicOff, desc: '上传音频文件转文字' },
  { key: 'imageRecognition', label: '图像识别', icon: ImageIcon, desc: '图片理解、OCR' },
];

/**
 * 各功能默认 API 编辑器
 * 为每种功能设定默认调用的 API。客户端开启此套餐时将自动使用这些 API。
 *
 * 过滤规则：
 * 1) 必须在「可用 API」中已勾选
 * 2) 必须支持该功能
 */
export default function FunctionDefaultsEditor({
  apiKeys,
  allowedModels,
  defaultConfigs,
  onSetDefaultConfig,
}: Props) {
  // 某 API 是否支持某功能
  const apiSupportsFeature = (api: ApiKeyItem, featureKey: string): boolean => {
    const supported = api.supportedFeatures || [];
    if (supported.length === 0) return false;
    if (supported.includes('all')) return true;
    return supported.includes(featureKey);
  };

  // 某功能可选的 API 列表
  const getAvailableApisForFeature = (featureKey: string): ApiKeyItem[] => {
    return apiKeys.filter(
      (k) => allowedModels.includes(k.model) && apiSupportsFeature(k, featureKey)
    );
  };

  // 已选中的 API 是否还支持该功能（陈旧检测）
  const isCurrentSelectionStale = (featureKey: string): boolean => {
    const currentValue = defaultConfigs?.[featureKey];
    if (!currentValue) return false;
    const currentApi = apiKeys.find((k) => k.model === currentValue);
    if (!currentApi) return false;
    return !apiSupportsFeature(currentApi, featureKey);
  };

  const configuredCount = FUNCTION_TYPES.filter(
    (ft) => defaultConfigs?.[ft.key]
  ).length;

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-lg font-semibold mb-2 flex items-center gap-2">
          <Brain className="w-5 h-5 text-purple-600" />
          各功能默认 API
        </h2>
        <p className="text-sm text-gray-500 mb-4">
          为每种功能设定默认调用的 API。客户端开启此套餐时将自动使用这些 API（用户可在 API 配置管理中覆盖）。
        </p>
      </div>

      {/* 完成度统计 */}
      <div className="flex items-center gap-3 p-3 bg-purple-50 border border-purple-100 rounded-lg">
        <Info className="w-4 h-4 text-purple-600 shrink-0" />
        <div className="flex-1 text-xs text-purple-700">
          已配置 <b>{configuredCount}</b> / {FUNCTION_TYPES.length} 个功能的默认 API
        </div>
        <div className="flex-1 max-w-[200px] h-1.5 bg-purple-100 rounded-full overflow-hidden">
          <div
            className="h-full bg-purple-500 transition-all"
            style={{ width: `${(configuredCount / FUNCTION_TYPES.length) * 100}%` }}
          />
        </div>
      </div>

      {apiKeys.length === 0 ? (
        <div className="text-amber-600 text-sm bg-amber-50 border border-amber-200 rounded p-3 flex items-start gap-2">
          <Info className="w-4 h-4 mt-0.5 shrink-0" />
          <span>请先到 <b>API Key 管理</b> 添加 API Key</span>
        </div>
      ) : allowedModels.length === 0 ? (
        <div className="text-amber-600 text-sm bg-amber-50 border border-amber-200 rounded p-3 flex items-start gap-2">
          <Info className="w-4 h-4 mt-0.5 shrink-0" />
          <span>请先在上一步「可用 API」中勾选至少一个 API</span>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {FUNCTION_TYPES.map((ft) => {
            const Icon = ft.icon;
            const currentValue = defaultConfigs?.[ft.key] || '';
            const currentKey = apiKeys.find((k) => k.model === currentValue);
            const availableApis = getAvailableApisForFeature(ft.key);
            const stale = isCurrentSelectionStale(ft.key);
            return (
              <div
                key={ft.key}
                className={`p-3 border rounded-lg ${
                  stale ? 'border-amber-300 bg-amber-50/50' : 'border-gray-200 bg-gray-50/30'
                }`}
              >
                {/* 头部：图标+标题+已选 badge */}
                <div className="flex items-center gap-2 mb-2">
                  <Icon className="w-4 h-4 text-blue-600 shrink-0" />
                  <div className="flex-1 min-w-0">
                    <div className="text-sm font-semibold text-gray-800 leading-tight">
                      {ft.label}
                    </div>
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
                  onChange={(e) => onSetDefaultConfig(ft.key, e.target.value)}
                >
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
      )}
    </div>
  );
}
