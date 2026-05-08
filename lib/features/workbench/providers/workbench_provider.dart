import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../models/workbench_tool.dart';

final workbenchProvider = StateNotifierProvider<WorkbenchNotifier, WorkbenchState>((ref) {
  return WorkbenchNotifier();
});

class WorkbenchState {
  final List<WorkbenchTool> tools;
  final WorkbenchLayoutConfig layoutConfig;
  final bool isLoading;
  final bool isEditMode;

  const WorkbenchState({
    this.tools = const [],
    this.layoutConfig = const WorkbenchLayoutConfig(),
    this.isLoading = true,
    this.isEditMode = false,
  });

  WorkbenchState copyWith({
    List<WorkbenchTool>? tools,
    WorkbenchLayoutConfig? layoutConfig,
    bool? isLoading,
    bool? isEditMode,
  }) {
    return WorkbenchState(
      tools: tools ?? this.tools,
      layoutConfig: layoutConfig ?? this.layoutConfig,
      isLoading: isLoading ?? this.isLoading,
      isEditMode: isEditMode ?? this.isEditMode,
    );
  }

  List<WorkbenchTool> get sortedTools {
    final order = layoutConfig.toolOrder;
    if (order.isEmpty) return tools;

    final sorted = [...tools];
    sorted.sort((a, b) {
      final indexA = order.indexOf(a.id);
      final indexB = order.indexOf(b.id);
      if (indexA == -1 && indexB == -1) return 0;
      if (indexA == -1) return 1;
      if (indexB == -1) return -1;
      return indexA.compareTo(indexB);
    });
    return sorted;
  }

  List<WorkbenchTool> get visibleTools {
    return sortedTools.where((t) {
      final visibility = layoutConfig.toolVisibility[t.id];
      return visibility ?? true;
    }).toList();
  }
}

class WorkbenchNotifier extends StateNotifier<WorkbenchState> {
  static const _toolsKey = 'workbench_tools';
  static const _layoutKey = 'workbench_layout';

  WorkbenchNotifier() : super(const WorkbenchState()) {
    _loadWorkbench();
  }

  static List<WorkbenchTool> get defaultTools => [
    const WorkbenchTool(
      id: 'mindmap',
      name: '知识脑图',
      description: '可视化知识关联，AI智能生成脑图',
      icon: Icons.account_tree_outlined,
      color: AppColors.purple,
      category: ToolCategory.analysis,
      route: '/mindmap',
      sortOrder: 0,
    ),
    const WorkbenchTool(
      id: 'weekly_report',
      name: '智能周报',
      description: 'AI自动生成周报，支持多种模板',
      icon: Icons.summarize_outlined,
      color: AppColors.success,
      category: ToolCategory.productivity,
      route: '/weekly-report',
      sortOrder: 1,
    ),
    const WorkbenchTool(
      id: 'reminders',
      name: '智能提醒',
      description: '设置提醒事项，不再错过重要工作',
      icon: Icons.notifications_active_outlined,
      color: AppColors.warning,
      category: ToolCategory.productivity,
      route: '/reminders',
      sortOrder: 2,
    ),
    const WorkbenchTool(
      id: 'statistics',
      name: '使用统计',
      description: '查看记录统计、趋势分析',
      icon: Icons.bar_chart_outlined,
      color: AppColors.info,
      category: ToolCategory.analysis,
      route: '/statistics',
      sortOrder: 3,
    ),
    const WorkbenchTool(
      id: 'role_management',
      name: 'AI角色管理',
      description: '管理AI分析角色和提示词模板',
      icon: Icons.manage_accounts_outlined,
      color: AppColors.primary,
      category: ToolCategory.ai,
      route: '/settings/roles',
      sortOrder: 4,
    ),
    const WorkbenchTool(
      id: 'ocr',
      name: 'OCR文字识别',
      description: '拍照识别文字，快速提取内容',
      icon: Icons.document_scanner_outlined,
      color: AppColors.secondary,
      category: ToolCategory.productivity,
      route: '/ocr',
      sortOrder: 5,
    ),
    const WorkbenchTool(
      id: 'quick_note',
      name: '快速笔记',
      description: '快速记录灵感，支持标签分类',
      icon: Icons.edit_note_outlined,
      color: AppColors.primaryLight,
      category: ToolCategory.productivity,
      route: '/quick-note',
      sortOrder: 6,
    ),
    const WorkbenchTool(
      id: 'favorites',
      name: '收藏夹',
      description: '查看和管理收藏的记录',
      icon: Icons.star_border_outlined,
      color: AppColors.warning,
      category: ToolCategory.management,
      route: '/favorites',
      sortOrder: 7,
    ),
    const WorkbenchTool(
      id: 'prompt_templates',
      name: '提示词模板',
      description: '管理AI分析提示词模板',
      icon: Icons.code_outlined,
      color: AppColors.secondaryDark,
      category: ToolCategory.ai,
      route: '/settings/prompt-templates',
      sortOrder: 8,
    ),
    const WorkbenchTool(
      id: 'analysis_templates',
      name: '分析模板',
      description: '配置AI分析模板和周报模板',
      icon: Icons.auto_fix_high_outlined,
      color: AppColors.purple,
      category: ToolCategory.ai,
      route: '/settings/analysis-templates',
      sortOrder: 9,
    ),
    const WorkbenchTool(
      id: 'backup',
      name: '备份管理',
      description: '数据备份、导出和恢复',
      icon: Icons.backup_outlined,
      color: AppColors.info,
      category: ToolCategory.management,
      route: '/settings/backup',
      sortOrder: 10,
    ),
    const WorkbenchTool(
      id: 'recycle_bin',
      name: '回收站',
      description: '恢复已删除的记录',
      icon: Icons.delete_outline,
      color: AppColors.error,
      category: ToolCategory.management,
      route: '/settings/recycle-bin',
      sortOrder: 11,
    ),
  ];

