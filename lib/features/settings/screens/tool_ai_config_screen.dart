import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../workbench/models/tool_template.dart';
import '../../workbench/models/workbench_tool.dart';
import '../../workbench/tools/tool_configs.dart';
import '../../workbench/tools/tool_templates.dart';
import '../../workbench/providers/tool_template_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/expandable_text_field.dart';

class ToolAiConfigScreen extends ConsumerStatefulWidget {
  const ToolAiConfigScreen({super.key});

  @override
  ConsumerState<ToolAiConfigScreen> createState() => _ToolAiConfigScreenState();
}

class _ToolAiConfigScreenState extends ConsumerState<ToolAiConfigScreen> {
  ToolCategory? _selectedCategory;
  String? _searchQuery;

  Map<ToolCategory, List<MapEntry<String, ToolConfig>>> _getToolsByCategory() {
    final map = <ToolCategory, List<MapEntry<String, ToolConfig>>>{};

    for (final entry in toolConfigs.entries) {
      final category = _getToolCategory(entry.key);
      map.putIfAbsent(category, () => []).add(entry);
    }

    return map;
  }

  ToolCategory _getToolCategory(String toolId) {
    switch (toolId) {
      case 'mindmap':
      case 'weekly_report':
      case 'smart_todo':
      case 'meeting_minutes':
      case 'email_draft':
      case 'multi_platform_copy':
      case 'voice_diary':
      case 'quick_translate':
        return ToolCategory.productivity;
      case 'time_audit':
      case 'project_review':
      case 'swot_analysis':
      case 'customer_profile':
      case 'trend_insight':
      case 'competitor_radar':
      case 'decision_matrix':
        return ToolCategory.analysis;
      case 'project_board':
      case 'lightweight_crm':
      case 'invoice_recognition':
      case 'contract_summary':
      case 'quotation':
      case 'knowledge_card':
        return ToolCategory.management;
      case 'ai_advisor':
      case 'creative_diverge':
      case 'knowledge_qa':
      case 'writing_workshop':
      case 'daily_three_questions':
      default:
        return ToolCategory.ai;
    }
  }

