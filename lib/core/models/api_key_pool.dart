import 'package:flutter/material.dart';
import 'ai_model_config.dart';

/// ============================================================================
/// API Key 池化数据模型（A1 阶段新增，与 ApiConfigEntry 并存）
/// ============================================================================

/// API Key 健康状态（与后端 status 字段对应）
enum ApiKeyStatus {
  /// 正常可用
  active,

  /// 主动禁用（用户手动停用）
  disabled,

  /// 暂时不可用（如限流、最近多次错误）
  throttled,

  /// 永久不可用（如被禁用、过期）
  banned,
}

/// 单个 API Key 在池中的条目（A1 阶段新增）
class ApiKeyEntry {
  /// 唯一 ID
  final String id;

  /// 显示名（如 "Key 1"、"备份 Key"、"主 Key"）
  final String name;

  /// API Key 值
  final String apiKey;

  /// 通义听悟专用
  final String? appId;
  final String? accessKeySecret;

  /// 自定义 baseUrl（覆盖 provider 默认）
  final String? baseUrl;

  /// 自定义 model（覆盖 provider 默认）
  final String? model;

  /// 健康状态
  final ApiKeyStatus status;

  /// 路由权重（值越大，被选中概率越高，默认 100）
  final int weight;

  /// 优先级（0=最高，用于固定优先级模式）
  final int priority;

  /// 今日已用 Token 数
  final int dailyUsage;

  /// 每日 Token 配额（0=无限制）
  final int dailyQuota;

  /// 每分钟速率限制（0=无限制）
  final int rateLimitPerMin;

  /// 最大并发请求数（0=无限制）
  final int maxConcurrentRequests;

  /// 当前正在进行的请求数
  final int currentConcurrent;

  /// 累计成功次数
  final int successCount;

  /// 累计错误次数
  final int errorCount;

  /// 最后一次错误信息
  final String? lastError;

  /// 最后一次使用时间
  final DateTime? lastUsedAt;

  /// 是否启用
  final bool isActive;

  /// 创建时间
  final DateTime createdAt;
  final DateTime updatedAt;

