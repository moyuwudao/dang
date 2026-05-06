enum AiProvider {
  openAI,
  claude,
  gemini,
  deepSeek,
  qwen,
  ernie,
  zhipu,
  kimi,
  spark,
  grok,
  custom,
}

enum AppFeature {
  recording,
  transcription,
  chatSummary,
  titleGeneration,
  ocr,
}

enum TranscriptionMethod {
  whisperApi,
  audioUpload,
  nativeAsr,
  asyncAsr,
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
  final bool supportsChat;
  final String? apiKeyPrefix;
  final String description;
  final TranscriptionMethod transcriptionMethod;
  final TranscriptionLimit? transcriptionLimit;
  final List<ModelDetail> modelDetails;
  final String asrModel;
  final String asrDescription;
  final String limitationNote;
  final String pricingNote;

  const AiModelConfig({
    required this.provider,
    required this.name,
    required this.displayName,
    required this.baseUrl,
    required this.defaultModel,
    required this.availableModels,
    this.supportsTranscription = false,
    this.supportsChat = true,
    this.apiKeyPrefix,
    required this.description,
    this.transcriptionMethod = TranscriptionMethod.whisperApi,
    this.transcriptionLimit,
    this.modelDetails = const [],
    this.asrModel = '',
    this.asrDescription = '',
    this.limitationNote = '',
    this.pricingNote = '',
  });

  static const List<AiModelConfig> allProviders = [
    openAI,
    deepSeek,
    claude,
    gemini,
    qwen,
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
      case AppFeature.ocr:
        return true;
      case AppFeature.transcription:
        if (configuredProvider == null) return false;
        final config = getConfig(configuredProvider);
        return config.supportsTranscription;
      case AppFeature.chatSummary:
      case AppFeature.titleGeneration:
        return configuredProvider != null;
    }
  }

  static String? getFeatureDisabledReason(AppFeature feature, AiProvider? configuredProvider) {
    switch (feature) {
      case AppFeature.recording:
      case AppFeature.ocr:
        return null;
      case AppFeature.transcription:
        if (configuredProvider == null) {
          return 'Please configure an AI model API Key first';
        }
        final config = getConfig(configuredProvider);
        if (!config.supportsTranscription) {
          return '${config.displayName} does not support transcription. Please use OpenAI, Gemini, or Qwen.';
        }
        return null;
      case AppFeature.chatSummary:
      case AppFeature.titleGeneration:
        if (configuredProvider == null) {
          return 'Please configure an AI model API Key first';
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
    supportsChat: true,
    apiKeyPrefix: 'sk-',
    description: 'Industry-leading AI with best-in-class Whisper transcription. Most reliable for voice-to-text.',
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
    supportsChat: true,
    apiKeyPrefix: null,
    description: 'Google\'s Gemini with generous free tier. Supports audio upload for transcription via multimodal input.',
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
    displayName: 'Qwen',
    baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    defaultModel: 'qwen3.6-flash',
    availableModels: [
      'qwen3.6-max',
      'qwen3.6-plus',
      'qwen3.6-flash',
      'qwen3.5-plus',
      'qwen-max',
      'qwen-plus',
    ],
    supportsTranscription: true,
    supportsChat: true,
    apiKeyPrefix: 'sk-',
    description: 'Alibaba Qwen 3.6 series. Strong Chinese understanding. Auto-selects qwen3-asr-flash for transcription, supports long audio via async API.',
    transcriptionMethod: TranscriptionMethod.nativeAsr,
    transcriptionLimit: TranscriptionLimit(
      maxDurationSeconds: 43200,
      maxFileSizeMB: 500,
      durationLabel: '12 hours',
      note: 'Short audio (<5min, <10MB): qwen3-asr-flash sync. Long audio: qwen3-asr-flash-filetrans async.',
    ),
    asrModel: 'qwen3-asr-flash',
    asrDescription: 'qwen3-asr-flash: 52 languages + 22 Chinese dialects. Best open-source ASR accuracy.\nqwen3-asr-flash-filetrans: For long audio up to 12 hours, async processing.',
    modelDetails: [
      ModelDetail(name: 'qwen3.6-max', description: 'Most capable', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'qwen3.6-plus', description: 'Balanced quality & cost', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'qwen3.6-flash', description: 'Fastest, most affordable', contextWindow: '128K', recommended: true),
      ModelDetail(name: 'qwen3.5-plus', description: 'Previous gen, stable', contextWindow: '128K', recommended: false),
    ],
    pricingNote: 'Chat: ¥0.001-¥2/M tokens | ASR: ¥0.001-¥0.01/min',
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
    supportsChat: true,
    apiKeyPrefix: null,
    description: 'iFlytek Spark X2: 293B MoE. Leading voice technology company in China.',
    limitationNote: 'ASR requires separate iFlytek credentials (AppID+APIKey+APISecret). Chat/summary only.',
    modelDetails: [
      ModelDetail(name: 'x2', description: 'Flagship, 293B MoE', contextWindow: '128K', recommended: false),
      ModelDetail(name: 'x2-flash', description: 'Fast & affordable', contextWindow: '128K', recommended: true),
      ModelDetail(name: 'generalv3.5', description: 'V3.5 stable', contextWindow: '8K', recommended: false),
      ModelDetail(name: 'pro-128k', description: 'Long context', contextWindow: '128K', recommended: false),
    ],
    pricingNote: 'Chat: ¥0.001-¥0.12/M tokens',
  );

  static const custom = AiModelConfig(
    provider: AiProvider.custom,
    name: 'custom',
    displayName: 'Custom API',
    baseUrl: '',
    defaultModel: '',
    availableModels: [],
    supportsTranscription: false,
    supportsChat: true,
    apiKeyPrefix: null,
    description: 'Any OpenAI-compatible API endpoint. Enter your own base URL and model name.',
    limitationNote: 'ASR support depends on your endpoint. Whisper-compatible endpoints may work.',
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
      .where((p) => p.supportsTranscription)
      .toList();
}
