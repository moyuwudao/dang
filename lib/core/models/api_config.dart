import 'ai_model_config.dart';

class ApiConfigEntry {
  final String id;
  final String name;
  final AiProvider provider;
  final String apiKey;
  final String? appId;
  final String? baseUrl;
  final String model;
  final bool isCustomProvider;
  final String? customProviderName;
  final List<ApiFunctionType> functions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? accessKeySecret;
  final bool isCloudConfig; // 标记是否为云端分配的配置
  final double cloudMultiplier; // 云端配置的消耗系数（1.0=标准，2.0=双倍消耗）

  const ApiConfigEntry({
    required this.id,
    required this.name,
    required this.provider,
    required this.apiKey,
    this.appId,
    this.baseUrl,
    required this.model,
    this.isCustomProvider = false,
    this.customProviderName,
    this.functions = const [ApiFunctionType.text],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.accessKeySecret,
    this.isCloudConfig = false,
    this.cloudMultiplier = 1.0,
  });

  ApiConfigEntry copyWith({
    String? id,
    String? name,
    AiProvider? provider,
    String? apiKey,
    String? appId,
    String? baseUrl,
    String? model,
    bool? isCustomProvider,
    String? customProviderName,
    List<ApiFunctionType>? functions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? accessKeySecret,
    bool? isCloudConfig,
    double? cloudMultiplier,
  }) {
    return ApiConfigEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      appId: appId ?? this.appId,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      isCustomProvider: isCustomProvider ?? this.isCustomProvider,
      customProviderName: customProviderName ?? this.customProviderName,
      functions: functions ?? this.functions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      accessKeySecret: accessKeySecret ?? this.accessKeySecret,
      isCloudConfig: isCloudConfig ?? this.isCloudConfig,
      cloudMultiplier: cloudMultiplier ?? this.cloudMultiplier,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider.name,
      'apiKey': apiKey,
      'appId': appId,
      'baseUrl': baseUrl,
      'model': model,
      'isCustomProvider': isCustomProvider,
      'customProviderName': customProviderName,
      'functions': functions.map((f) => f.name).toList(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'accessKeySecret': accessKeySecret,
      'isCloudConfig': isCloudConfig,
      'cloudMultiplier': cloudMultiplier,
    };
  }

