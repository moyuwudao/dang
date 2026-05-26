
import 'package:flutter/material.dart';
import '../models/data_source_selection.dart';
import 'category_selector.dart';
import 'tag_selector.dart';
import 'tool_output_selector.dart';
import 'record_filter_section.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class DataSourceSelector extends StatefulWidget {
  final DataSourceSelection selection;
  final ValueChanged<DataSourceSelection> onChanged;
  final String? toolId;

  const DataSourceSelector({
    super.key,
    required this.selection,
    required this.onChanged,
    this.toolId,
  });

  @override
  State<DataSourceSelector> createState() => _DataSourceSelectorState();
}

class _DataSourceSelectorState extends State<DataSourceSelector> {
  final Map<String, bool> _expandedPanels = {};

  @override
  void initState() {
    super.initState();
    _initExpandedPanels();
  }

  void _initExpandedPanels() {
    for (var category in widget.selection.selectedCategories) {
      _expandedPanels[category.name] = true;
    }
  }

  void _togglePanel(String categoryName) {
    setState(() {
      _expandedPanels[categoryName] = !(_expandedPanels[categoryName] ?? false);
    });
  }

  void _handleCategoryChange(List<DataSourceCategory> categories) {
    _expandedPanels.clear();
    for (var category in categories) {
      _expandedPanels[category.name] = true;
    }
    widget.onChanged(widget.selection.copyWith(selectedCategories: categories));
  }

  Widget _buildPanelHeader(DataSourceCategory category) {
    final l10n = AppLocalizations.of(context)!;
    final count = _getCategoryCount(category);
    return ListTile(
      leading: Icon(category.icon, color: AppColors.primary),
      title: Text(category.label),
      subtitle: count > 0 ? Text(l10n.selectedItems(count)) : null,
      trailing: Icon(
        _expandedPanels[category.name] ?? false
            ? Icons.expand_less
            : Icons.expand_more,
        color: AppColors.textTertiary,
      ),
      onTap: () => _togglePanel(category.name),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  int _getCategoryCount(DataSourceCategory category) {
    switch (category) {
      case DataSourceCategory.tags:
        return widget.selection.selectedTags.length;
      case DataSourceCategory.toolOutput:
        return widget.selection.selectedToolOutputIds.length;
      case DataSourceCategory.records:
        return widget.selection.dateRange != null ? 1 : 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Column(
        children: [
          CategorySelector(
            selectedCategories: widget.selection.selectedCategories,
            onChanged: _handleCategoryChange,
          ),
          if (widget.selection.selectedCategories.isNotEmpty)
            ExpansionPanelList(
              expandedHeaderPadding: EdgeInsets.zero,
              dividerColor: Colors.transparent,
              elevation: 0,
              children: widget.selection.selectedCategories
                  .map((category) => ExpansionPanel(
                        headerBuilder: (_, isExpanded) =>
                            _buildPanelHeader(category),
                        body: _buildPanelContent(category),
                        isExpanded: _expandedPanels[category.name] ?? false,
                        canTapOnHeader: true,
                      ))
                  .toList(),
              expansionCallback: (_, isExpanded) {},
            ),
          if (widget.selection.selectedCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                l10n.selectDataSourceType,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPanelContent(DataSourceCategory category) {
    switch (category) {
      case DataSourceCategory.tags:
        return TagSelector(
          selectedTags: widget.selection.selectedTags,
          onSelected: (tags) => widget.onChanged(
            widget.selection.copyWith(selectedTags: tags),
          ),
        );
      case DataSourceCategory.toolOutput:
        return ToolOutputSelector(
          selectedToolId: widget.toolId,
          selectedOutputIds: widget.selection.selectedToolOutputIds,
          onSelected: (ids) => widget.onChanged(
            widget.selection.copyWith(selectedToolOutputIds: ids),
          ),
        );
      case DataSourceCategory.records:
        return RecordFilterSection(
          dateRange: widget.selection.dateRange,
          includeAiAnalysis: widget.selection.includeAiAnalysis,
          onDateRangeChanged: (range) => widget.onChanged(
            widget.selection.copyWith(dateRange: range),
          ),
          onIncludeAiAnalysisChanged: (include) => widget.onChanged(
            widget.selection.copyWith(includeAiAnalysis: include),
          ),
        );
    }
  }
}