  void _setDefaultTemplate(String toolId, String templateId) {
    ref
        .read(toolTemplateProvider.notifier)
        .setDefaultTemplate(toolId, templateId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('已设置为默认模板'), backgroundColor: AppColors.success),
    );
  }

  void _addTemplate(String toolId) {
    final config = toolConfigs[toolId];
    if (config == null) return;

    showDialog(
      context: context,
      builder: (context) => AddTemplateDialog(
        toolConfig: config,
        onAdded: (template) {
          ref.read(toolTemplateProvider.notifier).addTemplate(toolId, template);
        },
      ),
    );
  }

  void _editTemplate(String toolId, ToolTemplate template) {
    showDialog(
      context: context,
      builder: (context) => EditTemplateDialog(
        template: template,
        onEdited: (updated) {
          ref
              .read(toolTemplateProvider.notifier)
              .editTemplate(toolId, template.id, updated);
        },
      ),
    );
  }

  void _deleteTemplate(String toolId, String templateId, bool isBuiltIn) async {
    if (isBuiltIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('系统默认模板不能删除'), backgroundColor: AppColors.warning),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除模板'),
        content: const Text('确定要删除这个模板吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref
          .read(toolTemplateProvider.notifier)
          .deleteTemplate(toolId, templateId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('模板已删除'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  Widget _buildCategoryChip(ToolCategory? category, int count) {
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(category == null ? '全部' : _getCategoryName(category)),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCategory = category),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontSize: 13,
      ),
      avatar: count > 0
          ? Text('$count', style: const TextStyle(fontSize: 12))
          : null,
    );
  }

  String _getCategoryName(ToolCategory category) {
    switch (category) {
      case ToolCategory.productivity:
        return '效率工具';
      case ToolCategory.analysis:
        return '分析工具';
      case ToolCategory.management:
        return '管理工具';
      case ToolCategory.ai:
        return 'AI工具';
    }
  }

  List<Widget> _buildToolSections(
    Map<ToolCategory, List<MapEntry<String, ToolConfig>>> toolsByCategory,
    Map<String, List<ToolTemplate>> templates,
  ) {
    final widgets = <Widget>[];

    for (final category in ToolCategory.values) {
      if (_selectedCategory != null && _selectedCategory != category) continue;

      final tools = toolsByCategory[category] ?? [];
      final filteredTools = tools.where((entry) {
        if (_searchQuery == null || _searchQuery!.isEmpty) return true;
        return entry.value.title
            .toLowerCase()
            .contains(_searchQuery!.toLowerCase());
      }).toList();

      if (filteredTools.isEmpty) continue;

      if (_selectedCategory == null) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _getCategoryName(category),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      }

      for (final entry in filteredTools) {
        final toolId = entry.key;
        final config = entry.value;
        final toolTemplates =
            templates[toolId] ?? builtInTemplates[toolId] ?? [];
        widgets.add(_buildToolSection(config.title, toolId, toolTemplates));
        widgets.add(const SizedBox(height: 20));
      }
    }

    return widgets;
  }

  Widget _buildToolSection(
      String toolName, String toolId, List<ToolTemplate> templates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                toolName,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              onPressed: () => _addTemplate(toolId),
              tooltip: '新增模板',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: templates.map((template) {
              return _buildTemplateItem(template, toolId);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateItem(ToolTemplate template, String toolId) {
    return InkWell(
      onTap: () => _editTemplate(toolId, template),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (template.isDefault)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text(
                            '默认',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  onPressed: () => _setDefaultTemplate(toolId, template.id),
                  tooltip: '设为默认',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppColors.textTertiary),
                  onPressed: () =>
                      _deleteTemplate(toolId, template.id, template.isBuiltIn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(toolTemplateProvider);
    final toolsByCategory = _getToolsByCategory();
    const categories = ToolCategory.values;

    return Scaffold(
      appBar: AppBar(
        title: const Text('工具方案配置'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: '搜索工具...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip(null, categories.length),
                  const SizedBox(width: 8),
                  ...categories.map((category) {
                    final count = toolsByCategory[category]?.length ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildCategoryChip(category, count),
                    );
                  }),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '工具方案配置',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  '以下是各工具的模板配置，系统默认模板不能删除，可设置默认模板',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ..._buildToolSections(toolsByCategory, templates),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AddTemplateDialog extends StatefulWidget {
  final ToolConfig toolConfig;
  final void Function(ToolTemplate) onAdded;

  const AddTemplateDialog({
    super.key,
    required this.toolConfig,
    required this.onAdded,
  });

  @override
  State<AddTemplateDialog> createState() => _AddTemplateDialogState();
}

class _AddTemplateDialogState extends State<AddTemplateDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _systemPromptController = TextEditingController();
  bool _isDefault = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty ||
        _systemPromptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('请填写名称和提示词'), backgroundColor: AppColors.warning),
      );
      return;
    }

    final newTemplate = ToolTemplate(
      id: '',
      toolId: widget.toolConfig.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      systemPrompt: _systemPromptController.text.trim(),
      isDefault: _isDefault,
      isBuiltIn: false,
    );

    widget.onAdded(newTemplate);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('为${widget.toolConfig.title}新增模板'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '模板名称',
                  hintText: '输入模板名称',
                ),
              ),
              const SizedBox(height: 12),
              ExpandableTextField(
                controller: _descriptionController,
                labelText: '描述',
                hintText: '简要描述这个模板的用途',
                minLines: 2,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ExpandableTextField(
                controller: _systemPromptController,
                labelText: '系统提示词',
                hintText: '输入AI的系统提示词',
                minLines: 5,
                maxLines: 8,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _isDefault,
                    onChanged: (value) =>
                        setState(() => _isDefault = value ?? false),
                  ),
                  const Text('设为默认模板'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class EditTemplateDialog extends StatefulWidget {
  final ToolTemplate template;
  final void Function(ToolTemplate) onEdited;

  const EditTemplateDialog({
    super.key,
    required this.template,
    required this.onEdited,
  });

  @override
  State<EditTemplateDialog> createState() => _EditTemplateDialogState();
}

class _EditTemplateDialogState extends State<EditTemplateDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _systemPromptController;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template.name);
    _descriptionController =
        TextEditingController(text: widget.template.description);
    _systemPromptController =
        TextEditingController(text: widget.template.systemPrompt);
    _isDefault = widget.template.isDefault;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty ||
        _systemPromptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('请填写名称和提示词'), backgroundColor: AppColors.warning),
      );
      return;
    }

    final updatedTemplate = widget.template.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      systemPrompt: _systemPromptController.text.trim(),
      isDefault: _isDefault,
    );

    widget.onEdited(updatedTemplate);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑模板'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '模板名称',
                ),
              ),
              const SizedBox(height: 12),
              ExpandableTextField(
                controller: _descriptionController,
                labelText: '描述',
                minLines: 2,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ExpandableTextField(
                controller: _systemPromptController,
                labelText: '系统提示词',
                minLines: 5,
                maxLines: 8,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _isDefault,
                    onChanged: (value) =>
                        setState(() => _isDefault = value ?? false),
                  ),
                  const Text('设为默认模板'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
