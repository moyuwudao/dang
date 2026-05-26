import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/workbench_tool.dart';
import '../providers/workbench_provider.dart';

class WorkbenchScreen extends ConsumerStatefulWidget {
  const WorkbenchScreen({super.key});

  @override
  ConsumerState<WorkbenchScreen> createState() => _WorkbenchScreenState();
}

class _WorkbenchScreenState extends ConsumerState<WorkbenchScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workbenchAsync = ref.watch(workbenchProvider);

    return workbenchAsync.when(
      data: (workbenchState) {
        final isEditMode = workbenchState.isEditMode;
        final layoutMode = workbenchState.layoutConfig.layoutMode;
        final tools = workbenchState.visibleTools;
        final selectedCategory = workbenchState.selectedCategory;
        final recentTools = workbenchState.recentTools;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(l10n.workbench),
            centerTitle: true,
            actions: [
              if (isEditMode)
                TextButton(
                  onPressed: () {
                    ref.read(workbenchProvider.notifier).setEditMode(false);
                  },
                  child: Text(
                    l10n.done,
                    style: TextStyle(color: Colors.white),
                  ),
                )
              else ...[
                IconButton(
                  icon: const Icon(Icons.folder_open_outlined),
                  tooltip: l10n.toolOutputs,
                  onPressed: () => context.push('/tool-outputs'),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => _showWorkbenchSettings(context),
                ),
              ],
            ],
          ),
          body: workbenchState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildCategoryFilter(selectedCategory),
                    Expanded(
                      child: isEditMode
                          ? _buildReorderableView(tools, layoutMode)
                          : _buildMainContent(tools, recentTools, layoutMode),
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

  Widget _buildMainContent(List<WorkbenchTool> tools,
      List<WorkbenchTool> recentTools, ToolLayoutMode layoutMode) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (recentTools.isNotEmpty) ...[
          _buildRecentToolsSection(recentTools),
          const SizedBox(height: 20),
        ],
        if (tools.isEmpty)
          _buildEmptyState()
        else if (layoutMode == ToolLayoutMode.grid)
          _buildGridView(tools)
        else
          _buildListView(tools),
      ],
    );
  }

  Widget _buildRecentToolsSection(List<WorkbenchTool> recentTools) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context)!.recentlyUsed,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recentTools.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final tool = recentTools[index];
              return _buildRecentToolChip(tool);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentToolChip(WorkbenchTool tool) {
    return InkWell(
      onTap: () {
        ref.read(workbenchProvider.notifier).openTool(tool.id);
        context.push(tool.route);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: tool.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tool.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tool.icon, color: tool.color, size: 24),
            const SizedBox(height: 6),
            Text(
              tool.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tool.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(ToolCategory? selectedCategory) {
    final l10n = AppLocalizations.of(context)!;
    final categories = [
      (null, l10n.allCategories),
      (ToolCategory.productivity, l10n.productivityTools),
      (ToolCategory.analysis, l10n.analysisTools),
      (ToolCategory.management, l10n.managementTools),
      (ToolCategory.ai, l10n.aiTools),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((item) {
            final category = item.$1;
            final label = item.$2;
            final isSelected = selectedCategory == category;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) {
                  ref.read(workbenchProvider.notifier).setSelectedCategory(
                        isSelected ? null : category,
                      );
                },
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.primary.withValues(alpha: 0.1),
                checkmarkColor: AppColors.primary,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                ),
                labelStyle: TextStyle(
                  fontSize: 13,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReorderableView(
      List<WorkbenchTool> tools, ToolLayoutMode layoutMode) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tools.length,
      onReorder: (oldIndex, newIndex) {
        ref.read(workbenchProvider.notifier).reorderTools(oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: child,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final tool = tools[index];
        return Padding(
          key: ValueKey(tool.id),
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildListToolCard(tool, showDragHandle: true),
        );
      },
    );
  }

  Widget _buildGridView(List<WorkbenchTool> tools) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _buildGridToolCard(tool);
      },
    );
  }

  Widget _buildListView(List<WorkbenchTool> tools) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildListToolCard(tool),
        );
      },
    );
  }

  Widget _buildGridToolCard(WorkbenchTool tool) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          ref.read(workbenchProvider.notifier).openTool(tool.id);
          context.push(tool.route);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tool.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      tool.icon,
                      color: tool.color,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  _buildCategoryBadge(tool.category),
                ],
              ),
              const Spacer(),
              Text(
                tool.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                tool.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(ToolCategory category) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      ToolCategory.productivity: (l10n.productivityTools, AppColors.primary),
      ToolCategory.analysis: (l10n.analysisTools, const Color(0xFF06B6D4)),
      ToolCategory.management: (l10n.managementTools, const Color(0xFFF59E0B)),
      ToolCategory.ai: (l10n.aiTools, const Color(0xFF8B5CF6)),
    };
    final (label, color) = labels[category]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildListToolCard(WorkbenchTool tool, {bool showDragHandle = false}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: showDragHandle
            ? null
            : () {
                ref.read(workbenchProvider.notifier).openTool(tool.id);
                context.push(tool.route);
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tool.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  tool.icon,
                  color: tool.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tool.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryBadge(tool.category),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tool.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (showDragHandle)
                const Icon(
                  Icons.drag_handle,
                  color: AppColors.textTertiary,
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary.withOpacity(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.widgets_outlined,
            size: 64,
            color: AppColors.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noTools,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addToolsInSettings,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _showWorkbenchSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workbenchState = ref.read(workbenchProvider).valueOrNull;
    if (workbenchState == null) return;
    final layoutMode = workbenchState.layoutConfig.layoutMode;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.workbenchSettings,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.view_module_outlined, color: AppColors.primary),
                  title: Text(l10n.layout),
                  subtitle: Text(layoutMode == ToolLayoutMode.grid ? l10n.cardLayout : l10n.listLayout),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.grid_view,
                          color: layoutMode == ToolLayoutMode.grid
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                        onPressed: () {
                          ref.read(workbenchProvider.notifier).setLayoutMode(ToolLayoutMode.grid);
                          Navigator.pop(context);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.view_list,
                          color: layoutMode == ToolLayoutMode.list
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                        onPressed: () {
                          ref.read(workbenchProvider.notifier).setLayoutMode(ToolLayoutMode.list);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.reorder, color: AppColors.secondary),
                  title: Text(l10n.sortTools),
                  subtitle: Text(l10n.reorderTools),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(workbenchProvider.notifier).setEditMode(true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.visibility_outlined, color: AppColors.info),
                  title: Text(l10n.showHideTools),
                  subtitle: Text(l10n.customizeVisibleTools),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    _showToolVisibilityDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restore, color: AppColors.warning),
                  title: Text(l10n.restoreDefault),
                  subtitle: Text(l10n.resetToInitialLayout),
                  onTap: () {
                    ref.read(workbenchProvider.notifier).resetToDefault();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.settingsRestored),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showToolVisibilityDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workbenchState = ref.read(workbenchProvider).valueOrNull;
    if (workbenchState == null) return;
    final allTools = workbenchState.tools;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.showHideTools),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allTools.length,
              itemBuilder: (context, index) {
                final tool = allTools[index];
                final isVisible = workbenchState.layoutConfig.toolVisibility[tool.id] ?? true;

                return StatefulBuilder(
                  builder: (context, setState) {
                    return CheckboxListTile(
                      title: Row(
                        children: [
                          Icon(tool.icon, color: tool.color, size: 20),
                          const SizedBox(width: 8),
                          Text(tool.name),
                        ],
                      ),
                      value: isVisible,
                      onChanged: (value) {
                        ref.read(workbenchProvider.notifier).toggleToolVisibility(tool.id);
                        setState(() {});
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.done),
            ),
          ],
        );
      },
    );
  }
}
