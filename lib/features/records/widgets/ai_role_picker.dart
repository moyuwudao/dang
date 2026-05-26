import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/ai_role.dart';
import '../../../core/services/prompt_template_service.dart';
import '../../../core/services/role_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../workbench/tools/tool_configs.dart';

enum RolePickerTab { system, custom, template, tool }

class AiRolePicker extends ConsumerStatefulWidget {
  final Function(AiRole role) onRoleSelected;
  final VoidCallback? onManageRoles;

  const AiRolePicker({
    super.key,
    required this.onRoleSelected,
    this.onManageRoles,
  });

  @override
  ConsumerState<AiRolePicker> createState() => _AiRolePickerState();
}

class _AiRolePickerState extends ConsumerState<AiRolePicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AiRole> _systemRoles = [];
  List<AiRole> _customRoles = [];
  List<PromptTemplate> _templates = [];
  List<ToolConfig> _tools = [];
  List<String> _recentToolIds = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final templateService = ref.read(promptTemplateServiceProvider);
    await templateService.initialize();

    final systemRoles = AiRole.builtInRoles;
    final customRoles = await RoleService.getCustomRoles();
    final templates = templateService.getAllTemplates();

    final tools = toolConfigs.values.toList();
    final recentToolIds = await _getRecentToolIds();

    if (mounted) {
      setState(() {
        _systemRoles = systemRoles;
        _customRoles = customRoles;
        _templates = templates;
        _tools = tools;
        _recentToolIds = recentToolIds;
        _isLoading = false;
      });
    }
  }

  Future<List<String>> _getRecentToolIds() async {
    final layoutConfigJson = await StorageService.getString('workbench_layout');
    if (layoutConfigJson != null) {
      try {
        final config = Map<String, dynamic>.from(jsonDecode(layoutConfigJson));
        final recentIds =
            (config['recentToolIds'] as List<dynamic>?)?.cast<String>() ?? [];
        return recentIds.take(5).toList();
      } catch (_) {}
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildTabBar(),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSystemRolesTab(),
                      _buildCustomRolesTab(),
                      _buildTemplatesTab(),
                      _buildToolsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                l10n.selectAiRole,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              // 管理按钮已移除
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: l10n.searchRoleOrTemplate,
          prefixIcon: const Icon(Icons.search, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(
            icon: Icon(Icons.verified, size: 20),
          ),
          Tab(
            icon: Icon(Icons.person_outline, size: 20),
          ),
          Tab(
            icon: Icon(Icons.auto_stories, size: 20),
          ),
          Tab(
            icon: Icon(Icons.build, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemRolesTab() {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _systemRoles
        .where((r) =>
            r.name.toLowerCase().contains(_searchQuery) ||
            r.description.toLowerCase().contains(_searchQuery))
        .toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(l10n.noMatchingSystemRole);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final role = filtered[index];
        return _buildRoleTile(role, Icons.verified, AppColors.success);
      },
    );
  }

  Widget _buildCustomRolesTab() {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _customRoles
        .where((r) =>
            r.name.toLowerCase().contains(_searchQuery) ||
            r.description.toLowerCase().contains(_searchQuery))
        .toList();

    if (filtered.isEmpty) {
      return _buildEmptyStateWithAction(
        l10n.noCustomRole,
        l10n.clickToCreateRole,
        widget.onManageRoles != null
            ? () {
                Navigator.pop(context);
                widget.onManageRoles!();
              }
            : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final role = filtered[index];
        return _buildRoleTile(role, Icons.person_outline, AppColors.primary);
      },
    );
  }

  Widget _buildTemplatesTab() {
    final l10n = AppLocalizations.of(context)!;
    final templateService = ref.read(promptTemplateServiceProvider);
    final categories = templateService.getCategories();

    if (_templates.isEmpty) {
      return _buildEmptyState(l10n.noTemplate);
    }

    // Get frequently used templates first
    final frequentlyUsed = _templates
        .where((t) =>
            t.useCount > 0 &&
            (t.name.toLowerCase().contains(_searchQuery) ||
                t.description.toLowerCase().contains(_searchQuery)))
        .toList()
      ..sort((a, b) => b.useCount.compareTo(a.useCount));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Frequently used section at the top
        if (frequentlyUsed.isNotEmpty && _searchQuery.isEmpty) ...[
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 6),
              Text(
                l10n.frequentlyUsedTemplates,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...frequentlyUsed
              .take(5)
              .map((template) => _buildTemplateTile(template)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
        ],

        // All categories as expandable sections
        ...categories.where((c) => c != 'frequently_used').map((category) {
          final categoryTemplates = _templates
              .where((t) =>
                  t.category == category &&
                  (t.name.toLowerCase().contains(_searchQuery) ||
                      t.description.toLowerCase().contains(_searchQuery)))
              .toList();

          if (categoryTemplates.isEmpty) return const SizedBox.shrink();

          return _ExpandableCategorySection(
            categoryLabel: _getCategoryLabel(category),
            templateCount: categoryTemplates.length,
            templates: categoryTemplates,
            onTemplateSelected: (template) => _selectTemplate(template),
          );
        }),
      ],
    );
  }

  void _selectTemplate(PromptTemplate template) async {
    final templateService = ref.read(promptTemplateServiceProvider);
    await templateService.incrementUseCount(template.id);
    final role = AiRole(
      id: 'template_${template.id}',
      name: template.name,
      description: template.description,
      systemPrompt: template.template,
      isBuiltIn: false,
      createdAt: DateTime.now(),
    );
    if (mounted) {
      Navigator.pop(context);
      widget.onRoleSelected(role);
    }
  }

  String _getCategoryLabel(String category) {
    const labels = {
      'frequently_used': '常用',
      'general': '通用',
      'solopreneur': '一人公司',
      'business': '商业',
      'productivity': '效率',
      'creative': '创意',
      'learning': '学习',
      'life': '生活',
      'fun': '趣味',
    };
    return labels[category] ?? category;
  }

  Map<String, String> _getToolCategoryLabel(String category) {
    const labels = {
      'frequently_used': {'label': '常用工具', 'icon': '⭐'},
      'productivity': {'label': '效率工具', 'icon': '⚡'},
      'analysis': {'label': '分析工具', 'icon': '📊'},
      'management': {'label': '管理工具', 'icon': '📋'},
      'ai': {'label': 'AI工具', 'icon': '🤖'},
    };
    return labels[category] ?? {'label': category, 'icon': '📦'};
  }

  Widget _buildToolsTab() {
    final l10n = AppLocalizations.of(context)!;
    final filteredTools = _tools
        .where((t) =>
            t.title.toLowerCase().contains(_searchQuery) ||
            t.id.toLowerCase().contains(_searchQuery))
        .toList();

    final recentTools = _recentToolIds
        .map((id) => _tools.firstWhere((t) => t.id == id,
            orElse: () => throw StateError('Tool not found')))
        .where((tool) => filteredTools.any((t) => t.id == tool.id))
        .toList();

    if (filteredTools.isEmpty) {
      return _buildEmptyState(l10n.noMatchingTool);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_searchQuery.isEmpty && recentTools.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 6),
              Text(
                l10n.frequentlyUsedTools,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recentTools.take(5).map((tool) => _buildToolTile(tool)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
        ],
        ..._getToolCategories().entries.map((entry) {
          final category = entry.key;
          final categoryTools = filteredTools
              .where((t) => _getToolCategory(t.id) == category)
              .toList();

          if (categoryTools.isEmpty) return const SizedBox.shrink();

          return _ExpandableToolCategorySection(
            categoryLabel: _getToolCategoryLabel(category)['label']!,
            categoryIcon: _getToolCategoryLabel(category)['icon']!,
            toolCount: categoryTools.length,
            tools: categoryTools,
            onToolSelected: (tool) => _selectTool(tool),
          );
        }),
      ],
    );
  }

  Map<String, List<ToolConfig>> _getToolCategories() {
    return {
      'productivity': _tools
          .where((t) => [
                'mindmap',
                'weekly_report',
                'smart_todo',
                'meeting_minutes',
                'email_draft',
                'multi_platform_copy',
                'voice_diary',
                'quick_translate',
              ].contains(t.id))
          .toList(),
      'analysis': _tools
          .where((t) => [
                'time_audit',
                'project_review',
                'swot_analysis',
                'customer_profile',
                'trend_insight',
                'competitor_radar',
              ].contains(t.id))
          .toList(),
      'management': _tools
          .where((t) => [
                'project_board',
                'lightweight_crm',
                'invoice_recognition',
                'contract_summary',
                'quotation',
                'knowledge_card',
              ].contains(t.id))
          .toList(),
      'ai': _tools
          .where((t) => [
                'ai_advisor',
                'creative_diverge',
                'knowledge_qa',
                'decision_matrix',
                'writing_workshop',
                'daily_three_questions',
              ].contains(t.id))
          .toList(),
    };
  }

  String _getToolCategory(String toolId) {
    if ([
      'mindmap',
      'weekly_report',
      'smart_todo',
      'meeting_minutes',
      'email_draft',
      'multi_platform_copy',
      'voice_diary',
      'quick_translate',
    ].contains(toolId)) {
      return 'productivity';
    }
    if ([
      'time_audit',
      'project_review',
      'swot_analysis',
      'customer_profile',
      'trend_insight',
      'competitor_radar',
    ].contains(toolId)) {
      return 'analysis';
    }
    if ([
      'project_board',
      'lightweight_crm',
      'invoice_recognition',
      'contract_summary',
      'quotation',
      'knowledge_card',
    ].contains(toolId)) {
      return 'management';
    }
    return 'ai';
  }

  Widget _buildToolTile(ToolConfig tool) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => _selectTool(tool),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.build, color: AppColors.info, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tool.emptyStateText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTool(ToolConfig tool) {
    final role = AiRole(
      id: 'tool_${tool.id}',
      name: tool.title,
      description: tool.emptyStateText,
      systemPrompt: tool.systemPrompt,
      isBuiltIn: true,
      createdAt: DateTime.now(),
    );
    if (mounted) {
      Navigator.pop(context);
      widget.onRoleSelected(role);
    }
  }

  Widget _buildRoleTile(AiRole role, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          widget.onRoleSelected(role);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateTile(PromptTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () async {
          // 增加模板使用次数
          final templateService = ref.read(promptTemplateServiceProvider);
          await templateService.incrementUseCount(template.id);

          // 模板被选择时，自动转为自定义角色
          final role = AiRole(
            id: 'template_${template.id}',
            name: template.name,
            description: template.description,
            systemPrompt: template.template,
            isBuiltIn: false,
            createdAt: DateTime.now(),
          );
          Navigator.pop(context);
          widget.onRoleSelected(role);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.auto_stories, color: AppColors.info, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      template.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWithAction(
    String title,
    String subtitle,
    VoidCallback? onAction,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          if (onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n.createRole),
            ),
          ],
        ],
      ),
    );
  }
}

