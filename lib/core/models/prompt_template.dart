class PromptTemplate {
  final String id;
  final String name;
  final String content;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PromptTemplate({
    required this.id,
    required this.name,
    required this.content,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PromptTemplate.fromJson(Map<String, dynamic> json) {
    return PromptTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      content: json['content'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
