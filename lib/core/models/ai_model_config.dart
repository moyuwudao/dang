import 'package:flutter/material.dart';

/// AI 服务提供商枚举（仅保留国内 6 家：深度求索、通义千问、智谱、Kimi、MiniMax、豆包）
enum AiProvider {
  deepSeek,
  qwen,
  zhipu,
  kimi,
  minimax,
  doubao,
}

enum ApiFunctionType {
  text,
  voice,
  voiceRealtime,
  image,
  offlineVoice,
}

enum AppFeature {
  recording,
  textAnalysis,
  speechTranscription,
  speechRealtimeTranscription,
  speakerDiarization,
  ocr,
  chatSummary,
  titleGeneration,
}

enum TranscriptionMethod {
  whisperApi,
  audioUpload,
  nativeAsr,
  asyncAsr,
  realtimeWebSocket,
}

class TranscriptionLimit {
  final int maxDurationSeconds;
  final int maxFileSizeMB;
  final String durationLabel;
  final String note;

  const TranscriptionLimit({
    required this.maxDurationSeconds,
    required this.maxFileSizeMB,
    required this.durationLabel,
    this.note = '',
  });
}

class ModelDetail {
  final String name;
  final String description;
  final String contextWindow;
  final bool recommended;

  const ModelDetail({
    required this.name,
    required this.description,
    this.contextWindow = '',
    this.recommended = false,
  });
}

class AiModelConfig {
  final AiProvider provider;
  final String name;
  final String displayName;
  final String baseUrl;
  final String defaultModel;
  final List<String> availableModels;
  final bool supportsTranscription;
  final bool supportsRealtimeTranscription;
  final bool supportsOfflineTranscription;
  final bool supportsSpeakerDiarization;
  final bool supportsChat;
  final bool supportsTextAnalysis;
  final bool supportsOCR;
  final String? apiKeyPrefix;
  final String description;
  final TranscriptionMethod transcriptionMethod;
  final TranscriptionMethod? realtimeTranscriptionMethod;
  final TranscriptionLimit? transcriptionLimit;
  final List<ModelDetail> modelDetails;
  final String asrModel;
  final String asrDescription;
  final String realtimeAsrModel;
  final String realtimeAsrDescription;
  final String visionModel;
  final String limitationNote;
  final String pricingNote;
  final bool requiresAppId;
  final String? appIdDescription;
  final String? appIdLabel;
  final String? appIdHint;
  final bool requiresAccessKeySecret;
  final String? accessKeySecretDescription;
  final String? accessKeySecretLabel;
  final String? accessKeySecretHint;
  final String? apiKeyLabel;
  final String? apiKeyHint;
  final String? apiKeyDescription;

  const AiModelConfig({
    required this.provider,
    required this.name,
    required this.displayName,
    required this.baseUrl,
    required this.defaultModel,
    required this.availableModels,
    this.supportsTranscription = false,
    this.supportsRealtimeTranscription = false,
    this.supportsOfflineTranscription = false,
    this.supportsSpeakerDiarization = false,
    this.supportsChat = true,
    this.supportsTextAnalysis = true,
    this.supportsOCR = false,
    this.visionModel = '',
    this.apiKeyPrefix,
    required this.description,
    this.transcriptionMethod = TranscriptionMethod.whisperApi,
    this.realtimeTranscriptionMethod,
    this.transcriptionLimit,
    this.modelDetails = const [],
    this.asrModel = '',
    this.asrDescription = '',
    this.realtimeAsrModel = '',
    this.realtimeAsrDescription = '',
    this.limitationNote = '',
    this.pricingNote = '',
    this.requiresAppId = false,
    this.appIdDescription,
    this.appIdLabel,
    this.appIdHint,
    this.requiresAccessKeySecret = false,
    this.accessKeySecretDescription,
    this.accessKeySecretLabel,
    this.accessKeySecretHint,
    this.apiKeyLabel,
    this.apiKeyHint,
    this.apiKeyDescription,
  });

  /// 全部国内提供商列表（6 家，已摒弃国外模型）
  static const List<AiModelConfig> allProviders = [
    deepSeek,
    qwen,
    zhipu,
    kimi,
    minimax,
    doubao,
  ];

