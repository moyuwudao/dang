class AnalysisTemplate {
  final String id;
  final String name;
  final String description;
  final String prompt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AnalysisTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.prompt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AnalysisTemplate.fromJson(Map<String, dynamic> json) {
    return AnalysisTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      prompt: json['prompt'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'prompt': prompt,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
