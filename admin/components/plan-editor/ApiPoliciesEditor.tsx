'use client';

import { Spinner, Chip, Tooltip } from '@nextui-org/react';
import { ListChecks, Info, Lock } from 'lucide-react';
import { ApiKeyItem, PlanFormData } from './types';

interface Props {
  apiKeys: ApiKeyItem[];
  loadingApiKeys: boolean;
  allowedModels: string[];
  apiPolicies: PlanFormData['apiPolicies'];
  onToggleModel: (model: string) => void;
  onSetApiPolicyField: (model: string, field: 'isAllowed', value: boolean) => void;
}

/**
 * 可用 API 编辑器
 *
 * 关键设计：
 * 1. 系数（multiplier）来源于计费配置 api_configs.baseCoefficient
 * 2. 套餐编辑中**不允许修改**系数，只读展示（带锁图标 + 提示）
 * 3. 用户可切换 isAllowed（是否允许此套餐使用该 API）
 * 4. 实际 API 列表只显示 api_keys 中 status='active' 的
 */
export default function ApiPoliciesEditor({
  apiKeys,
  loadingApiKeys,
  allowedModels,
  apiPolicies,
  onToggleModel,
  onSetApiPolicyField,
}: Props) {
  // 系数取自 apiKey.baseCoefficient（来自计费配置）
  const getModelMultiplier = (model: string): number => {
    const api = apiKeys.find((k) => k.model === model);
    return api?.baseCoefficient ?? 1.0;
  };
  const getModelIsAllowed = (model: string): boolean => {
    return apiPolicies?.find((p) => p.model === model)?.isAllowed ?? true;
  };

  // 过滤：只显示 active 的 API
  const activeApiKeys = apiKeys.filter((k) => k.status === 'active');
  // 过滤后去重（按 model 唯一）
  const uniqueApiKeys = Array.from(
    new Map(activeApiKeys.map((k) => [k.model, k])).values()
  );

  const unconfiguredCount = uniqueApiKeys.filter(
    (k) => !k.supportedFeatures || k.supportedFeatures.length === 0
  ).length;

  // 缺少计费配置（没有 baseCoefficient）的 API
  const missingConfigCount = uniqueApiKeys.filter(
    (k) => k.baseCoefficient === undefined
  ).length;

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-lg font-semibold mb-2 flex items-center gap-2">
          <ListChecks className="w-5 h-5 text-blue-600" />
          可用 API
        </h2>
        <p className="text-sm text-gray-500 mb-4">
          勾选此套餐允许用户调用的 API。系数由<b>计费配置</b>统一管理，套餐中不可修改。
        </p>
      </div>

      {/* 统计信息 */}
      <div className="grid grid-cols-4 gap-3">
        <div className="bg-blue-50 border border-blue-100 rounded-lg p-3">
          <div className="text-xs text-blue-600 mb-1">API 总数</div>
          <div className="text-2xl font-bold text-blue-700">{uniqueApiKeys.length}</div>
        </div>
        <div className="bg-green-50 border border-green-100 rounded-lg p-3">
          <div className="text-xs text-green-600 mb-1">已选 API</div>
          <div className="text-2xl font-bold text-green-700">{allowedModels.length}</div>
        </div>
        <div className="bg-amber-50 border border-amber-100 rounded-lg p-3">
          <div className="text-xs text-amber-600 mb-1">未配置功能</div>
          <div className="text-2xl font-bold text-amber-700">{unconfiguredCount}</div>
        </div>
        <div className="bg-red-50 border border-red-100 rounded-lg p-3">
          <div className="text-xs text-red-600 mb-1">缺计费系数</div>
          <div className="text-2xl font-bold text-red-700">{missingConfigCount}</div>
        </div>
      </div>

      {loadingApiKeys ? (
        <div className="flex items-center gap-2 text-gray-500 p-8 justify-center">
          <Spinner size="sm" /> 加载 API 列表...
        </div>
      ) : uniqueApiKeys.length === 0 ? (
        <div className="text-amber-600 text-sm bg-amber-50 border border-amber-200 rounded p-3 flex items-start gap-2">
          <Info className="w-4 h-4 mt-0.5 shrink-0" />
          <span>
            暂无可用 API，请先到 <b>API Key 管理</b> 添加 API Key（status 必须为 active）
          </span>
        </div>
      ) : (
        <>
          {missingConfigCount > 0 && (
            <div className="p-2 bg-red-50 border border-red-200 rounded text-xs text-red-800 flex items-start gap-2">
              <Info className="w-4 h-4 mt-0.5 shrink-0" />
              <span>
                有 {missingConfigCount} 个 API 在 <b>计费配置（api_configs）</b> 中缺少系数配置，
                请到 <b>计费配置 → API 配置管理</b> 补充 <code>base_coefficient</code>。
                缺失系数的 API 在套餐中不可用。
              </span>
            </div>
          )}

          {unconfiguredCount > 0 && (
            <div className="p-2 bg-amber-50 border border-amber-200 rounded text-xs text-amber-800 flex items-start gap-2">
              <Info className="w-4 h-4 mt-0.5 shrink-0" />
              <span>
                有 {unconfiguredCount} 个 API Key <b>未配置支持的功能</b>，它们不会出现在「各功能默认 API」下拉中。
              </span>
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-2 max-h-[480px] overflow-y-auto border border-gray-200 rounded-lg p-3">
            {uniqueApiKeys.map((k) => {
              const isSelected = allowedModels.includes(k.model);
              const features = k.supportedFeatures || [];
              const hasFeatures = features.length > 0;
              const hasCoefficient = k.baseCoefficient !== undefined;
              const multiplier = getModelMultiplier(k.model);
              const isAllowed = getModelIsAllowed(k.model);
              const disabled = !hasCoefficient; // 缺系数的不可用
              return (
                <div
                  key={k.id}
                  className={`p-2 rounded border ${
                    isSelected && !disabled
                      ? 'border-blue-300 bg-blue-50/40'
                      : disabled
                      ? 'border-red-200 bg-red-50/40 opacity-60'
                      : 'border-gray-200'
                  } ${!hasFeatures ? 'ring-1 ring-amber-200' : ''}`}
                >
                  <div
                    className={`flex items-center gap-2 p-2 rounded ${
                      disabled ? 'cursor-not-allowed' : 'cursor-pointer hover:bg-gray-50'
                    }`}
                    onClick={() => !disabled && onToggleModel(k.model)}
                  >
                    <input
                      type="checkbox"
                      checked={isSelected && !disabled}
                      disabled={disabled}
                      onChange={() => {}}
                      className="rounded"
                    />
                    <div className="flex-1 min-w-0">
                      <div className="text-sm font-medium truncate flex items-center gap-1">
                        {k.name}
                        {disabled && (
                          <span className="text-[9px] px-1 py-0.5 bg-red-100 text-red-700 rounded">
                            缺系数
                          </span>
                        )}
                        {!hasFeatures && !disabled && (
                          <span className="text-[9px] px-1 py-0.5 bg-amber-100 text-amber-700 rounded">
                            未配置功能
                          </span>
                        )}
                      </div>
                      <div className="text-xs text-gray-500 truncate">
                        {k.model} · {k.provider}
                      </div>
                      {hasFeatures ? (
                        <div className="flex flex-wrap gap-0.5 mt-0.5">
                          {features.slice(0, 3).map((f) => (
                            <span
                              key={f}
                              className="text-[9px] px-1 py-0.5 bg-blue-50 text-blue-700 rounded border border-blue-100"
                              title={f}
                            >
                              {f === 'textAnalysis'
                                ? '文本'
                                : f === 'speechTranscribe'
                                ? '转写'
                                : f === 'speechRealtime'
                                ? '实时'
                                : f === 'speechOffline'
                                ? '离线'
                                : f === 'imageRecognition'
                                ? '图像'
                                : f === 'all'
                                ? '全'
                                : f}
                            </span>
                          ))}
                          {features.length > 3 && (
                            <span className="text-[9px] text-gray-400">
                              +{features.length - 3}
                            </span>
                          )}
                        </div>
                      ) : (
                        !disabled && (
                          <div className="text-[9px] text-amber-600 mt-0.5">
                            ⚠ 请到 API Key 管理配置
                          </div>
                        )
                      )}
                    </div>
                    {k.isDefault && (
                      <span className="text-xs bg-green-100 text-green-700 px-1.5 py-0.5 rounded">
                        默认
                      </span>
                    )}
                  </div>

                  {/* 选中时显示系数（只读）和允许开关 */}
                  {isSelected && !disabled && (
                    <div className="flex items-center gap-2 mt-2 pt-2 border-t border-blue-100">
                      {/* 系数：只读 Chip，标明来源 */}
                      <Tooltip
                        content="系数由「计费配置 → API 配置管理」统一维护，套餐中不可修改"
                        placement="top"
                      >
                        <div className="flex items-center gap-1 flex-1 px-1">
                          <Lock className="w-3 h-3 text-gray-400" />
                          <span className="text-[10px] text-gray-600">系数</span>
                          <Chip
                            size="sm"
                            variant="flat"
                            color="default"
                            classNames={{
                              base: 'h-5 px-1.5',
                              content: 'text-[10px] font-mono font-semibold text-blue-700',
                            }}
                          >
                            {multiplier.toFixed(2)}x
                          </Chip>
                          <span className="text-[9px] text-gray-400 ml-auto">来自计费配置</span>
                        </div>
                      </Tooltip>

                      {/* 允许开关 */}
                      <div className="flex items-center gap-1">
                        <span className="text-[10px] text-gray-600">允许</span>
                        <input
                          type="checkbox"
                          checked={isAllowed}
                          onChange={(e) => onSetApiPolicyField(k.model, 'isAllowed', e.target.checked)}
                          onClick={(e) => e.stopPropagation()}
                          className="rounded w-4 h-4 cursor-pointer"
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

      <div className="text-xs text-gray-400">
        💡 已选 {allowedModels.length} 个 API · 系数统一来源于<b>计费配置（api_configs）</b>，不在套餐中维护
      </div>
    </div>
  );
}
