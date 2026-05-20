import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/ai_role.dart';
import '../../../core/services/prompt_template_service.dart';
import '../../../core/services/role_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/expandable_text_field.dart';

class RoleManagementScreen extends ConsumerStatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  ConsumerState<RoleManagementScreen> createState() =>
      _RoleManagementScreenState();
}

class _RoleManagementScreenState extends ConsumerState<RoleManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AiRole> _builtInRoles = [];
  List<AiRole> _customRoles = [];
  List<PromptTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final templateService = ref.read(promptTemplateServiceProvider);
    await templateService.initialize();

    final customRoles = await RoleService.getCustomRoles();

    setState(() {
      _builtInRoles = AiRole.builtInRoles;
      _customRoles = customRoles;
      _templates = templateService.getAllTemplates();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI分析角色'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: '系统角色 (${_builtInRoles.length})'),
            Tab(text: '自定义 (${_customRoles.length})'),
            Tab(text: '模板库 (${_templates.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSystemRolesTab(),
                _buildCustomRolesTab(),
                _buildTemplatesTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRoleDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSystemRolesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _builtInRoles.length,
      itemBuilder: (context, index) {
        final role = _builtInRoles[index];
        return _buildRoleCard(role, canEdit: false, canDelete: false);
      },
    );
  }

  Widget _buildCustomRolesTab() {
    if (_customRoles.isEmpty) {
      return _buildEmptyState(
        '暂无自定义角色',
        '点击右下角 + 创建你的专属AI角色',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _customRoles.length,
      itemBuilder: (context, index) {
        final role = _customRoles[index];
        return _buildRoleCard(role, canEdit: true, canDelete: true);
      },
    );
  }

  Widget _buildTemplatesTab() {
    final templateService = ref.read(promptTemplateServiceProvider);
    final categories = templateService.getCategories();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryTemplates =
            _templates.where((t) => t.category == category).toList();

        if (categoryTemplates.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 16),
            Text(
              _getCategoryLabel(category),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...categoryTemplates
                .map((template) => _buildTemplateCard(template)),
          ],
        );
      },
    );
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

  Widget _buildRoleCard(AiRole role,
      {required bool canEdit, required bool canDelete}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showRoleDetail(role, canEdit: canEdit),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    role.isBuiltIn ? Icons.verified : Icons.person_outline,
                    color:
                        role.isBuiltIn ? AppColors.success : AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      role.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (canEdit)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _showEditRoleDialog(role),
                    ),
                  if (canDelete)
                    IconButton(
                      icon: const Icon(Icons.delete,
                          size: 18, color: AppColors.error),
                      onPressed: () => _showDeleteConfirm(role),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                role.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(PromptTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showTemplateDetail(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_stories,
                      color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (template.useCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '使用${template.useCount}次',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                template.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
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
        ],
      ),
    );
  }

  void _showRoleDetail(AiRole role, {required bool canEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        role.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (canEdit)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditRoleDialog(role);
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('编辑'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  role.description,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  '提示词（Prompt）',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: SelectableText(
                        role.systemPrompt,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTemplateDetail(PromptTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        template.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _convertTemplateToCustomRole(template);
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('编辑并转为自定义'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  template.description,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  '模板内容',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: SelectableText(
                        template.template,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _convertTemplateToCustomRole(PromptTemplate template) {
    _showRoleEditorDialog(
      existingRole: null,
      initialName: template.name,
      initialDesc: template.description,
      initialPrompt: template.template,
      isFromTemplate: true,
    );
  }

  void _showAddRoleDialog() {
    _showRoleEditorDialog();
  }

  void _showEditRoleDialog(AiRole role) {
    _showRoleEditorDialog(existingRole: role);
  }

  void _showRoleEditorDialog({
    AiRole? existingRole,
    String initialName = '',
    String initialDesc = '',
    String initialPrompt = '',
    bool isFromTemplate = false,
  }) {
    final nameController = TextEditingController(
      text: existingRole?.name ?? initialName,
    );
    final descController = TextEditingController(
      text: existingRole?.description ?? initialDesc,
    );
    final promptController = TextEditingController(
      text: existingRole?.systemPrompt ?? initialPrompt,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          existingRole != null
              ? '编辑角色'
              : isFromTemplate
                  ? '基于模板创建角色'
                  : '新建角色',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '角色名称',
                  hintText: '例如：产品经理',
                ),
              ),
              const SizedBox(height: 12),
              ExpandableTextField(
                controller: descController,
                labelText: '角色描述',
                hintText: '简要说明这个角色的用途',
                minLines: 2,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ExpandableTextField(
                controller: promptController,
                labelText: '系统提示词（Prompt）',
                hintText: '输入系统提示词，定义AI的角色和行为...',
                minLines: 5,
                maxLines: 8,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final desc = descController.text.trim();
              final prompt = promptController.text.trim();

              if (name.isEmpty || prompt.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('名称和提示词不能为空')),
                );
                return;
              }

              if (existingRole != null) {
                await RoleService.updateCustomRole(
                  existingRole.copyWith(
                    name: name,
                    description: desc,
                    systemPrompt: prompt,
                  ),
                );
              } else {
                await RoleService.addCustomRole(
                  AiRole(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    description: desc,
                    systemPrompt: prompt,
                    isBuiltIn: false,
                    createdAt: DateTime.now(),
                  ),
                );
              }

              if (mounted) {
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(AiRole role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除角色「${role.name}」吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await RoleService.deleteCustomRole(role.id);
              if (mounted) {
                Navigator.pop(context);
                _loadData();
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
