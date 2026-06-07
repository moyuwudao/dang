/// 套餐可用 API 策略（与云端 api_policies 一致）
class ApiPolicy {
  final String provider;
  final String model;
  final String? modelPattern;
  final double multiplier;
  final bool isAllowed;

  const ApiPolicy({
    required this.provider,
    required this.model,
    this.modelPattern,
    required this.multiplier,
    this.isAllowed = true,
  });

  factory ApiPolicy.fromJson(Map<String, dynamic> json) => ApiPolicy(
        provider: (json['provider'] as String?) ?? '',
        model: (json['model'] as String?) ?? '',
        modelPattern: json['modelPattern'] as String?,
        multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
        isAllowed: json['isAllowed'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'model': model,
        if (modelPattern != null) 'modelPattern': modelPattern,
        'multiplier': multiplier,
        'isAllowed': isAllowed,
      };
}

/// 套餐功能配额（保留向后兼容）
class PlanFeatureQuotaModel {
  final String id;
  final String featureType;
  final int quotaValue;
  final String quotaUnit;
  final double multiplier;

  const PlanFeatureQuotaModel({
    required this.id,
    required this.featureType,
    required this.quotaValue,
    required this.quotaUnit,
    this.multiplier = 1.0,
  });

  factory PlanFeatureQuotaModel.fromJson(Map<String, dynamic> json) {
    return PlanFeatureQuotaModel(
      id: json['id'] as String,
      featureType: json['featureType'] as String,
      quotaValue: json['quotaValue'] as int,
      quotaUnit: json['quotaUnit'] as String,
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'featureType': featureType,
        'quotaValue': quotaValue,
        'quotaUnit': quotaUnit,
        'multiplier': multiplier,
      };
}

/// 套餐模型 - 与云端 plans 表完全一致
/// 数据来源：admin 套餐编辑 → 后端 normalizePlan → APK 解析
class PlanModel {
  final String id;
  final String name;
  final String description;
  final int priceCents;
  final int? tokenQuota;
  final int durationDays;
  final String type; // monthly | recharge
  final bool isActive;
  final bool isRecommended; // 是否推荐（admin 可勾选）
  final List<String> features; // 特性卖点（云端录入，APK 端 Store 卡片展示）
  final List<String> allowedModels; // 允许的模型列表
  final Map<String, String> defaultConfigs; // 功能默认 API：{ textAnalysis: 'qwen3.6-flash', ... }
  final List<ApiPolicy> apiPolicies; // 可用 API 详细策略（含系数）
  final List<PlanFeatureQuotaModel> featureQuotas; // 功能配额（兼容老字段）

  const PlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.durationDays,
    required this.type,
    this.tokenQuota,
    this.isActive = true,
    this.isRecommended = false,
    this.features = const [],
    this.allowedModels = const [],
    this.defaultConfigs = const {},
    this.apiPolicies = const [],
    this.featureQuotas = const [],
  });

  /// 价格（元，保留 2 位小数）
  String get priceYuan => (priceCents / 100).toStringAsFixed(2);

  /// 套餐类型展示文案
  String get typeLabel {
    switch (type) {
      case 'monthly':
        return '订阅套餐';
      case 'recharge':
        return '充值包';
      default:
        return type;
    }
  }

  /// 有效期展示文案（按 type 区分）
  String get durationLabel {
    if (type == 'monthly') {
      return durationDays >= 30
          ? '${(durationDays / 30).toStringAsFixed(durationDays % 30 == 0 ? 0 : 1)} 个月'
          : '$durationDays 天';
    }
    return '$durationDays 天有效';
  }

  /// 是否有 token 配额
  bool get hasTokenQuota => (tokenQuota ?? 0) > 0;

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    // features：可能是 String[]（新数据） 或 String（旧数据用逗号/换行分隔）
    List<String> parseFeatures(dynamic raw) {
      if (raw == null) return const [];
      if (raw is List) {
        return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      }
      if (raw is String) {
        final trimmed = raw.trim();
        if (trimmed.isEmpty) return const [];
        // 优先按 \n 分割，兼容 \\n 转义
        return trimmed
            .split(RegExp(r'\\n|\n'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return const [];
    }

    Map<String, String> parseDefaultConfigs(dynamic raw) {
      if (raw == null) return const {};
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
      return const {};
    }

    List<ApiPolicy> parseApiPolicies(dynamic raw) {
      if (raw == null) return const [];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((m) => ApiPolicy.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
      return const [];
    }

    return PlanModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      priceCents: (json['priceCents'] as num?)?.toInt() ?? 0,
      tokenQuota: (json['tokenQuota'] as num?)?.toInt(),
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 30,
      type: (json['type'] as String?) ?? 'monthly',
      isActive: json['isActive'] as bool? ?? true,
      isRecommended: json['isRecommended'] as bool? ?? false,
      features: parseFeatures(json['features']),
      allowedModels: (json['allowedModels'] as List?)
              ?.map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
      defaultConfigs: parseDefaultConfigs(json['defaultConfigs']),
      apiPolicies: parseApiPolicies(json['apiPolicies']),
      featureQuotas: (json['featureQuotas'] as List<dynamic>?)
              ?.map((e) => PlanFeatureQuotaModel.fromJson(e))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'priceCents': priceCents,
        'tokenQuota': tokenQuota,
        'durationDays': durationDays,
        'type': type,
        'isActive': isActive,
        'isRecommended': isRecommended,
        'features': features,
        'allowedModels': allowedModels,
        'defaultConfigs': defaultConfigs,
        'apiPolicies': apiPolicies.map((p) => p.toJson()).toList(),
        'featureQuotas': featureQuotas.map((q) => q.toJson()).toList(),
      };
}
