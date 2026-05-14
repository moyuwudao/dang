import 'package:flutter/material.dart';

class ToolOutputModel {
  final String id;
  final String toolId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final List<int> sourceRecordIds;
  final String? templateId;
  final int usageCount;
  final bool isFavorite;

  const ToolOutputModel({
    required this.id,
    required this.toolId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.sourceRecordIds = const [],
    this.templateId,
    this.usageCount = 0,
    this.isFavorite = false,
  });

  ToolOutputModel copyWith({
    String? id,
    String? toolId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    List<int>? sourceRecordIds,
    String? templateId,
    int? usageCount,
    bool? isFavorite,
  }) {
    return ToolOutputModel(
      id: id ?? this.id,
      toolId: toolId ?? this.toolId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      sourceRecordIds: sourceRecordIds ?? this.sourceRecordIds,
      templateId: templateId ?? this.templateId,
      usageCount: usageCount ?? this.usageCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'toolId': toolId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'sourceRecordIds': sourceRecordIds,
      'templateId': templateId,
      'usageCount': usageCount,
      'isFavorite': isFavorite,
    };
  }

  factory ToolOutputModel.fromJson(Map<String, dynamic> json) {
    return ToolOutputModel(
      id: json['id'] as String,
      toolId: json['toolId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      sourceRecordIds: (json['sourceRecordIds'] as List<dynamic>?)?.cast<int>() ?? [],
      templateId: json['templateId'] as String?,
      usageCount: json['usageCount'] as int? ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}

class ToolOutputQuery {
  final String? toolId;
  final String? searchQuery;
  final List<String>? tags;
  final DateTimeRange? dateRange;

  const ToolOutputQuery({
    this.toolId,
    this.searchQuery,
    this.tags,
    this.dateRange,
  });
}