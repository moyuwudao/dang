import 'dart:convert';

class MindMapPlan {
  final String id;
  final String name;
  final String content;
  final List<String> tags;
  final DateTime createdAt;

  const MindMapPlan({
    required this.id,
    required this.name,
    required this.content,
    this.tags = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'content': content,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MindMapPlan.fromJson(Map<String, dynamic> json) => MindMapPlan(
        id: json['id'] as String,
        name: json['name'] as String,
        content: json['content'] as String,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  MindMapPlan copyWith({
    String? id,
    String? name,
    String? content,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return MindMapPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
