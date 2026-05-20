
import 'package:flutter/material.dart';

enum DataSourceCategory {
  records,
  tags,
  toolOutput,
}

extension DataSourceCategoryExtension on DataSourceCategory {
  String get label {
    switch (this) {
      case DataSourceCategory.records:
        return '原始记录';
      case DataSourceCategory.tags:
        return '标签';
      case DataSourceCategory.toolOutput:
        return '工具输出';
    }
  }

  IconData get icon {
    switch (this) {
      case DataSourceCategory.records:
        return Icons.description_outlined;
      case DataSourceCategory.tags:
        return Icons.label_outlined;
      case DataSourceCategory.toolOutput:
        return Icons.output_outlined;
    }
  }
}

class DataSourceSelection {
  final List<DataSourceCategory> selectedCategories;
  final List<String> selectedTags;
  final List<int> selectedToolOutputIds;
  final DateTimeRange? dateRange;
  final bool includeAiAnalysis;

  const DataSourceSelection({
    this.selectedCategories = const [],
    this.selectedTags = const [],
    this.selectedToolOutputIds = const [],
    this.dateRange,
    this.includeAiAnalysis = true,
  });

  DataSourceSelection copyWith({
    List<DataSourceCategory>? selectedCategories,
    List<String>? selectedTags,
    List<int>? selectedToolOutputIds,
    DateTimeRange? dateRange,
    bool? includeAiAnalysis,
  }) {
    return DataSourceSelection(
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedTags: selectedTags ?? this.selectedTags,
      selectedToolOutputIds: selectedToolOutputIds ?? this.selectedToolOutputIds,
      dateRange: dateRange ?? this.dateRange,
      includeAiAnalysis: includeAiAnalysis ?? this.includeAiAnalysis,
    );
  }

  bool get isEmpty => selectedCategories.isEmpty;

  int get totalSelectedCount {
    return selectedTags.length + selectedToolOutputIds.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedCategories': selectedCategories.map((c) => c.name).toList(),
      'selectedTags': selectedTags,
      'selectedToolOutputIds': selectedToolOutputIds,
      'dateRange': dateRange != null
          ? {
              'start': dateRange!.start.toIso8601String(),
              'end': dateRange!.end.toIso8601String(),
            }
          : null,
      'includeAiAnalysis': includeAiAnalysis,
    };
  }

  factory DataSourceSelection.fromJson(Map<String, dynamic> json) {
    return DataSourceSelection(
      selectedCategories: (json['selectedCategories'] as List<dynamic>?)
              ?.map((e) => DataSourceCategory.values.firstWhere(
                    (c) => c.name == e,
                    orElse: () => DataSourceCategory.records,
                  ))
              .toList() ??
          [],
      selectedTags: (json['selectedTags'] as List<dynamic>?)?.cast<String>() ?? [],
      selectedToolOutputIds:
          (json['selectedToolOutputIds'] as List<dynamic>?)?.cast<int>() ?? [],
      dateRange: json['dateRange'] != null
          ? DateTimeRange(
              start: DateTime.parse(json['dateRange']['start']),
              end: DateTime.parse(json['dateRange']['end']),
            )
          : null,
      includeAiAnalysis: json['includeAiAnalysis'] as bool? ?? true,
    );
  }
}