  static bool canUseFeature(AppFeature feature, AiProvider? configuredProvider) {
    switch (feature) {
      case AppFeature.recording:
        return true;
      case AppFeature.textAnalysis:
        if (configuredProvider == null) return false;
        final config = getConfig(configuredProvider);
        return config.supportsTextAnalysis;
      case AppFeature.speechTranscription:
        if (configuredProvider == null) return false;
        final config = getConfig(configuredProvider);
        return config.supportsTranscription || config.supportsOfflineTranscription;
      case AppFeature.speechRealtimeTranscription:
        if (configuredProvider == null) return false;
        final config = getConfig(configuredProvider);
        return config.supportsRealtimeTranscription;
      case AppFeature.speakerDiarization:
        if (configuredProvider == null) return false;
        final config = getConfig(configuredProvider);
        return config.supportsSpeakerDiarization;
      case AppFeature.ocr:
        if (configuredProvider == null) return false;
        final config = getConfig(configuredProvider);
        return config.supportsOCR;
      case AppFeature.chatSummary:
      case AppFeature.titleGeneration:
        if (configuredProvider == null) return false;
        final config = getConfig(configuredProvider);
        return config.supportsChat || config.supportsTextAnalysis;
    }
  }

  static String? getFeatureDisabledReason(AppFeature feature, AiProvider? configuredProvider) {
    switch (feature) {
      case AppFeature.recording:
        return null;
      case AppFeature.textAnalysis:
        if (configuredProvider == null) {
          return '请先配置 AI 模型 API Key';
        }
        final config = getConfig(configuredProvider);
        if (!config.supportsTextAnalysis) {
          return '${config.displayName} 不支持文本分析';
        }
        return null;
      case AppFeature.speechTranscription:
        if (configuredProvider == null) {
          return '请先配置 AI 模型 API Key';
        }
        final config = getConfig(configuredProvider);
        if (!config.supportsTranscription) {
          return '${config.displayName} 不支持语音转写，请使用通义千问';
        }
        return null;
      case AppFeature.speechRealtimeTranscription:
        if (configuredProvider == null) {
          return '请先配置 AI 模型 API Key';
        }
        final config = getConfig(configuredProvider);
        if (!config.supportsRealtimeTranscription) {
          return '${config.displayName} 不支持实时语音转写，请使用通义千问';
        }
        return null;
      case AppFeature.speakerDiarization:
        if (configuredProvider == null) {
          return '请先配置 AI 模型 API Key';
        }
        final config = getConfig(configuredProvider);
        if (!config.supportsSpeakerDiarization) {
          return '${config.displayName} 不支持说话人分离，需要专用的声纹识别 API';
        }
        return null;
      case AppFeature.ocr:
        if (configuredProvider == null) {
          return '请先配置 AI 模型 API Key';
        }
        final config = getConfig(configuredProvider);
        if (!config.supportsOCR) {
          return '${config.displayName} 不支持图像识别，请使用通义千问 VL 或豆包视觉模型';
        }
        return null;
      case AppFeature.chatSummary:
      case AppFeature.titleGeneration:
        if (configuredProvider == null) {
          return '请先配置 AI 模型 API Key';
        }
        final config = getConfig(configuredProvider);
        if (!config.supportsChat && !config.supportsTextAnalysis) {
          return '${config.displayName} 不支持对话或文本分析';
        }
        return null;
    }
  }

  /// DeepSeek（深度求索）— 1M 上下文，性价比极高，OpenAI 兼容格式
  static const deepSeek = AiModelConfig(
    provider: AiProvider.deepSeek,
    name: 'deepseek',
    displayName: 'DeepSeek 深度求索',
    baseUrl: 'https://api.deepseek.com/v1',
    defaultModel: 'deepseek-v4-flash',
    availableModels: [
      'deepseek-v4-pro',
      'deepseek-v4-flash',
      'deepseek-chat',
      'deepseek-reasoner',
    ],
    supportsTranscription: false,
    supportsChat: true,
    apiKeyPrefix: null,
    description: 'DeepSeek V4：1M 上下文，性价比突出，OpenAI 兼容格式。擅长推理与代码。',
    limitationNote: '不支持语音转写，仅用于对话/摘要。',
    modelDetails: [
      ModelDetail(name: 'deepseek-v4-pro', description: 'V4 旗舰，最佳质量', contextWindow: '1M', recommended: false),
      ModelDetail(name: 'deepseek-v4-flash', description: 'V4 快速版，性价比高', contextWindow: '1M', recommended: true),
      ModelDetail(name: 'deepseek-chat', description: 'V3（2026-07 弃用）', contextWindow: '64K', recommended: false),
      ModelDetail(name: 'deepseek-reasoner', description: '深度思考（2026-07 弃用）', contextWindow: '64K', recommended: false),
    ],
    pricingNote: '对话: ¥0.5-10/百万 tokens | 性价比极高',
  );

