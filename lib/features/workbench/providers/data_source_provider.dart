
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/data_source_selection.dart';

final dataSourceSelectionProvider = StateProvider<DataSourceSelection>(
  (ref) => DataSourceSelection(
    selectedCategories: [],
    selectedTags: [],
    selectedToolOutputIds: [],
    dateRange: DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    ),
    includeAiAnalysis: true,
  ),
);

final expandedPanelsProvider = Provider<Map<String, bool>>((ref) {
  final selection = ref.watch(dataSourceSelectionProvider);
  final panels = <String, bool>{};

  for (var category in selection.selectedCategories) {
    panels[category.name] = true;
  }

  return panels;
});

final dataSourceSummaryProvider = Provider<String>((ref) {
  final selection = ref.watch(dataSourceSelectionProvider);
  
  if (selection.isEmpty) {
    return '未选择数据源';
  }

  final parts = <String>[];
  
  if (selection.selectedTags.isNotEmpty) {
    parts.add('${selection.selectedTags.length} 个标签');
  }
  
  if (selection.selectedToolOutputIds.isNotEmpty) {
    parts.add('${selection.selectedToolOutputIds.length} 个工具输出');
  }
  
  if (selection.dateRange != null) {
    parts.add('时间范围');
  }

  return parts.join(' + ');
});