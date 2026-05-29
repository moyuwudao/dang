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
}

class PlanModel {
  final String id;
  final String name;
  final String description;
  final int priceCents;
  final int durationDays;
  final List<String> features;
  final bool isRecommended;
  final String type;
  final List<String> allowedModels;
  final List<PlanFeatureQuotaModel> featureQuotas;

  const PlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.durationDays,
    required this.features,
    this.isRecommended = false,
    required this.type,
    this.allowedModels = const [],
    this.featureQuotas = const [],
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      priceCents: json['priceCents'] as int,
      durationDays: json['durationDays'] as int,
      features: (json['features'] as List<dynamic>?)?.cast<String>() ?? [],
      isRecommended: json['isRecommended'] as bool? ?? false,
      type: json['type'] as String? ?? 'subscription',
      allowedModels: (json['allowedModels'] as List<dynamic>?)?.cast<String>() ?? [],
      featureQuotas: (json['featureQuotas'] as List<dynamic>?)
          ?.map((e) => PlanFeatureQuotaModel.fromJson(e))
          .toList() ?? [],
    );
  }
}