// ========== 可展开分类组件 ==========
class _ExpandableCategorySection extends StatefulWidget {
  final String categoryLabel;
  final int templateCount;
  final List<PromptTemplate> templates;
  final ValueChanged<PromptTemplate> onTemplateSelected;

  const _ExpandableCategorySection({
    required this.categoryLabel,
    required this.templateCount,
    required this.templates,
    required this.onTemplateSelected,
  });

  @override
  State<_ExpandableCategorySection> createState() =>
      _ExpandableCategorySectionState();
}

class _ExpandableCategorySectionState
    extends State<_ExpandableCategorySection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: Radius.circular(_isExpanded ? 0 : 12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.categoryLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.templateCount}个方案',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, size: 20),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: widget.templates
                    .map((template) => _TemplateItem(
                          template: template,
                          onTap: () => widget.onTemplateSelected(template),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _TemplateItem extends StatelessWidget {
  final PromptTemplate template;
  final VoidCallback onTap;

  const _TemplateItem({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            const Icon(Icons.auto_stories, color: AppColors.info, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ========== 工具分类可展开组件 ==========
class _ExpandableToolCategorySection extends StatefulWidget {
  final String categoryLabel;
  final String categoryIcon;
  final int toolCount;
  final List<ToolConfig> tools;
  final ValueChanged<ToolConfig> onToolSelected;

  const _ExpandableToolCategorySection({
    required this.categoryLabel,
    required this.categoryIcon,
    required this.toolCount,
    required this.tools,
    required this.onToolSelected,
  });

  @override
  State<_ExpandableToolCategorySection> createState() =>
      _ExpandableToolCategorySectionState();
}

class _ExpandableToolCategorySectionState
    extends State<_ExpandableToolCategorySection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: Radius.circular(_isExpanded ? 0 : 12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text(widget.categoryIcon,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.categoryLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.toolCount}个工具',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, size: 20),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: widget.tools
                    .map((tool) => _ToolItem(
                          tool: tool,
                          onTap: () => widget.onToolSelected(tool),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToolItem extends StatelessWidget {
  final ToolConfig tool;
  final VoidCallback onTap;

  const _ToolItem({
    required this.tool,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            const Icon(Icons.build, color: AppColors.info, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tool.emptyStateText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}