  const ApiKeyEntry({
    required this.id,
    required this.name,
    required this.apiKey,
    this.appId,
    this.accessKeySecret,
    this.baseUrl,
    this.model,
    this.status = ApiKeyStatus.active,
    this.weight = 100,
    this.priority = 0,
    this.dailyUsage = 0,
    this.dailyQuota = 0,
    this.rateLimitPerMin = 0,
    this.maxConcurrentRequests = 0,
    this.currentConcurrent = 0,
    this.successCount = 0,
    this.errorCount = 0,
    this.lastError,
    this.lastUsedAt,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  ApiKeyEntry copyWith({
    String? id,
    String? name,
    String? apiKey,
    String? appId,
    String? accessKeySecret,
    String? baseUrl,
    String? model,
    ApiKeyStatus? status,
    int? weight,
    int? priority,
    int? dailyUsage,
    int? dailyQuota,
    int? rateLimitPerMin,
    int? maxConcurrentRequests,
    int? currentConcurrent,
    int? successCount,
    int? errorCount,
    String? lastError,
    DateTime? lastUsedAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApiKeyEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      apiKey: apiKey ?? this.apiKey,
      appId: appId ?? this.appId,
      accessKeySecret: accessKeySecret ?? this.accessKeySecret,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      status: status ?? this.status,
      weight: weight ?? this.weight,
      priority: priority ?? this.priority,
      dailyUsage: dailyUsage ?? this.dailyUsage,
      dailyQuota: dailyQuota ?? this.dailyQuota,
      rateLimitPerMin: rateLimitPerMin ?? this.rateLimitPerMin,
      maxConcurrentRequests: maxConcurrentRequests ?? this.maxConcurrentRequests,
      currentConcurrent: currentConcurrent ?? this.currentConcurrent,
      successCount: successCount ?? this.successCount,
      errorCount: errorCount ?? this.errorCount,
      lastError: lastError ?? this.lastError,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'apiKey': apiKey,
      'appId': appId,
      'accessKeySecret': accessKeySecret,
      'baseUrl': baseUrl,
      'model': model,
      'status': status.name,
      'weight': weight,
      'priority': priority,
      'dailyUsage': dailyUsage,
      'dailyQuota': dailyQuota,
      'rateLimitPerMin': rateLimitPerMin,
      'maxConcurrentRequests': maxConcurrentRequests,
      'currentConcurrent': currentConcurrent,
      'successCount': successCount,
      'errorCount': errorCount,
      'lastError': lastError,
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ApiKeyEntry.fromJson(Map<String, dynamic> json) {
    return ApiKeyEntry(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      apiKey: json['apiKey'] ?? '',
      appId: json['appId'],
      accessKeySecret: json['accessKeySecret'],
      baseUrl: json['baseUrl'],
      model: json['model'],
      status: ApiKeyStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ApiKeyStatus.active,
      ),
      weight: (json['weight'] as num?)?.toInt() ?? 100,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      dailyUsage: (json['dailyUsage'] as num?)?.toInt() ?? 0,
      dailyQuota: (json['dailyQuota'] as num?)?.toInt() ?? 0,
      rateLimitPerMin: (json['rateLimitPerMin'] as num?)?.toInt() ?? 0,
      maxConcurrentRequests: (json['maxConcurrentRequests'] as num?)?.toInt() ?? 0,
      currentConcurrent: (json['currentConcurrent'] as num?)?.toInt() ?? 0,
      successCount: (json['successCount'] as num?)?.toInt() ?? 0,
      errorCount: (json['errorCount'] as num?)?.toInt() ?? 0,
      lastError: json['lastError'],
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.tryParse(json['lastUsedAt'])
          : null,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// 是否可用于调用（active + isActive + 未超限）
  bool get isAvailable {
    if (!isActive || status != ApiKeyStatus.active) return false;
    if (dailyQuota > 0 && dailyUsage >= dailyQuota) return false;
    if (maxConcurrentRequests > 0 &&
        currentConcurrent >= maxConcurrentRequests) {
      return false;
    }
    return true;
  }

  /// 用量百分比（0.0-1.0）
  double get usageRatio {
    if (dailyQuota <= 0) return 0.0;
    return (dailyUsage / dailyQuota).clamp(0.0, 1.0);
  }

  /// 健康评分（0-100，用于 selectOptimalKey 排序）
  double get healthScore {
    if (!isActive) return 0.0;
    if (status == ApiKeyStatus.banned) return 0.0;
    if (status == ApiKeyStatus.throttled) return 30.0;

    final total = successCount + errorCount;
    if (total == 0) return 100.0; // 全新 key 给满分

    final successRate = successCount / total;
    final score = successRate * 100.0;

    // 用量接近上限时降分
    if (usageRatio > 0.8) {
      return score * 0.5;
    }
    return score;
  }

  /// 简略显示 Key（仅显示前 8 位 + ...）
  String get maskedKey {
    if (apiKey.length <= 8) return apiKey;
    return '${apiKey.substring(0, 8)}...';
  }

  /// 健康状态显示文案
  String get statusLabel {
    switch (status) {
      case ApiKeyStatus.active:
        return '正常';
      case ApiKeyStatus.disabled:
        return '已停用';
      case ApiKeyStatus.throttled:
        return '限流中';
      case ApiKeyStatus.banned:
        return '已禁用';
    }
  }

  /// 健康状态颜色
  Color get statusColor {
    switch (status) {
      case ApiKeyStatus.active:
        return Colors.green;
      case ApiKeyStatus.disabled:
        return Colors.grey;
      case ApiKeyStatus.throttled:
        return Colors.orange;
      case ApiKeyStatus.banned:
        return Colors.red;
    }
  }
}

/// 一个 Provider 的 Key 池
class ApiKeyPool {
  /// 池唯一 ID（与 provider 绑定：provider_${provider.name}）
  final String id;

  /// Provider
  final AiProvider provider;

  /// 是否自定义 Provider
  final bool isCustomProvider;
  final String? customProviderName;

  /// 默认 model
  final String model;

  /// 池中所有 Key
  final List<ApiKeyEntry> keys;

  /// 池支持的功能列表
  final List<ApiFunctionType> functions;

  /// 池显示名
  final String? name;

  /// 是否是云端配置（云端分配的 Key 池）
  final bool isCloudConfig;

  /// 云端配置消耗系数
  final double cloudMultiplier;

  /// 创建/更新时间
  final DateTime createdAt;
  final DateTime updatedAt;

  const ApiKeyPool({
    required this.id,
    required this.provider,
    required this.model,
    this.isCustomProvider = false,
    this.customProviderName,
    this.keys = const [],
    this.functions = const [ApiFunctionType.text],
    this.name,
    this.isCloudConfig = false,
    this.cloudMultiplier = 1.0,
    required this.createdAt,
    required this.updatedAt,
  });

  ApiKeyPool copyWith({
    String? id,
    AiProvider? provider,
    bool? isCustomProvider,
    String? customProviderName,
    String? model,
    List<ApiKeyEntry>? keys,
    List<ApiFunctionType>? functions,
    String? name,
    bool? isCloudConfig,
    double? cloudMultiplier,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApiKeyPool(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      isCustomProvider: isCustomProvider ?? this.isCustomProvider,
      customProviderName: customProviderName ?? this.customProviderName,
      model: model ?? this.model,
      keys: keys ?? this.keys,
      functions: functions ?? this.functions,
      name: name ?? this.name,
      isCloudConfig: isCloudConfig ?? this.isCloudConfig,
      cloudMultiplier: cloudMultiplier ?? this.cloudMultiplier,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider.name,
      'isCustomProvider': isCustomProvider,
      'customProviderName': customProviderName,
      'model': model,
      'keys': keys.map((k) => k.toJson()).toList(),
      'functions': functions.map((f) => f.name).toList(),
      'name': name,
      'isCloudConfig': isCloudConfig,
      'cloudMultiplier': cloudMultiplier,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ApiKeyPool.fromJson(Map<String, dynamic> json) {
    return ApiKeyPool(
      id: json['id'] ?? '',
      provider: AiProvider.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => AiProvider.openAI,
      ),
      isCustomProvider: json['isCustomProvider'] ?? false,
      customProviderName: json['customProviderName'],
      model: json['model'] ?? '',
      keys: (json['keys'] as List<dynamic>?)
              ?.map((k) => ApiKeyEntry.fromJson(k as Map<String, dynamic>))
              .toList() ??
          [],
      functions: (json['functions'] as List<dynamic>?)
              ?.map((f) => ApiFunctionType.values.firstWhere(
                    (ft) => ft.name == f,
                    orElse: () => ApiFunctionType.text,
                  ))
              .toList() ??
          [ApiFunctionType.text],
      name: json['name'],
      isCloudConfig: json['isCloudConfig'] ?? false,
      cloudMultiplier: (json['cloudMultiplier'] as num?)?.toDouble() ?? 1.0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// 获取池显示名
  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (isCustomProvider && customProviderName != null) {
      return customProviderName!;
    }
    final providerName = AiModelConfig.getConfig(provider).displayName;
    if (keys.length == 1) {
      return '$providerName (${keys.first.name})';
    }
    return '$providerName (${keys.length} Keys)';
  }

  /// 池中所有可用的 Key
  List<ApiKeyEntry> get availableKeys =>
      keys.where((k) => k.isAvailable).toList();

  /// 池是否启用（至少有 1 个可用 Key）
  bool get isEnabled => availableKeys.isNotEmpty;

  /// 池中是否有任何 Key
  bool get hasKeys => keys.isNotEmpty;

  /// 池中是否所有 Key 都被禁用
  bool get allKeysDisabled =>
      keys.isNotEmpty && keys.every((k) => !k.isActive);

  /// 池内 selectOptimalKey（基于健康评分 + 权重）
  ApiKeyEntry? selectOptimalKey({Set<ApiFunctionType>? requiredFunctions}) {
    final candidates = availableKeys.where((k) {
      if (requiredFunctions == null || requiredFunctions.isEmpty) return true;
      // 池的 functions 决定是否支持该功能
      return requiredFunctions
          .every((f) => functions.contains(f));
    }).toList();

    if (candidates.isEmpty) return null;

    // 按健康评分 × 权重 排序，取最高
    candidates.sort((a, b) {
      final scoreA = a.healthScore * a.weight;
      final scoreB = b.healthScore * b.weight;
      return scoreB.compareTo(scoreA);
    });

    return candidates.first;
  }

  /// 池是否支持指定功能
  bool supportsFunction(ApiFunctionType functionType) {
    return functions.contains(functionType);
  }

  /// 池内用量汇总（用于池卡片显示）
  int get totalDailyUsage =>
      keys.fold(0, (sum, k) => sum + k.dailyUsage);

  int get totalDailyQuota =>
      keys.fold(0, (sum, k) => sum + k.dailyQuota);

  double get totalUsageRatio {
    if (totalDailyQuota <= 0) return 0.0;
    return (totalDailyUsage / totalDailyQuota).clamp(0.0, 1.0);
  }

  /// 池整体健康度（0-100）
  double get poolHealth {
    if (keys.isEmpty) return 0.0;
    final activeKeys = keys.where((k) => k.isActive).toList();
    if (activeKeys.isEmpty) return 0.0;
    final totalScore = activeKeys.fold<double>(
        0.0, (sum, k) => sum + k.healthScore);
    return totalScore / activeKeys.length;
  }
}
