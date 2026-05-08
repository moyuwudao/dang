import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
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
    final workbenchState = ref.watch(workbenchProvider);
    final isEditMode = workbenchState.isEditMode;
    final layoutMode = workbenchState.layoutConfig.layoutMode;
    final tools = workbenchState.visibleTools;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('工作台'),
        centerTitle: true,
        actions: [
          if (isEditMode)
            TextButton(
              onPressed: () {
                ref.read(workbenchProvider.notifier).setEditMode(false);
              },
              child: const Text(
                '完成',
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => _showWorkbenchSettings(context),
            ),
        ],
      ),
      body: workbenchState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCategoryFilter(),
                Expanded(
                  child: isEditMode
                      ? _buildReorderableView(tools, layoutMode)
                      : _buildToolView(tools, layoutMode),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCategoryChip('全部', null),
            const SizedBox(width: 8),
            _buildCategoryChip('效率', ToolCategory.productivity),
            const SizedBox(width: 8),
            _buildCategoryChip('分析', ToolCategory.analysis),
            const SizedBox(width: 8),
            _buildCategoryChip('AI', ToolCategory.ai),
            const SizedBox(width: 8),
            _buildCategoryChip('管理', ToolCategory.management),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, ToolCategory? category) {
    return Consumer(
      builder: (context, ref, child) {
        return ActionChip(
          label: Text(label),
          onPressed: () {},
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.divider),
          labelStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        );
      },
    );
  }

  Widget _buildToolView(List<WorkbenchTool> tools, ToolLayoutMode layoutMode) {
    if (tools.isEmpty) {
      return _buildEmptyState();
    }

    if (layoutMode == ToolLayoutMode.grid) {
      return _buildGridView(tools);
    } else {
      return _buildListView(tools);
    }
  }

  Widget _buildReorderableView(List<WorkbenchTool> tools, ToolLayoutMode layoutMode) {
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
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _buildGridToolCard(tool);
      },
    );
  }

  Widget _buildListView(List<WorkbenchTool> tools) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
        onTap: () => context.push(tool.route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tool.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  tool.icon,
                  color: tool.color,
                  size: 28,
                ),
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

  Widget _buildListToolCard(WorkbenchTool tool, {bool showDragHandle = false}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: showDragHandle ? null : () => context.push(tool.route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tool.color.withOpacity(0.1),
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
                    Text(
                      tool.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
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
          const Text(
            '暂无工具',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '请在设置中添加工具',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _showWorkbenchSettings(BuildContext context) {
    final workbenchState = ref.read(workbenchProvider);
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
                const Text(
                  '工作台设置',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.view_module_outlined, color: AppColors.primary),
                  title: const Text('布局方式'),
                  subtitle: Text(layoutMode == ToolLayoutMode.grid ? '卡片式' : '列表式'),
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
                  title: const Text('排序工具'),
                  subtitle: const Text('拖拽调整工具顺序'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(workbenchProvider.notifier).setEditMode(true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.visibility_outlined, color: AppColors.info),
                  title: const Text('显示/隐藏工具'),
                  subtitle: const Text('自定义显示哪些工具'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    _showToolVisibilityDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restore, color: AppColors.warning),
                  title: const Text('恢复默认'),
                  subtitle: const Text('重置为初始布局'),
                  onTap: () {
                    ref.read(workbenchProvider.notifier).resetToDefault();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已恢复默认设置'),
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
    final workbenchState = ref.read(workbenchProvider);
    final allTools = workbenchState.tools;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('显示/隐藏工具'),
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
              child: const Text('完成'),
            ),
          ],
        );
      },
    );
  }
}
