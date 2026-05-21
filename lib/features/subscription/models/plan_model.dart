class PlanModel {
  final String id;
  final String name;
  final String description;
  final int priceCents;
  final int durationDays;
  final List<String> features;
  final bool isRecommended;
  final String type;

  const PlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.durationDays,
    required this.features,
    this.isRecommended = false,
    required this.type,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      priceCents: json['priceCents'] as int,
      durationDays: json['durationDays'] as int,
      features: (json['features'] as List<dynamic>).cast<String>(),
      isRecommended: json['isRecommended'] as bool? ?? false,
      type: json['type'] as String,
    );
  }
}
