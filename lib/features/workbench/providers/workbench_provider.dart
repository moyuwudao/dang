import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../models/workbench_tool.dart';

final workbenchProvider =
    StateNotifierProvider<WorkbenchNotifier, WorkbenchState>((ref) {
  return WorkbenchNotifier();
});

class WorkbenchState {
  final List<WorkbenchTool> tools;
  final WorkbenchLayoutConfig layoutConfig;
  final bool isLoading;
  final bool isEditMode;
  final ToolCategory? selectedCategory;

  const WorkbenchState({
    this.tools = const [],
    this.layoutConfig = const WorkbenchLayoutConfig(),
    this.isLoading = true,
    this.isEditMode = false,
    this.selectedCategory,
  });

  WorkbenchState copyWith({
    List<WorkbenchTool>? tools,
    WorkbenchLayoutConfig? layoutConfig,
    bool? isLoading,
    bool? isEditMode,
    ToolCategory? selectedCategory,
    bool clearSelectedCategory = false,
  }) {
    return WorkbenchState(
      tools: tools ?? this.tools,
      layoutConfig: layoutConfig ?? this.layoutConfig,
      isLoading: isLoading ?? this.isLoading,
      isEditMode: isEditMode ?? this.isEditMode,
      selectedCategory: clearSelectedCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
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
    var filtered = sortedTools.where((t) {
      final visibility = layoutConfig.toolVisibility[t.id];
      return visibility ?? true;
    }).toList();

    if (selectedCategory != null) {
      filtered = filtered.where((t) => t.category == selectedCategory).toList();
    }

    return filtered;
  }

  List<WorkbenchTool> get homeTools {
    return sortedTools.where((t) {
      final showInHome = layoutConfig.showInHome[t.id] ?? false;
      return showInHome;
    }).toList();
  }

  List<WorkbenchTool> get recentTools {
    return layoutConfig.recentToolIds
        .map((id) => tools.where((t) => t.id == id).firstOrNull)
        .whereType<WorkbenchTool>()
        .toList();
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
          category: ToolCategory.productivity,
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
          id: 'smart_todo',
          name: '智能待办',
          description: '从记录中提取待办，按四象限自动分类',
          icon: Icons.task_alt_outlined,
          color: AppColors.primary,
          category: ToolCategory.productivity,
          route: '/smart-todo',
          sortOrder: 2,
        ),
        const WorkbenchTool(
          id: 'meeting_minutes',
          name: '会议纪要',
          description: '录音转结构化纪要，议题/决策/行动项',
          icon: Icons.description_outlined,
          color: Color(0xFF0EA5E9),
          category: ToolCategory.productivity,
          route: '/meeting-minutes',
          sortOrder: 3,
        ),
        const WorkbenchTool(
          id: 'email_draft',
          name: '邮件草稿',
          description: '语音/文本一键生成商务邮件',
          icon: Icons.mail_outlined,
          color: Color(0xFF6366F1),
          category: ToolCategory.productivity,
          route: '/email-draft',
          sortOrder: 4,
        ),
        const WorkbenchTool(
          id: 'multi_platform_copy',
          name: '多平台文案',
          description: '一条灵感，多平台分发文案',
          icon: Icons.content_copy_outlined,
          color: Color(0xFFEC4899),
          category: ToolCategory.productivity,
          route: '/multi-platform-copy',
          sortOrder: 5,
        ),
        const WorkbenchTool(
          id: 'voice_diary',
          name: '语音日记',
          description: '语音自动提取事件/情绪/反思',
          icon: Icons.auto_stories_outlined,
          color: Color(0xFF8B5CF6),
          category: ToolCategory.productivity,
          route: '/voice-diary',
          sortOrder: 6,
        ),
        const WorkbenchTool(
          id: 'quick_translate',
          name: '快速翻译',
          description: '语音/文本/图片多语言翻译',
          icon: Icons.translate_outlined,
          color: Color(0xFF06B6D4),
          category: ToolCategory.productivity,
          route: '/quick-translate',
          sortOrder: 7,
        ),
        const WorkbenchTool(
          id: 'time_audit',
          name: '时间审计',
          description: '分析一周时间分配，发现效率黑洞',
          icon: Icons.schedule_outlined,
          color: Color(0xFF06B6D4),
          category: ToolCategory.analysis,
          route: '/time-audit',
          sortOrder: 8,
        ),
        const WorkbenchTool(
          id: 'project_review',
          name: '项目复盘',
          description: 'AI辅助项目复盘，目标/过程/教训',
          icon: Icons.rate_review_outlined,
          color: Color(0xFF14B8A6),
          category: ToolCategory.analysis,
          route: '/project-review',
          sortOrder: 9,
        ),
        const WorkbenchTool(
          id: 'swot_analysis',
          name: 'SWOT分析',
          description: '录音生成SWOT战略分析矩阵',
          icon: Icons.grid_on_outlined,
          color: Color(0xFF3B82F6),
          category: ToolCategory.analysis,
          route: '/swot-analysis',
          sortOrder: 10,
        ),
        const WorkbenchTool(
          id: 'customer_profile',
          name: '客户画像',
          description: '沟通记录自动提取客户偏好和需求',
          icon: Icons.person_search_outlined,
          color: Color(0xFF8B5CF6),
          category: ToolCategory.analysis,
          route: '/customer-profile',
          sortOrder: 11,
        ),
        const WorkbenchTool(
          id: 'trend_insight',
          name: '趋势洞察',
          description: '长期记录关键词趋势与话题演变',
          icon: Icons.trending_up_outlined,
          color: Color(0xFF6366F1),
          category: ToolCategory.analysis,
          route: '/trend-insight',
          sortOrder: 12,
        ),
        const WorkbenchTool(
          id: 'competitor_radar',
          name: '竞品雷达',
          description: '竞品信息自动整理成对比矩阵',
          icon: Icons.my_location_outlined,
          color: Color(0xFF0EA5E9),
          category: ToolCategory.analysis,
          route: '/competitor-radar',
          sortOrder: 13,
        ),
        const WorkbenchTool(
          id: 'project_board',
          name: '项目看板',
          description: '碎片记录自动构建项目进度视图',
          icon: Icons.view_agenda_outlined,
          color: Color(0xFFF59E0B),
          category: ToolCategory.management,
          route: '/project-board',
          sortOrder: 14,
        ),
        const WorkbenchTool(
          id: 'lightweight_crm',
          name: '轻量CRM',
          description: '沟通记录提取客户卡片和跟进要点',
          icon: Icons.contacts_outlined,
          color: Color(0xFF10B981),
          category: ToolCategory.management,
          route: '/lightweight-crm',
          sortOrder: 15,
        ),
        const WorkbenchTool(
          id: 'invoice_recognition',
          name: '发票识别',
          description: '拍照识别发票，自动提取财务数据',
          icon: Icons.receipt_long_outlined,
          color: Color(0xFFEF4444),
          category: ToolCategory.management,
          route: '/invoice-recognition',
          sortOrder: 16,
        ),
        const WorkbenchTool(
          id: 'contract_summary',
          name: '合同摘要',
          description: '合同图片提取关键条款和风险点',
          icon: Icons.gavel_outlined,
          color: Color(0xFF8B5CF6),
          category: ToolCategory.management,
          route: '/contract-summary',
          sortOrder: 17,
        ),
        const WorkbenchTool(
          id: 'quotation',
          name: '报价单',
          description: '客户需求一键生成报价方案',
          icon: Icons.request_quote_outlined,
          color: Color(0xFF06B6D4),
          category: ToolCategory.management,
          route: '/quotation',
          sortOrder: 18,
        ),
        const WorkbenchTool(
          id: 'knowledge_card',
          name: '知识卡片',
          description: '记录转化为Anki闪卡，随时复习',
          icon: Icons.style_outlined,
          color: Color(0xFFEC4899),
          category: ToolCategory.management,
          route: '/knowledge-card',
          sortOrder: 19,
        ),
        const WorkbenchTool(
          id: 'ai_advisor',
          name: 'AI顾问',
          description: '一人公司的联合创始人，多角度分析',
          icon: Icons.psychology_outlined,
          color: Color(0xFF8B5CF6),
          category: ToolCategory.ai,
          route: '/ai-advisor',
          sortOrder: 20,
        ),
        const WorkbenchTool(
          id: 'creative_diverge',
          name: '创意发散',
          description: 'SCAMPER/六顶思考帽多角度创意',
          icon: Icons.lightbulb_outlined,
          color: Color(0xFFEC4899),
          category: ToolCategory.ai,
          route: '/creative-diverge',
          sortOrder: 21,
        ),
        const WorkbenchTool(
          id: 'knowledge_qa',
          name: '知识库问答',
          description: '搜自己的记忆，基于个人数据问答',
          icon: Icons.question_answer_outlined,
          color: Color(0xFF6366F1),
          category: ToolCategory.ai,
          route: '/knowledge-qa',
          sortOrder: 22,
        ),
        const WorkbenchTool(
          id: 'decision_matrix',
          name: '决策矩阵',
          description: '多选项加权评分，量化分析决策',
          icon: Icons.calculate_outlined,
          color: Color(0xFF3B82F6),
          category: ToolCategory.ai,
          route: '/decision-matrix',
          sortOrder: 23,
        ),
        const WorkbenchTool(
          id: 'writing_workshop',
          name: '写作工坊',
          description: '碎片素材渐进式写作，从大纲到长文',
          icon: Icons.edit_note_outlined,
          color: Color(0xFF10B981),
          category: ToolCategory.ai,
          route: '/writing-workshop',
          sortOrder: 24,
        ),
        const WorkbenchTool(
          id: 'daily_three_questions',
          name: '每日三问',
          description: '基于当日记录，AI提出深度反思问题',
          icon: Icons.quiz_outlined,
          color: Color(0xFFF59E0B),
          category: ToolCategory.ai,
          route: '/daily-three-questions',
          sortOrder: 25,
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

    final storedIds = tools.map((t) => t.id).toSet();
    for (final defaultTool in defaultTools) {
      if (!storedIds.contains(defaultTool.id)) {
        tools.add(defaultTool);
      }
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

  void setSelectedCategory(ToolCategory? category) {
    if (category == null) {
      state = state.copyWith(clearSelectedCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
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

  void toggleShowInHome(String toolId) {
    final showInHome = {...state.layoutConfig.showInHome};
    showInHome[toolId] = !(showInHome[toolId] ?? false);
    state = state.copyWith(
      layoutConfig: state.layoutConfig.copyWith(showInHome: showInHome),
    );
    _saveLayout();
  }

  void openTool(String toolId) {
    final recent = [...state.layoutConfig.recentToolIds];
    recent.remove(toolId);
    recent.insert(0, toolId);
    if (recent.length > WorkbenchLayoutConfig.maxRecentTools) {
      recent.removeRange(WorkbenchLayoutConfig.maxRecentTools, recent.length);
    }
    state = state.copyWith(
      layoutConfig: state.layoutConfig.copyWith(recentToolIds: recent),
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
