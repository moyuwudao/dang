import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workbench_tool.dart';
import '../providers/workbench_provider.dart';
import '../../../core/theme/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    final workbenchState = ref.watch(workbenchProvider);
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
      (null, '全部'),
      (ToolCategory.productivity, '效率'),
      (ToolCategory.analysis, '分析'),
      (ToolCategory.management, '管理'),
      (ToolCategory.ai, 'AI'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('工具展示设置'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: '搜索工具...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
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
              '已选择 $homeToolCount/5 个工具显示在首页',
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surfaceVariant,
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '工具名称',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                '展示在首页',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                '是否隐藏',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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

  const _ToolDisplayRow({
    required this.tool,
    required this.isVisible,
    required this.showInHome,
    required this.canAddToHome,
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
                      const SnackBar(
                        content: Text('首页最多显示5个工具'),
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
                      const SnackBar(
                        content: Text('展示在首页的工具不得隐藏'),
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
      ToolCategory.productivity: '效率',
      ToolCategory.analysis: '分析',
      ToolCategory.management: '管理',
      ToolCategory.ai: 'AI',
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
