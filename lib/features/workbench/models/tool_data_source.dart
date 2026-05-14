import 'package:flutter/material.dart';
import 'data_source_selection.dart';

enum DataSourceType {
  records,
  tags,
  toolOutput,
  textInput,
  dateRange,
}

enum RecordFilterMode {
  byDateRange,
  byTags,
  bySearch,
  byFavorites,
  manualSelect,
}

class ToolDataSource {
  final DataSourceType type;
  final RecordFilterMode? filterMode;
  final DateTimeRange? dateRange;
  final List<String>? selectedTags;
  final List<int>? selectedRecordIds;
  final List<String>? selectedToolOutputIds;
  final String? textInput;
  final bool includeAiAnalysis;
  final List<DataSourceCategory> selectedCategories;

  const ToolDataSource({
    required this.type,
    this.filterMode,
    this.dateRange,
    this.selectedTags,
    this.selectedRecordIds,
    this.selectedToolOutputIds,
    this.textInput,
    this.includeAiAnalysis = true,
    this.selectedCategories = const [],
  });

  ToolDataSource copyWith({
    DataSourceType? type,
    RecordFilterMode? filterMode,
    DateTimeRange? dateRange,
    List<String>? selectedTags,
    List<int>? selectedRecordIds,
    List<String>? selectedToolOutputIds,
    String? textInput,
    bool? includeAiAnalysis,
    List<DataSourceCategory>? selectedCategories,
  }) {
    return ToolDataSource(
      type: type ?? this.type,
      filterMode: filterMode ?? this.filterMode,
      dateRange: dateRange ?? this.dateRange,
      selectedTags: selectedTags ?? this.selectedTags,
      selectedRecordIds: selectedRecordIds ?? this.selectedRecordIds,
      selectedToolOutputIds:
          selectedToolOutputIds ?? this.selectedToolOutputIds,
      textInput: textInput ?? this.textInput,
      includeAiAnalysis: includeAiAnalysis ?? this.includeAiAnalysis,
      selectedCategories: selectedCategories ?? this.selectedCategories,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'filterMode': filterMode?.name,
        'dateRange': dateRange != null
            ? {
                'start': dateRange!.start.toIso8601String(),
                'end': dateRange!.end.toIso8601String(),
              }
            : null,
        'selectedTags': selectedTags,
        'selectedRecordIds': selectedRecordIds,
        'selectedToolOutputIds': selectedToolOutputIds,
        'textInput': textInput,
        'includeAiAnalysis': includeAiAnalysis,
        'selectedCategories': selectedCategories.map((c) => c.name).toList(),
      };

  factory ToolDataSource.fromJson(Map<String, dynamic> json) => ToolDataSource(
        type: DataSourceType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => DataSourceType.records,
        ),
        filterMode: json['filterMode'] != null
            ? RecordFilterMode.values.firstWhere(
                (e) => e.name == json['filterMode'],
                orElse: () => RecordFilterMode.byDateRange,
              )
            : null,
        dateRange: json['dateRange'] != null
            ? DateTimeRange(
                start: DateTime.parse(json['dateRange']['start']),
                end: DateTime.parse(json['dateRange']['end']),
              )
            : null,
        selectedTags: (json['selectedTags'] as List<dynamic>?)?.cast<String>(),
        selectedRecordIds:
            (json['selectedRecordIds'] as List<dynamic>?)?.cast<int>(),
        selectedToolOutputIds:
            (json['selectedToolOutputIds'] as List<dynamic>?)?.cast<String>(),
        textInput: json['textInput'] as String?,
        includeAiAnalysis: json['includeAiAnalysis'] as bool? ?? true,
        selectedCategories: (json['selectedCategories'] as List<dynamic>?)
                ?.map((e) => DataSourceCategory.values.firstWhere(
                      (c) => c.name == e,
                      orElse: () => DataSourceCategory.records,
                    ))
                .toList() ??
            [],
      );

  factory ToolDataSource.fromSelection(DataSourceSelection selection) {
    return ToolDataSource(
      type: selection.selectedCategories.isNotEmpty
          ? _mapCategoryToType(selection.selectedCategories.first)
          : DataSourceType.records,
      dateRange: selection.dateRange,
      selectedTags: selection.selectedTags,
      selectedToolOutputIds: selection.selectedToolOutputIds,
      includeAiAnalysis: selection.includeAiAnalysis,
      selectedCategories: selection.selectedCategories,
    );
  }

  DataSourceSelection toSelection() {
    return DataSourceSelection(
      selectedCategories: selectedCategories,
      selectedTags: selectedTags ?? [],
      selectedToolOutputIds: selectedToolOutputIds ?? [],
      dateRange: dateRange,
      includeAiAnalysis: includeAiAnalysis,
    );
  }

  static DataSourceType _mapCategoryToType(DataSourceCategory category) {
    switch (category) {
      case DataSourceCategory.records:
        return DataSourceType.records;
      case DataSourceCategory.tags:
        return DataSourceType.tags;
      case DataSourceCategory.toolOutput:
        return DataSourceType.toolOutput;
    }
  }
}
