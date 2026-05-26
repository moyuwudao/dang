import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workbench_tool.dart';
import '../providers/workbench_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class ToolDisplaySettingsScreen extends ConsumerStatefulWidget {
  const ToolDisplaySettingsScreen({super.key});

  @override
  ConsumerState<ToolDisplaySettingsScreen> createState() =>
      _ToolDisplaySettingsScreenState();
}

class _ToolDisplaySettingsScreenState
    extends ConsumerState<ToolDisplaySettingsScreen> {
  String? _searchQuery;
  ToolCategory? _selectedCategory;
  late AppLocalizations _l10n;

  @override
  Widget build(BuildContext context) {
    _l10n = AppLocalizations.of(context)!;
    final workbenchAsync = ref.watch(workbenchProvider);

    return workbenchAsync.when(
      data: (workbenchState) {
        final allTools = workbenchState.tools;

        final homeToolCount =
            workbenchState.layoutConfig.showInHome.values.where((v) => v).length;

        var filteredTools = allTools;

        if (_selectedCategory != null) {
          filteredTools =
              filteredTools.where((t) => t.category == _selectedCategory).toList();
        }

        if (_searchQuery != null && _searchQuery!.isNotEmpty) {
          filteredTools = filteredTools
              .where(
                  (t) => t.name.toLowerCase().contains(_searchQuery!.toLowerCase()))
              .toList();
        }

        final categories = [
          (null, _l10n.allCategories),
          (ToolCategory.productivity, _l10n.efficiency),
          (ToolCategory.analysis, _l10n.analysis),
          (ToolCategory.management, _l10n.management),
          (ToolCategory.ai, _l10n.ai),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(_l10n.toolDisplaySettings),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: _l10n.searchTools,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: categories.map((item) {
                    final category = item.$1;
                    final label = item.$2;
                    final isSelected = _selectedCategory == category;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() =>
                              _selectedCategory = isSelected ? null : category);
                        },
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primary.withValues(alpha: 0.1),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _l10n.toolsSelectedForHomeDisplay(homeToolCount),
                  style: TextStyle(
                    fontSize: 13,
                    color: homeToolCount >= 5
                        ? AppColors.warning
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              _buildTableHeader(),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredTools.length,
                  itemBuilder: (context, index) {
                    final tool = filteredTools[index];
                    final isVisible =
                        workbenchState.layoutConfig.toolVisibility[tool.id] ?? true;
                    final showInHome =
                        workbenchState.layoutConfig.showInHome[tool.id] ?? false;

                    return _ToolDisplayRow(
                      tool: tool,
                      isVisible: isVisible,
                      showInHome: showInHome,
                      canAddToHome: homeToolCount < 5 || showInHome,
                      l10n: _l10n,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surfaceVariant,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _l10n.toolName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                _l10n.showOnHome,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                _l10n.hidden,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolDisplayRow extends ConsumerWidget {
  final WorkbenchTool tool;
  final bool isVisible;
  final bool showInHome;
  final bool canAddToHome;
  final AppLocalizations l10n;

  const _ToolDisplayRow({
    required this.tool,
    required this.isVisible,
    required this.showInHome,
    required this.canAddToHome,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(tool.icon, color: tool.color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tool.name,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      _buildCategoryBadge(tool.category),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Switch(
                value: showInHome,
                onChanged: (value) {
                  if (value && !canAddToHome) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.homeMaxFiveTools),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                    return;
                  }
                  ref
                      .read(workbenchProvider.notifier)
                      .toggleShowInHome(tool.id);
                },
                activeThumbColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Switch(
                value: isVisible,
                onChanged: (value) {
                  if (value == false && showInHome) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.homeToolsCannotBeHidden),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                    return;
                  }
                  ref
                      .read(workbenchProvider.notifier)
                      .toggleToolVisibility(tool.id);
                },
                activeThumbColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(ToolCategory category) {
    final colors = {
      ToolCategory.productivity: AppColors.primary,
      ToolCategory.analysis: AppColors.info,
      ToolCategory.management: AppColors.success,
      ToolCategory.ai: AppColors.purple,
    };

    final names = {
      ToolCategory.productivity: l10n.efficiency,
      ToolCategory.analysis: l10n.analysis,
      ToolCategory.management: l10n.management,
      ToolCategory.ai: l10n.ai,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colors[category]!.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        names[category]!,
        style: TextStyle(
          fontSize: 11,
          color: colors[category],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