  /// 通义千问（阿里云）— 中文理解强，支持 ASR/实时转写/VL 视觉
  static const qwen = AiModelConfig(
    provider: AiProvider.qwen,
    name: 'qwen',
    displayName: '通义千问',
    baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    defaultModel: 'qwen-turbo',
    availableModels: [
      'qwen-turbo',
      'qwen-plus',
      'qwen-max',
      'qwen3.6-flash',
      'qwen3.6-plus',
      'qwen3.6-max',
      // VL（视觉）模型：只有这些模型支持图像识别
      'qwen-vl-plus',
      'qwen-vl-plus-latest',
      'qwen-vl-max',
      'qwen-vl-max-latest',
      'qwen3-vl-plus',
      'qwen3-vl-plus-latest',
      'qwen3-vl-flash',
      'qwen3-vl-flash-latest',
      'qwen2-vl-7b-instruct',
      'qwen2-vl-72b-instruct',
      'qwen2.5-vl-32b-instruct',
      'qwen2.5-vl-72b-instruct',
    ],
    supportsTranscription: true,
    supportsRealtimeTranscription: true,
    supportsOfflineTranscription: true,
    supportsSpeakerDiarization: false,
    supportsChat: true,
    supportsTextAnalysis: true,
    supportsOCR: true,
    visionModel: 'qwen-vl-plus',
    apiKeyPrefix: 'sk-',
    requiresAppId: false,
    description: '阿里云通义千问系列。中文理解能力强，支持语音转写和实时语音转写。语音转写用 qwen3-asr-flash，实时转写用 WebSocket 流式接口。不支持声纹识别（说话人分离）。',
    transcriptionMethod: TranscriptionMethod.nativeAsr,
    realtimeTranscriptionMethod: TranscriptionMethod.realtimeWebSocket,
    transcriptionLimit: TranscriptionLimit(
      maxDurationSeconds: 43200,
      maxFileSizeMB: 500,
      durationLabel: '12 小时',
      note: '短音频(<5分钟,<10MB): qwen3-asr-flash 同步。长音频: qwen3-asr-flash-filetrans 异步。实时: qwen3-asr-flash WebSocket。',
    ),
    asrModel: 'qwen3-asr-flash',
    asrDescription: 'qwen3-asr-flash: 52 种语言 + 22 种中文方言，最佳开源 ASR 精度。\nqwen3-asr-flash-filetrans: 长音频异步转写，最长 12 小时。',
    realtimeAsrModel: 'qwen3-asr-flash',
    realtimeAsrDescription: 'DashScope WebSocket 实时 ASR，流式音频输入，增量文本输出，低延迟。',
    modelDetails: [
      ModelDetail(name: 'qwen3.6-max', description: '最强能力', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'qwen3.6-plus', description: '质量与成本均衡', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'qwen3.6-flash', description: '最快、最实惠', contextWindow: '128K', recommended: true),
      ModelDetail(name: 'qwen3-vl-plus', description: '最新视觉模型，图像 OCR 最佳', contextWindow: '128K', recommended: true),
      ModelDetail(name: 'qwen3-vl-plus-latest', description: '始终指向最新 Qwen3-VL-Plus', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'qwen3-vl-flash', description: '快速视觉模型，低成本', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'qwen-vl-plus', description: '视觉模型，图像 OCR', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'qwen-vl-max', description: '最佳视觉精度', contextWindow: '128K', recommended: false),
    ],
    pricingNote: '对话: ¥0.001-2/百万 tokens | ASR: ¥0.001-0.01/分钟 | 实时: ¥0.003/分钟',
  );