  Future<void> _loadWorkbench() async {
    final prefs = await SharedPreferences.getInstance();

    final toolsJson = prefs.getString(_toolsKey);
    List<WorkbenchTool> tools;
    if (toolsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(toolsJson);
        tools = decoded.map((e) => WorkbenchTool.fromJson(e)).toList();
      } catch (_) {
        tools = defaultTools;
      }
    } else {
      tools = defaultTools;
    }

    final layoutJson = prefs.getString(_layoutKey);
    WorkbenchLayoutConfig layout;
    if (layoutJson != null) {
      try {
        layout = WorkbenchLayoutConfig.fromJson(jsonDecode(layoutJson));
      } catch (_) {
        layout = const WorkbenchLayoutConfig();
      }
    } else {
      layout = const WorkbenchLayoutConfig(
        toolOrder: [],
      );
    }

    state = state.copyWith(
      tools: tools,
      layoutConfig: layout,
      isLoading: false,
    );
  }

  Future<void> _saveTools() async {
    final prefs = await SharedPreferences.getInstance();
    final toolsJson = jsonEncode(state.tools.map((t) => t.toJson()).toList());
    await prefs.setString(_toolsKey, toolsJson);
  }

  Future<void> _saveLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final layoutJson = jsonEncode(state.layoutConfig.toJson());
    await prefs.setString(_layoutKey, layoutJson);
  }

  void setEditMode(bool value) {
    state = state.copyWith(isEditMode: value);
  }

  void toggleLayoutMode() {
    final newMode = state.layoutConfig.layoutMode == ToolLayoutMode.grid
        ? ToolLayoutMode.list
        : ToolLayoutMode.grid;
    state = state.copyWith(
      layoutConfig: state.layoutConfig.copyWith(layoutMode: newMode),
    );
    _saveLayout();
  }

  void setLayoutMode(ToolLayoutMode mode) {
    state = state.copyWith(
      layoutConfig: state.layoutConfig.copyWith(layoutMode: mode),
    );
    _saveLayout();
  }

  void reorderTools(int oldIndex, int newIndex) {
    final tools = [...state.tools];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = tools.removeAt(oldIndex);
    tools.insert(newIndex, item);

    final order = tools.map((t) => t.id).toList();
    state = state.copyWith(
      tools: tools,
      layoutConfig: state.layoutConfig.copyWith(toolOrder: order),
    );
    _saveTools();
    _saveLayout();
  }

  void toggleToolVisibility(String toolId) {
    final visibility = {...state.layoutConfig.toolVisibility};
    visibility[toolId] = !(visibility[toolId] ?? true);
    state = state.copyWith(
      layoutConfig: state.layoutConfig.copyWith(toolVisibility: visibility),
    );
    _saveLayout();
  }

  void resetToDefault() {
    state = state.copyWith(
      tools: defaultTools,
      layoutConfig: const WorkbenchLayoutConfig(),
    );
    _saveTools();
    _saveLayout();
  }
}
