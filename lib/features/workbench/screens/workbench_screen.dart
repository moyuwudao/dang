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