  factory ApiConfigEntry.fromJson(Map<String, dynamic> json) {
    return ApiConfigEntry(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      provider: AiProvider.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => AiProvider.openAI,
      ),
      apiKey: json['apiKey'] ?? '',
      appId: json['appId'],
      baseUrl: json['baseUrl'],
      model: json['model'] ?? '',
      isCustomProvider: json['isCustomProvider'] ?? false,
      customProviderName: json['customProviderName'],
      functions: (json['functions'] as List<dynamic>?)
              ?.map((f) => ApiFunctionType.values.firstWhere(
                    (ft) => ft.name == f,
                    orElse: () => ApiFunctionType.text,
                  ))
              .toList() ??
          [ApiFunctionType.text],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      accessKeySecret: json['accessKeySecret'],
      isCloudConfig: json['isCloudConfig'] ?? false,
      cloudMultiplier: (json['cloudMultiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }

  String get displayName {
    if (isCustomProvider && customProviderName != null) {
      return '$customProviderName ($name)';
    }
    return '${AiModelConfig.getConfig(provider).displayName} ($name)';
  }

  bool get supportsText => functions.contains(ApiFunctionType.text);
  bool get supportsVoice => functions.contains(ApiFunctionType.voice);
  bool get supportsVoiceRealtime => functions.contains(ApiFunctionType.voiceRealtime);
  bool get supportsImage => functions.contains(ApiFunctionType.image);
  bool get supportsOfflineVoice => functions.contains(ApiFunctionType.offlineVoice);

  /// 检查此配置是否支持指定的功能类型（基于模型固有能力）
  bool isFunctionCompatible(ApiFunctionType functionType) {
    return AiModelConfig.providerSupportsFunction(provider, functionType);
  }

  /// 获取此配置支持的功能类型列表（基于模型固有能力）
  List<ApiFunctionType> get compatibleFunctions {
    return ApiFunctionType.values
        .where((f) => AiModelConfig.providerSupportsFunction(provider, f))
        .toList();
  }

  /// 获取此配置不支持但用户已勾选的功能列表
  List<ApiFunctionType> get incompatibleSelectedFunctions {
    return functions.where((f) => !isFunctionCompatible(f)).toList();
  }

  /// 检查是否有不兼容的功能选择
  bool get hasIncompatibleFunctions => incompatibleSelectedFunctions.isNotEmpty;
}

class ApiFunctionAssignment {
  final ApiFunctionType functionType;
  final String? configId;

  const ApiFunctionAssignment({
    required this.functionType,
    this.configId,
  });

  Map<String, dynamic> toJson() {
    return {
      'functionType': functionType.name,
      'configId': configId,
    };
  }

  factory ApiFunctionAssignment.fromJson(Map<String, dynamic> json) {
    return ApiFunctionAssignment(
      functionType: ApiFunctionType.values.firstWhere(
        (f) => f.name == json['functionType'],
        orElse: () => ApiFunctionType.text,
      ),
      configId: json['configId'],
    );
  }
}

class MultiApiConfig {
  final List<ApiConfigEntry> configs;
  final List<ApiFunctionAssignment> functionAssignments;
  final String? defaultConfigId;

  const MultiApiConfig({
    this.configs = const [],
    this.functionAssignments = const [],
    this.defaultConfigId,
  });

  MultiApiConfig copyWith({
    List<ApiConfigEntry>? configs,
    List<ApiFunctionAssignment>? functionAssignments,
    String? defaultConfigId,
  }) {
    return MultiApiConfig(
      configs: configs ?? this.configs,
      functionAssignments: functionAssignments ?? this.functionAssignments,
      defaultConfigId: defaultConfigId ?? this.defaultConfigId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'configs': configs.map((c) => c.toJson()).toList(),
      'functionAssignments': functionAssignments.map((a) => a.toJson()).toList(),
      'defaultConfigId': defaultConfigId,
    };
  }

  factory MultiApiConfig.fromJson(Map<String, dynamic> json) {
    return MultiApiConfig(
      configs: (json['configs'] as List<dynamic>?)
              ?.map((c) => ApiConfigEntry.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      functionAssignments: (json['functionAssignments'] as List<dynamic>?)
              ?.map((a) => ApiFunctionAssignment.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      defaultConfigId: json['defaultConfigId'],
    );
  }

  ApiConfigEntry? getConfigForFunction(ApiFunctionType function) {
    final assignment = functionAssignments.firstWhere(
      (a) => a.functionType == function,
      orElse: () => const ApiFunctionAssignment(
        functionType: ApiFunctionType.text,
        configId: null,
      ),
    );
    if (assignment.configId == null) return null;
    return configs.firstWhere(
      (c) => c.id == assignment.configId && c.isActive,
      orElse: () => configs.firstWhere(
        (c) => c.isActive,
        orElse: () => throw Exception('No active config found'),
      ),
    );
  }

  ApiConfigEntry? getConfigById(String id) {
    try {
      return configs.firstWhere(
        (c) => c.id == id,
      );
    } catch (_) {
      return null;
    }
  }

  List<ApiConfigEntry> get activeConfigs =>
      configs.where((c) => c.isActive).toList();

  /// 仅本地配置（用于备份，排除云端配置）
  List<ApiConfigEntry> get localConfigs =>
      configs.where((c) => !c.isCloudConfig).toList();

  /// 仅云端配置
  List<ApiConfigEntry> get cloudConfigs =>
      configs.where((c) => c.isCloudConfig).toList();

  bool get hasAnyConfig => configs.any((c) => c.isActive);

  bool get hasCloudConfig => configs.any((c) => c.isCloudConfig && c.isActive);
}