  /// 智谱 GLM — 开源友好，学术表现强
  static const zhipu = AiModelConfig(
    provider: AiProvider.zhipu,
    name: 'zhipu',
    displayName: '智谱 GLM',
    baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
    defaultModel: 'glm-5.1-flash',
    availableModels: [
      'glm-5.1',
      'glm-5.1-flash',
      'glm-4.7',
      'glm-4.7-flash',
      'glm-4-air',
      // 智谱视觉模型
      'glm-4v',
      'glm-4v-flash',
    ],
    supportsTranscription: false,
    supportsChat: true,
    supportsOCR: true,
    visionModel: 'glm-4v',
    apiKeyPrefix: null,
    description: '智谱 AI GLM 5.1 系列。开源友好，学术表现强。GLM-4V 支持图像识别。',
    limitationNote: '不支持语音转写，仅用于对话/摘要/图像识别。',
    modelDetails: [
      ModelDetail(name: 'glm-5.1', description: '旗舰模型', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'glm-5.1-flash', description: '快速、实惠', contextWindow: '128K', recommended: true),
      ModelDetail(name: 'glm-4.7', description: '稳定生成', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'glm-4.7-flash', description: '快速生成', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'glm-4v', description: '视觉模型', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'glm-4v-flash', description: '快速视觉模型', contextWindow: '128K', recommended: false),
    ],
    pricingNote: '对话: ¥0.001-0.1/百万 tokens',
  );

  /// Kimi（月之暗面）— 1T MoE，256K 上下文，Agent 与编码能力强
  static const kimi = AiModelConfig(
    provider: AiProvider.kimi,
    name: 'kimi',
    displayName: 'Kimi',
    baseUrl: 'https://api.moonshot.cn/v1',
    defaultModel: 'kimi-k2.6',
    availableModels: [
      'kimi-k2.6',
      'kimi-k2.5',
      'kimi-k2',
      'moonshot-v1-8k',
      'moonshot-v1-32k',
      'moonshot-v1-128k',
    ],
    supportsTranscription: false,
    supportsChat: true,
    apiKeyPrefix: null,
    description: '月之暗面 Kimi K2.6：1T MoE，256K 上下文，Agent 与编码能力突出。',
    limitationNote: '不支持语音转写，仅用于对话/摘要。',
    modelDetails: [
      ModelDetail(name: 'kimi-k2.6', description: '最新，1T MoE，最佳质量', contextWindow: '256K', recommended: true),
      ModelDetail(name: 'kimi-k2.5', description: '上一版本', contextWindow: '256K', recommended: false),
      ModelDetail(name: 'kimi-k2', description: '基础 K2 模型', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'moonshot-v1-128k', description: '长上下文 legacy', contextWindow: '128K', recommended: false),
    ],
    pricingNote: '对话: ¥0.012-24/百万 tokens',
  );

  /// MiniMax — OpenAI 兼容格式，支持长文本与多模态
  static const minimax = AiModelConfig(
    provider: AiProvider.minimax,
    name: 'minimax',
    displayName: 'MiniMax',
    baseUrl: 'https://api.minimax.chat/v1',
    defaultModel: 'MiniMax-Text-01',
    availableModels: [
      'MiniMax-Text-01',
      'MiniMax-M1',
      'abab6.5s-chat',
      'abab6.5-chat',
    ],
    supportsTranscription: false,
    supportsChat: true,
    supportsOCR: true,
    visionModel: 'MiniMax-Text-01',
    apiKeyPrefix: null,
    description: 'MiniMax 大模型，OpenAI 兼容格式，支持长文本与多模态（vl-01 视觉）。',
    limitationNote: '不支持语音转写，仅用于对话/摘要/图像识别。',
    modelDetails: [
      ModelDetail(name: 'MiniMax-Text-01', description: '旗舰，1M 上下文', contextWindow: '1M', recommended: true),
      ModelDetail(name: 'MiniMax-M1', description: '推理模型', contextWindow: '1M', recommended: false),
      ModelDetail(name: 'abab6.5s-chat', description: '快速版', contextWindow: '245K', recommended: false),
      ModelDetail(name: 'abab6.5-chat', description: '通用版', contextWindow: '245K', recommended: false),
    ],
    pricingNote: '对话: ¥0.001-2/百万 tokens',
  );

