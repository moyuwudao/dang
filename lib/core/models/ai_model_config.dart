import 'package:flutter/material.dart';

enum AiProvider {
  openAI,
  claude,
  gemini,
  deepSeek,
  qwen,
  tingwu,
  ernie,
  zhipu,
  kimi,
  spark,
  grok,
  custom,
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

  static const List<AiModelConfig> allProviders = [
    openAI,
    deepSeek,
    claude,
    gemini,
    qwen,
    tingwu,
    ernie,
    zhipu,
    kimi,
    spark,
    grok,
    custom,
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
          return 'Please configure an AI model API Key first';
        }
        final config = getConfig(configuredProvider);
        if (!config.supportsTextAnalysis) {
          return '${config.displayName} does not support text analysis.';
        }
        return null;
      case AppFeature.speechTranscription:
        if (configuredProvider == null) {
          return 'Please configure an AI model API Key first';
        }
        final config = getConfig(configuredProvider);
        if (!config.supportsTranscription) {
          return '${config.displayName} does not support speech transcription. Please use OpenAI, Gemini, or Qwen.';
        }
        return null;
      case AppFeature.speechRealtimeTranscription:
        if (configuredProvider == null) {
          return 'Please configure an AI model API Key first';
        }
        final config = getConfig(configuredProvider);
        if (!config.supportsRealtimeTranscription) {
          return '${config.displayName} does not support real-time speech transcription. Please use iFlytek Spark or Aliyun Qwen.';
        }
        return null;
      case AppFeature.speakerDiarization:
        if (configuredProvider == null) {
          return 'Please configure an AI model API Key first';
        }
        final config = getConfig(configuredProvider);
        if (!config.supportsSpeakerDiarization) {
          return '${config.displayName} does not support speaker diarization (speaker recognition). This feature requires a dedicated speaker recognition API (e.g., Aliyun Voice ID, iFlytek Speaker Recognition).';
        }
        return null;
      case AppFeature.ocr:
        if (configuredProvider == null) {
          return 'Please configure an AI model API Key first';
        }
        final config = getConfig(configuredProvider);
        if (!config.supportsOCR) {
          return '${config.displayName} does not support image recognition. Please use OpenAI (GPT-4o), Gemini, or Qwen.';
        }
        return null;
      case AppFeature.chatSummary:
      case AppFeature.titleGeneration:
        if (configuredProvider == null) {
          return 'Please configure an AI model API Key first';
        }
        final config = getConfig(configuredProvider);
        if (!config.supportsChat && !config.supportsTextAnalysis) {
          return '${config.displayName} does not support chat or text analysis. Please use a model with chat capabilities.';
        }
        return null;
    }
  }

  static const openAI = AiModelConfig(
    provider: AiProvider.openAI,
    name: 'openai',
    displayName: 'OpenAI',
    baseUrl: 'https://api.openai.com/v1',
    defaultModel: 'gpt-4o-mini',
    availableModels: [
      'gpt-4o',
      'gpt-4o-mini',
      'gpt-4.1',
      'gpt-4.1-mini',
      'gpt-4.1-nano',
    ],
    supportsTranscription: true,
    supportsRealtimeTranscription: false,
    supportsSpeakerDiarization: false,
    supportsChat: true,
    supportsTextAnalysis: true,
    supportsOCR: true,
    visionModel: 'gpt-4o',
    apiKeyPrefix: 'sk-',
    description: 'Industry-leading AI with best-in-class Whisper transcription. Most reliable for voice-to-text. GPT-4o supports image recognition.',
    transcriptionMethod: TranscriptionMethod.whisperApi,
    transcriptionLimit: TranscriptionLimit(
      maxDurationSeconds: 600,
      maxFileSizeMB: 25,
      durationLabel: '10 min',
      note: 'Whisper API supports up to 25MB audio files',
    ),
    asrModel: 'whisper-1',
    asrDescription: 'Whisper v1: OpenAI\'s speech recognition model. Supports 99 languages, auto-detection, punctuation, and timestamps. Best accuracy for most scenarios.',
    modelDetails: [
      ModelDetail(name: 'gpt-4.1', description: 'Latest flagship, best reasoning', contextWindow: '1M', recommended: false),
      ModelDetail(name: 'gpt-4.1-mini', description: 'Balanced performance & cost', contextWindow: '1M', recommended: true),
      ModelDetail(name: 'gpt-4.1-nano', description: 'Fastest, lowest cost', contextWindow: '1M', recommended: false),
      ModelDetail(name: 'gpt-4o', description: 'Multimodal, vision support', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'gpt-4o-mini', description: 'Affordable multimodal', contextWindow: '128K', recommended: false),
    ],
    pricingNote: 'Chat: \$0.15-\$2/M tokens | ASR: \$0.006/min',
  );

  static const claude = AiModelConfig(
    provider: AiProvider.claude,
    name: 'claude',
    displayName: 'Claude',
    baseUrl: 'https://api.anthropic.com/v1',
    defaultModel: 'claude-sonnet-4-6',
    availableModels: [
      'claude-opus-4-7',
      'claude-opus-4-6',
      'claude-sonnet-4-6',
      'claude-haiku-4-5',
    ],
    supportsTranscription: false,
    supportsChat: true,
    apiKeyPrefix: 'sk-ant-',
    description: 'Anthropic\'s Claude 4 series. Excellent at reasoning, writing, and analysis. No ASR support.',
    limitationNote: 'Does not support audio transcription. Use for chat/summary only.',
    modelDetails: [
      ModelDetail(name: 'claude-opus-4-7', description: 'Most capable, complex tasks', contextWindow: '200K', recommended: false),
      ModelDetail(name: 'claude-opus-4-6', description: 'High capability', contextWindow: '200K', recommended: false),
      ModelDetail(name: 'claude-sonnet-4-6', description: 'Best balance of speed & quality', contextWindow: '200K', recommended: true),
      ModelDetail(name: 'claude-haiku-4-5', description: 'Fastest, most affordable', contextWindow: '200K', recommended: false),
    ],
    pricingNote: 'Chat: \$0.25-\$15/M tokens',
  );

  static const gemini = AiModelConfig(
    provider: AiProvider.gemini,
    name: 'gemini',
    displayName: 'Gemini',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
    defaultModel: 'gemini-2.5-flash',
    availableModels: [
      'gemini-2.5-pro',
      'gemini-2.5-flash',
      'gemini-3.1-pro',
    ],
    supportsTranscription: true,
    supportsRealtimeTranscription: false,
    supportsSpeakerDiarization: false,
    supportsChat: true,
    supportsTextAnalysis: true,
    supportsOCR: true,
    visionModel: 'gemini-2.5-flash',
    apiKeyPrefix: null,
    description: 'Google\'s Gemini with generous free tier. Supports audio upload for transcription via multimodal input. Also supports image recognition.',
    transcriptionMethod: TranscriptionMethod.audioUpload,
    transcriptionLimit: TranscriptionLimit(
      maxDurationSeconds: 300,
      maxFileSizeMB: 20,
      durationLabel: '5 min',
      note: 'Free tier: 15 RPM, 1M tokens/min. Audio processed as inline data.',
    ),
    asrModel: 'gemini-2.5-flash',
    asrDescription: 'Uses Gemini multimodal model to transcribe audio. Supports multiple languages. Less accurate than Whisper for pure ASR.',
    modelDetails: [
      ModelDetail(name: 'gemini-3.1-pro', description: 'Latest flagship', contextWindow: '1M', recommended: false),
      ModelDetail(name: 'gemini-2.5-pro', description: 'High quality reasoning', contextWindow: '1M', recommended: false),
      ModelDetail(name: 'gemini-2.5-flash', description: 'Fast & free tier available', contextWindow: '1M', recommended: true),
    ],
    pricingNote: 'Free tier available | Paid: \$0.075-\$1.25/M tokens',
  );

  static const grok = AiModelConfig(
    provider: AiProvider.grok,
    name: 'grok',
    displayName: 'Grok',
    baseUrl: 'https://api.x.ai/v1',
    defaultModel: 'grok-3',
    availableModels: [
      'grok-3',
      'grok-3-mini',
      'grok-2-1212',
    ],
    supportsTranscription: false,
    supportsChat: true,
    apiKeyPrefix: null,
    description: 'xAI\'s Grok 3 with real-time knowledge from X. Strong reasoning capabilities.',
    limitationNote: 'Does not support audio transcription. Use for chat/summary only.',
    modelDetails: [
      ModelDetail(name: 'grok-3', description: 'Flagship, real-time knowledge', contextWindow: '128K', recommended: true),
      ModelDetail(name: 'grok-3-mini', description: 'Affordable alternative', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'grok-2-1212', description: 'Previous generation', contextWindow: '128K', recommended: false),
    ],
    pricingNote: 'Chat: \$0.30-\$5/M tokens',
  );

  static const deepSeek = AiModelConfig(
    provider: AiProvider.deepSeek,
    name: 'deepseek',
    displayName: 'DeepSeek',
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
    description: 'DeepSeek V4: 1M context, outstanding cost-performance. OpenAI-compatible format.',
    limitationNote: 'No ASR support. deepseek-chat/reasoner will be deprecated on 2026-07-24.',
    modelDetails: [
      ModelDetail(name: 'deepseek-v4-pro', description: 'V4 flagship, best quality', contextWindow: '1M', recommended: false),
      ModelDetail(name: 'deepseek-v4-flash', description: 'V4 fast & affordable', contextWindow: '1M', recommended: true),
      ModelDetail(name: 'deepseek-chat', description: 'V3 (deprecated 2026-07)', contextWindow: '64K', recommended: false),
      ModelDetail(name: 'deepseek-reasoner', description: 'Deep thinking (deprecated 2026-07)', contextWindow: '64K', recommended: false),
    ],
    pricingNote: 'Chat: \$0.07-\$1.40/M tokens | Very affordable',
  );

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
    ],
    supportsTranscription: true,
    supportsRealtimeTranscription: true,
    supportsOfflineTranscription: true,
    supportsSpeakerDiarization: false,
    supportsChat: true,
    supportsTextAnalysis: true,
    supportsOCR: true,
    visionModel: 'qwen3.6-vl-plus',
    apiKeyPrefix: 'sk-',
    requiresAppId: true,
    appIdDescription: '通义听悟 AppID（可选，用于实时转写。在阿里云听悟控制台获取）',
    description: '阿里云通义千问系列。中文理解能力强，支持语音转写和实时语音转写。语音转写用 qwen-asr-flash，实时转写用 WebSocket 流式接口。不支持声纹识别（说话人分离）。',
    transcriptionMethod: TranscriptionMethod.nativeAsr,
    realtimeTranscriptionMethod: TranscriptionMethod.realtimeWebSocket,
    transcriptionLimit: TranscriptionLimit(
      maxDurationSeconds: 43200,
      maxFileSizeMB: 500,
      durationLabel: '12 hours',
      note: 'Short audio (<5min, <10MB): qwen3-asr-flash sync. Long audio: qwen3-asr-flash-filetrans async. Realtime: qwen3-asr-flash via WebSocket.',
    ),
    asrModel: 'qwen3-asr-flash',
    asrDescription: 'qwen3-asr-flash: 52 languages + 22 Chinese dialects. Best open-source ASR accuracy.\nqwen3-asr-flash-filetrans: For long audio up to 12 hours, async processing.',
    realtimeAsrModel: 'qwen3-asr-flash',
    realtimeAsrDescription: 'Realtime ASR via DashScope WebSocket. Supports streaming audio input with incremental text output. Low latency for live transcription.',
    modelDetails: [
      ModelDetail(name: 'qwen3.6-max', description: 'Most capable', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'qwen3.6-plus', description: 'Balanced quality & cost', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'qwen3.6-flash', description: 'Fastest, most affordable', contextWindow: '128K', recommended: true),
      ModelDetail(name: 'qwen3.5-plus', description: 'Previous gen, stable', contextWindow: '128K', recommended: false),
    ],
    pricingNote: 'Chat: ¥0.001-¥2/M tokens | ASR: ¥0.001-¥0.01/min | Realtime: ¥0.003/min',
  );

  static const ernie = AiModelConfig(
    provider: AiProvider.ernie,
    name: 'ernie',
    displayName: 'Ernie',
    baseUrl: 'https://qianfan.baidubce.com/v2',
    defaultModel: 'ernie-4.5-8k',
    availableModels: [
      'ernie-4.5-8k',
      'ernie-4.5-32k',
      'ernie-4.5-128k',
      'ernie-speed',
      'ernie-lite',
    ],
    supportsTranscription: false,
    supportsChat: true,
    apiKeyPrefix: null,
    description: 'Baidu Ernie 4.5 series. Optimized for Chinese scenarios.',
    limitationNote: 'ASR requires separate Baidu OAuth credentials (not compatible with current setup). Chat/summary only.',
    modelDetails: [
      ModelDetail(name: 'ernie-4.5-128k', description: 'Long context', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'ernie-4.5-32k', description: 'Medium context', contextWindow: '32K', recommended: false),
      ModelDetail(name: 'ernie-4.5-8k', description: 'Standard, affordable', contextWindow: '8K', recommended: true),
      ModelDetail(name: 'ernie-speed', description: 'Fast inference', contextWindow: '8K', recommended: false),
      ModelDetail(name: 'ernie-lite', description: 'Lightweight', contextWindow: '8K', recommended: false),
    ],
    pricingNote: 'Chat: ¥0.001-¥0.12/M tokens',
  );

  static const zhipu = AiModelConfig(
    provider: AiProvider.zhipu,
    name: 'zhipu',
    displayName: 'Zhipu GLM',
    baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
    defaultModel: 'glm-5.1-flash',
    availableModels: [
      'glm-5.1',
      'glm-5.1-flash',
      'glm-4.7',
      'glm-4.7-flash',
      'glm-4-air',
    ],
    supportsTranscription: false,
    supportsChat: true,
    apiKeyPrefix: null,
    description: 'Zhipu AI GLM 5.1 series. Open-source friendly, strong academic performance.',
    limitationNote: 'ASR requires separate integration. Chat/summary only.',
    modelDetails: [
      ModelDetail(name: 'glm-5.1', description: 'Flagship', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'glm-5.1-flash', description: 'Fast & affordable', contextWindow: '128K', recommended: true),
      ModelDetail(name: 'glm-4.7', description: 'Stable generation', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'glm-4.7-flash', description: 'Fast generation', contextWindow: '128K', recommended: false),
    ],
    pricingNote: 'Chat: ¥0.001-¥0.1/M tokens',
  );

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
    description: 'Moonshot Kimi K2.6: 1T MoE, 256K context. Outstanding agent and coding capabilities.',
    limitationNote: 'No ASR support. Use for chat/summary only.',
    modelDetails: [
      ModelDetail(name: 'kimi-k2.6', description: 'Latest, 1T MoE, best quality', contextWindow: '256K', recommended: true),
      ModelDetail(name: 'kimi-k2.5', description: 'Previous version', contextWindow: '256K', recommended: false),
      ModelDetail(name: 'kimi-k2', description: 'Base K2 model', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'moonshot-v1-128k', description: 'Long context legacy', contextWindow: '128K', recommended: false),
    ],
    pricingNote: 'Chat: ¥0.012-¥24/M tokens',
  );

  static const spark = AiModelConfig(
    provider: AiProvider.spark,
    name: 'spark',
    displayName: 'Spark',
    baseUrl: 'https://spark-api-open.xf-yun.com/v1',
    defaultModel: 'x2-flash',
    availableModels: [
      'x2',
      'x2-flash',
      'generalv3.5',
      'pro-128k',
      'lite',
    ],
    supportsTranscription: false,
    supportsRealtimeTranscription: true,
    supportsSpeakerDiarization: false,
    supportsChat: true,
    supportsTextAnalysis: true,
    apiKeyPrefix: null,
    description: 'iFlytek Spark X2: 293B MoE. Leading voice technology company in China. Supports realtime ASR via iFlytek WebSocket API.',
    transcriptionMethod: TranscriptionMethod.nativeAsr,
    realtimeTranscriptionMethod: TranscriptionMethod.realtimeWebSocket,
    transcriptionLimit: TranscriptionLimit(
      maxDurationSeconds: 14400,
      maxFileSizeMB: 200,
      durationLabel: '4 hours',
      note: 'Realtime ASR via iFlytek WebSocket. Best Chinese ASR accuracy.',
    ),
    asrModel: '',
    asrDescription: 'iFlytek Spark does not support file-based ASR through this endpoint. Use realtime ASR instead.',
    realtimeAsrModel: 'iFlytek-realtime-asr',
    realtimeAsrDescription: 'iFlytek Realtime ASR via WebSocket. Industry-leading Chinese speech recognition. Supports Mandarin, dialects, and mixed-language. Low latency with incremental results.',
    limitationNote: 'File-based ASR requires separate iFlytek credentials. Realtime ASR available via WebSocket.',
    requiresAppId: true,
    appIdDescription: '讯飞开放平台 AppID（在讯飞开放平台控制台获取）',
    modelDetails: [
      ModelDetail(name: 'x2', description: 'Flagship, 293B MoE', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'x2-flash', description: 'Fast & affordable', contextWindow: '128K', recommended: true),
      ModelDetail(name: 'generalv3.5', description: 'V3.5 stable', contextWindow: '8K', recommended: false),
      ModelDetail(name: 'pro-128k', description: 'Long context', contextWindow: '128K', recommended: false),
    ],
    pricingNote: 'Chat: ¥0.001-¥0.12/M tokens | Realtime ASR: ¥0.004/min',
  );

  // TODO: Speaker Diarization API - 声纹识别（说话人分离）
  // 当前没有内置提供商支持声纹识别。
  // 如需接入，请申请以下服务之一：
  //
  // ============================================================
  // 推荐方案 1: 阿里云通义听悟（Tingwu）- 说话人分离
  // ============================================================
  // 通义听悟支持在语音转写中开启"说话人分离"功能，
  // 能够区分对话中的不同发言人。
  //
  // 申请地址: https://tingwu.aliyun.com/
  // API 文档: https://tingwu.aliyun.com/helpcenter/api
  // 说话人分离参数:
  //   - Transcription.DiarizationEnabled = true
  //   - Transcription.Diarization.SpeakerCount = 0(不定人数) 或 2(2人)
  //
  // 计费: 语音转写按音频时长计费，说话人分离不额外收费
  // 限制: 需提交音频文件 URL，不支持本地文件
  //
  // ============================================================
  // 方案 2: 讯飞开放平台 - 声纹识别
  // ============================================================
  // 讯飞声纹识别是身份核验技术（1:1 或 1:N 比对），
  // 不是说话人分离，但可用于说话人辨认场景。
  //
  // 申请地址: https://www.xfyun.cn/
  // 文档: https://www.xfyun.cn/doc/voiceservice/isv/API.html
  // 流程: 创建声纹库 → 添加音频特征 → 特征比对
  //
  // 计费: 按调用次数计费
  // 限制: 需要先注册声纹，不适合会议纪要场景
  //
  // ============================================================
  // 方案 3: 百度智能云 - 音频文件转写
  // ============================================================
  // 百度语音识别支持音频文件转写，但说话人分离能力较弱。
  //
  // 申请地址: https://console.bce.baidu.com/
  // 文档: https://ai.baidu.com/ai-doc/SPEECH/
  //
  // 计费: 按调用次数计费，有免费额度
  // 限制: 说话人分离不是主要能力
  //
  // ============================================================
  // 推荐选择
  // ============================================================
  // 会议纪要场景推荐: 阿里云通义听悟
  // 原因:
  //   1. 原生支持说话人分离（Diarization）
  //   2. 与现有阿里云账号体系兼容
  //   3. 支持离线文件转写，适合录音后处理
  //   4. 同时提供摘要、待办提取等会议纪要功能
  //
  // 接入步骤:
  // 1. 在通义听悟官网申请账号和 API Key
  // 2. 在 AiProvider 枚举中添加 tingwu 提供商
  // 3. 在 allProviders 列表中添加配置
  // 4. 设置 supportsSpeakerDiarization = true
  // 5. 实现 TingwuTranscriptionService（参考通义听悟 API 文档）

  static const tingwu = AiModelConfig(
    provider: AiProvider.tingwu,
    name: 'tingwu',
    displayName: '通义听悟',
    baseUrl: 'https://tingwu.cn-beijing.aliyuncs.com',
    defaultModel: 'tingwu-v2',
    availableModels: ['tingwu-v2'],
    supportsTranscription: true,
    supportsRealtimeTranscription: true,
    supportsOfflineTranscription: true,
    supportsSpeakerDiarization: true,
    supportsChat: false,
    supportsTextAnalysis: false,
    supportsOCR: false,
    visionModel: '',
    apiKeyPrefix: null,
    description: '阿里云通义听悟 - 音视频内容工作学习AI助手。支持语音转写、说话人分离、全文摘要、章节速览、发言总结、待办提取、关键词提取、翻译等一站式会议纪要功能。',
    transcriptionMethod: TranscriptionMethod.asyncAsr,
    realtimeTranscriptionMethod: TranscriptionMethod.realtimeWebSocket,
    transcriptionLimit: TranscriptionLimit(
      maxDurationSeconds: 21600,
      maxFileSizeMB: 6144,
      durationLabel: '6 hours',
      note: '需提交音频文件URL。支持mp3/wav/m4a等格式。说话人分离、摘要、待办等能力需额外开启。',
    ),
    asrModel: 'tingwu-asr',
    asrDescription: '通义听悟语音转写，支持中文、英文、粤语、中英混、日语。可开启说话人分离（2人或不定人数）。',
    realtimeAsrModel: 'tingwu-realtime',
    realtimeAsrDescription: '通义听悟实时会议记录，支持实时转写和翻译。',
    limitationNote: '文件转写需提交URL，不支持本地文件直接上传。大模型能力（摘要/待办/关键词）按功能叠加计费。',
    requiresAppId: true,
    appIdLabel: 'AppKey',
    appIdDescription: '通义听悟 AppKey（在通义听悟控制台创建项目后获取）',
    appIdHint: '如: UFtTh4CAQxxhNdEC',
    requiresAccessKeySecret: true,
    accessKeySecretLabel: 'AccessKey Secret',
    accessKeySecretDescription: '阿里云 AccessKey Secret（RAM 用户密钥）',
    accessKeySecretHint: '如: your-access-key-secret',
    apiKeyLabel: 'AccessKey ID',
    apiKeyHint: '如: your-access-key-id',
    apiKeyDescription: '阿里云 RAM 用户的 AccessKey ID',
    modelDetails: [
      ModelDetail(name: 'tingwu-v2', description: '通义听悟V2，完整会议纪要能力', contextWindow: 'N/A', recommended: true),
    ],
    pricingNote: '转写: ¥0.6/小时 | 大模型能力: ¥0.064/小时/功能 | 翻译: ¥0.5-4/小时 | 新用户免费试用90天',
  );

  static const custom = AiModelConfig(
    provider: AiProvider.custom,
    name: 'custom',
    displayName: 'Custom API',
    baseUrl: '',
    defaultModel: '',
    availableModels: [],
    supportsTranscription: false,
    supportsRealtimeTranscription: false,
    supportsSpeakerDiarization: false,
    supportsChat: true,
    supportsTextAnalysis: true,
    supportsOCR: false,
    visionModel: '',
    apiKeyPrefix: null,
    description: 'Any OpenAI-compatible API endpoint. Enter your own base URL and model name.',
    limitationNote: 'ASR/OCR support depends on your endpoint. Whisper-compatible endpoints may work for ASR. Vision models for OCR.',
    modelDetails: [],
  );

  static AiModelConfig getConfig(AiProvider provider) {
    return allProviders.firstWhere(
      (config) => config.provider == provider,
      orElse: () => openAI,
    );
  }

  static AiModelConfig? getConfigByName(String name) {
    try {
      return allProviders.firstWhere(
        (config) => config.name == name,
      );
    } catch (e) {
      return null;
    }
  }

  static List<AiModelConfig> get domesticProviders => [
    deepSeek,
    qwen,
    tingwu,
    ernie,
    zhipu,
    kimi,
    spark,
  ];

  static List<AiModelConfig> get internationalProviders => [
    openAI,
    claude,
    gemini,
    grok,
  ];

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