  /// 豆包（字节火山引擎）— OpenAI 兼容格式，支持视觉模型
  static const doubao = AiModelConfig(
    provider: AiProvider.doubao,
    name: 'doubao',
    displayName: '豆包',
    baseUrl: 'https://ark.cn-beijing.volces.com/api/v3',
    defaultModel: 'doubao-pro-32k',
    availableModels: [
      'doubao-pro-32k',
      'doubao-pro-128k',
      'doubao-pro-256k',
      'doubao-lite-32k',
      'doubao-lite-128k',
      // 视觉模型
      'doubao-vision-pro-32k',
      'doubao-vision-lite-32k',
    ],
    supportsTranscription: false,
    supportsChat: true,
    supportsOCR: true,
    visionModel: 'doubao-vision-pro-32k',
    apiKeyPrefix: null,
    description: '字节火山引擎豆包大模型，OpenAI 兼容格式，支持视觉模型。需要先在火山引擎控制台创建接入点（endpoint）。',
    limitationNote: '不支持语音转写，仅用于对话/摘要/图像识别。模型名需使用火山引擎的 endpoint ID。',
    modelDetails: [
      ModelDetail(name: 'doubao-pro-32k', description: '标准版', contextWindow: '32K', recommended: true),
      ModelDetail(name: 'doubao-pro-128k', description: '长上下文', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'doubao-pro-256k', description: '超长上下文', contextWindow: '256K', recommended: false),
      ModelDetail(name: 'doubao-lite-32k', description: '轻量版', contextWindow: '32K', recommended: false),
      ModelDetail(name: 'doubao-vision-pro-32k', description: '视觉模型', contextWindow: '32K', recommended: false),
      ModelDetail(name: 'doubao-vision-lite-32k', description: '轻量视觉', contextWindow: '32K', recommended: false),
    ],
    pricingNote: '对话: ¥0.0008-5/百万 tokens',
  );

  /// 获取指定 provider 的配置（fallback 到 deepSeek）
  static AiModelConfig getConfig(AiProvider provider) {
    return allProviders.firstWhere(
      (config) => config.provider == provider,
      orElse: () => deepSeek,
    );
  }

  /// 按名称获取配置
  static AiModelConfig? getConfigByName(String name) {
    try {
      return allProviders.firstWhere(
        (config) => config.name == name,
      );
    } catch (e) {
      return null;
    }
  }

  /// 国内提供商列表（全部 6 家）
  static List<AiModelConfig> get domesticProviders => allProviders;

  static List<AiModelConfig> get transcriptionProviders => allProviders
      .where((p) => p.supportsTranscription || p.supportsOfflineTranscription)
      .toList();

  static List<AiModelConfig> get offlineTranscriptionProviders => allProviders
      .where((p) => p.supportsOfflineTranscription)
      .toList();

  static List<AiModelConfig> get realtimeTranscriptionProviders => allProviders
      .where((p) => p.supportsRealtimeTranscription)
      .toList();

  static List<AiModelConfig> get textAnalysisProviders => allProviders
      .where((p) => p.supportsTextAnalysis)
      .toList();

  static List<AiModelConfig> get ocrProviders => allProviders
      .where((p) => p.supportsOCR)
      .toList();

  static List<AiModelConfig> get speakerDiarizationProviders => allProviders
      .where((p) => p.supportsSpeakerDiarization)
      .toList();

  /// 获取支持指定功能类型的所有提供商配置
  static List<AiModelConfig> getProvidersForFunction(ApiFunctionType functionType) {
    switch (functionType) {
      case ApiFunctionType.text:
        return textAnalysisProviders;
      case ApiFunctionType.voice:
        return transcriptionProviders;
      case ApiFunctionType.voiceRealtime:
        return realtimeTranscriptionProviders;
      case ApiFunctionType.image:
        return ocrProviders;
      case ApiFunctionType.offlineVoice:
        return offlineTranscriptionProviders;
    }
  }

  /// 检查指定提供商是否支持指定功能类型
  static bool providerSupportsFunction(AiProvider provider, ApiFunctionType functionType) {
    final config = getConfig(provider);
    switch (functionType) {
      case ApiFunctionType.text:
        return config.supportsTextAnalysis;
      case ApiFunctionType.voice:
        return config.supportsTranscription || config.supportsOfflineTranscription;
      case ApiFunctionType.voiceRealtime:
        return config.supportsRealtimeTranscription;
      case ApiFunctionType.image:
        return config.supportsOCR;
      case ApiFunctionType.offlineVoice:
        return config.supportsOfflineTranscription;
    }
  }

  /// 判断指定模型是否为视觉模型（支持图像识别）
  ///
  /// 规则：
  /// - 文本/转写功能：按 provider 级别判断
  /// - 图像识别：必须具体到模型，避免把普通模型也当成视觉模型
  static bool isVisionModel(AiProvider provider, String? model) {
    if (model == null || model.isEmpty) return false;
    final lower = model.toLowerCase();
    switch (provider) {
      case AiProvider.qwen:
        // Qwen 视觉模型命名规律：包含 -vl- 或 qwen3-vl- 等
        return lower.contains('-vl-') ||
            lower.startsWith('qwen-vl-') ||
            lower.startsWith('qwen2-vl-') ||
            lower.startsWith('qwen2.5-vl-') ||
            lower.startsWith('qwen3-vl-');
      case AiProvider.zhipu:
        // 智谱视觉模型：glm-4v 系列
        return lower.contains('glm-4v') || lower.contains('vision');
      case AiProvider.minimax:
        // MiniMax: vl-01 / vision 系列
        return lower.contains('vl-01') || lower.contains('vision');
      case AiProvider.doubao:
        // 豆包视觉模型：doubao-vision 系列
        return lower.contains('vision');
      case AiProvider.deepSeek:
      case AiProvider.kimi:
        // 当前不支持视觉
        return false;
    }
  }

  /// 检查指定 provider + model 是否支持指定功能类型
  static bool modelSupportsFunction(
    AiProvider provider,
    String? model,
    ApiFunctionType functionType,
  ) {
    // 非图像功能保持 provider 级别判断（足够且避免误判）
    if (functionType != ApiFunctionType.image) {
      return providerSupportsFunction(provider, functionType);
    }
    // 图像识别必须精确到模型能力
    final config = getConfig(provider);
    if (!config.supportsOCR) return false;
    return isVisionModel(provider, model);
  }

  /// 获取功能类型对应的中文名称
  static String getFunctionTypeLabel(ApiFunctionType functionType) {
    switch (functionType) {
      case ApiFunctionType.text:
        return '文本分析';
      case ApiFunctionType.voice:
        return '语音转写';
      case ApiFunctionType.voiceRealtime:
        return '实时语音转写';
      case ApiFunctionType.image:
        return '图像识别';
      case ApiFunctionType.offlineVoice:
        return '离线语音转写';
    }
  }

  /// 获取功能类型对应的图标
  static IconData getFunctionTypeIcon(ApiFunctionType functionType) {
    switch (functionType) {
      case ApiFunctionType.text:
        return Icons.chat_bubble_outline;
      case ApiFunctionType.voice:
        return Icons.mic;
      case ApiFunctionType.voiceRealtime:
        return Icons.record_voice_over;
      case ApiFunctionType.image:
        return Icons.image;
      case ApiFunctionType.offlineVoice:
        return Icons.offline_bolt;
    }
  }

  /// 获取不支持该功能的原因说明
  static String getUnsupportedReason(AiProvider provider, ApiFunctionType functionType) {
    final config = getConfig(provider);
    final functionName = getFunctionTypeLabel(functionType);
    final supportedFunctions = <String>[];

    if (config.supportsTextAnalysis) supportedFunctions.add('文本分析');
    if (config.supportsTranscription || config.supportsOfflineTranscription) supportedFunctions.add('语音转写');
    if (config.supportsRealtimeTranscription) supportedFunctions.add('实时语音转写');
    if (config.supportsOCR) supportedFunctions.add('图像识别');
    if (config.supportsOfflineTranscription) supportedFunctions.add('离线语音转写');

    if (supportedFunctions.isEmpty) {
      return '${config.displayName} 不支持 $functionName 功能。该模型目前无可用的功能支持。';
    }

    return '${config.displayName} 不支持 $functionName 功能。该模型仅支持: ${supportedFunctions.join('、')}。';
  }
}
